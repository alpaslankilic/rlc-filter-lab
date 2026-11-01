function [p, timing] = plan_experiment(p, resistance)
%PLAN_EXPERIMENT Apply the second source step after every case has settled.
probe = (0:p.sampleTime:0.05).';
initialSettling = zeros(1,numel(resistance));
for k = 1:numel(resistance)
    trial = p;
    trial.R = resistance(k);
    trial.secondStepVoltage = 0;
    response = circuit_response(probe,trial);
    initialSettling(k) = settled_at(probe,response,p.sourceTime, ...
        p.sourceVoltage,p.sourceVoltage);
end
% One saved sample separates the final settled sample from the next event.
p.secondStepTime = max(initialSettling)+p.sampleTime;
finalSettling = zeros(size(initialSettling));
for k = 1:numel(resistance)
    trial = p;
    trial.R = resistance(k);
    response = circuit_response(probe,trial);
    finalSettling(k) = settled_at(probe,response,p.secondStepTime, ...
        p.sourceVoltage+p.secondStepVoltage,p.secondStepVoltage);
end
lastSettled = max(finalSettling);
postEventDuration = lastSettled-p.secondStepTime;
p.stopTime = ceil((lastSettled+0.1*postEventDuration)/p.sampleTime)*p.sampleTime;
timing.initial_settled_at_s = initialSettling;
timing.second_source_step_at_s = p.secondStepTime;
timing.final_settled_at_s = finalSettling;
timing.post_event_settling_s = finalSettling-p.secondStepTime;
timing.stop_time_s = p.stopTime;
timing.tail_fraction = 0.1;
timing.criteria = '2% input-step amplitude for capacitor voltage; 2% transient peak for current and R/L voltages';
end

function time = settled_at(t,response,startTime,voltageTarget,stepAmplitude)
selected = find(t>=startTime);
signals = response(selected,1:4);
deviation = signals-[0,voltageTarget,0,0];
tolerance = 0.02*max(abs(deviation),[],1);
tolerance(2) = 0.02*abs(stepAmplitude);
tolerance = max(tolerance,1e-12);
outside = any(abs(deviation)>tolerance,2);
last = find(outside,1,'last');
assert(~isempty(last) && last<numel(selected),'Sizing horizon did not capture settling.');
time = t(selected(last+1));
end
