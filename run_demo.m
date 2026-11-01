function report = run_demo(showFigures)
%RUN_DEMO Compare three damping cases and verify Kirchhoff's voltage law.
if nargin == 0
    showFigures = true;
end
root = fileparts(mfilename('fullpath'));
previous = pwd;
cleanup = onCleanup(@() cd(previous));
cd(root);
p = project_parameters();
resistance = [p.R, 2*sqrt(p.L/p.C), 3.2*sqrt(p.L/p.C)];
names = {'Underdamped', 'Critically damped', 'Overdamped'};
probeTime = (0:p.sampleTime:0.04).';
settling = zeros(1, 3);
for k = 1:3
    trial = p;
    trial.R = resistance(k);
    response = circuit_response(probeTime, trial);
    after = find(probeTime >= p.disturbanceTime);
    tolerance = 0.02*abs(p.disturbanceVoltage);
    last = find(abs(response(after, 2) - ...
        p.sourceVoltage - p.disturbanceVoltage) > tolerance, 1, 'last');
    assert(~isempty(last) && last < numel(after), 'Sizing response did not settle.');
    settling(k) = probeTime(after(last + 1)) - p.disturbanceTime;
end
p.stopTime = ceil((p.disturbanceTime + 1.2*max(settling))/p.sampleTime)*p.sampleTime;
t = (0:p.sampleTime:p.stopTime).';
response = cell(1, 3);
maxError = zeros(1, 3);
for k = 1:3
    trial = p;
    trial.R = resistance(k);
    in = Simulink.SimulationInput('rlc_series');
    in = in.setVariable('p', trial, 'Workspace', 'rlc_series');
    in = in.setModelParameter('StopTime', num2str(p.stopTime, 12), ...
        'Solver', 'ode45', 'MaxStep', num2str(p.sampleTime), ...
        'RelTol', '1e-8', 'AbsTol', '1e-10');
    out = sim(in);
    response{k} = interp1(out.response.Time, out.response.Data, t, 'linear');
    exact = circuit_response(t, trial);
    % Input jumps are checked separately; compare the continuous capacitor state.
    maxError(k) = max(abs(response{k}(:, 2) - exact(:, 2)));
    assert(maxError(k) < 2e-4, 'Capacitor response disagrees with the closed form.');
    residual = response{k}(:, 2) + response{k}(:, 3) + ...
        response{k}(:, 4) - response{k}(:, 5);
    assert(max(abs(residual)) < 1e-8, 'Kirchhoff voltage balance failed.');
    assert(abs(response{k}(end, 2) - p.sourceVoltage - ...
        p.disturbanceVoltage) < 0.02*p.disturbanceVoltage, 'Response not settled.');
end
frequency = logspace(1, 5, 700).';
s = 1i*2*pi*frequency;
denominator = p.L*p.C*s.^2 + p.R*p.C*s + 1;
gain = [1./denominator, p.R*p.C*s./denominator, p.L*p.C*s.^2./denominator];
assert(max(abs(sum(gain, 2) - 1)) < 1e-12, 'Frequency-domain voltage balance failed.');
report.natural_frequency_Hz = 1/(2*pi*sqrt(p.L*p.C));
report.damping_ratios = resistance/2*sqrt(p.C/p.L);
report.resistance_ohm = resistance;
report.post_disturbance_settling_s = settling;
report.closed_form_max_error_V = maxError;
report.stop_time_s = p.stopTime;
report.verification = 'PASS';
if ~isfolder('results')
    mkdir('results');
end
for k = 1:3
    data = array2table([t, response{k}], 'VariableNames', ...
        {'time_s','current_A','capacitor_V','resistor_V','inductor_V','source_V'});
    writetable(data, fullfile('results', sprintf('case_%d.csv', k)));
end
writetable(array2table([frequency, 20*log10(abs(gain))], 'VariableNames', ...
    {'frequency_Hz','lowpass_dB','bandpass_dB','highpass_dB'}), 'results/frequency.csv');
write_json('results/metrics.json', report);
write_json('results/parameters.json', p);
plot_results(t, response, frequency, gain, names, p, showFigures);
disp(report);
end

function write_json(path, value)
file = fopen(path, 'w');
assert(file ~= -1, 'Cannot write output.');
cleanup = onCleanup(@() fclose(file));
fprintf(file, '%s\n', jsonencode(value, 'PrettyPrint', true));
end
