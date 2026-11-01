function plot_results(t, response, frequency, gain, names, p, visible)
%PLOT_RESULTS Keep damping, circuit dynamics and filter selectivity separate.
colors = [0 .36 .60; .80 .32 .05; .2 .55 .35];
[fig, layout] = new_figure('Damping comparison', 1, visible);
ax = nexttile(layout);
hold(ax, 'on');
for k = 1:3
    plot(ax, 1e3*t, response{k}(:, 2), 'Color', colors(k, :), ...
        'LineWidth', 1.8, 'DisplayName', names{k});
end
plot(ax, 1e3*t, response{1}(:, 5), ':', 'Color', [.4 .4 .4], ...
    'LineWidth', 1.3, 'DisplayName', 'Source voltage');
events(ax, p);
ylabel(ax, 'Capacitor voltage [V]');
xlabel(ax, 'Time [ms]');
legend(ax, 'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off');
xlim(ax, [0, 1e3*p.stopTime]);
style(ax);
save_figure(fig, '01_damping_comparison', visible);

[fig, layout] = new_figure('Circuit dynamics', 2, visible);
ax = nexttile(layout);
plot(ax, 1e3*t, 1e3*response{1}(:, 1), 'Color', colors(1, :), 'LineWidth', 1.8);
events(ax, p);
ylabel(ax, 'Series current [mA]');
title(ax, '(a) Inductor current remains continuous', 'FontWeight', 'normal');
xlim(ax, [0, 1e3*p.stopTime]);
style(ax);
ax = nexttile(layout);
plot(ax, 1e3*t, response{1}(:, 3:4), 'LineWidth', 1.6);
events(ax, p);
ylabel(ax, 'Component voltage [V]');
xlabel(ax, 'Time [ms]');
title(ax, '(b) Resistor and inductor transients', 'FontWeight', 'normal');
legend(ax, 'Resistor', 'Inductor', 'Location', 'southoutside', ...
    'Orientation', 'horizontal', 'Box', 'off');
xlim(ax, [0, 1e3*p.stopTime]);
style(ax);
save_figure(fig, '02_circuit_dynamics', visible);

[fig, layout] = new_figure('Three filter outputs', 1, visible);
ax = nexttile(layout);
hold(ax, 'on');
for k = 1:3
    semilogx(ax, frequency, 20*log10(abs(gain(:, k))), ...
        'Color', colors(k, :), 'LineWidth', 1.8);
end
set(ax, 'XScale', 'log');
xline(ax, 1/(2*pi*sqrt(p.L*p.C)), ':', 'Natural frequency', ...
    'LabelOrientation', 'horizontal', 'HandleVisibility', 'off', 'Color', [.4 .4 .4]);
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'Voltage gain [dB]');
legend(ax, 'Capacitor: low-pass', 'Resistor: band-pass', 'Inductor: high-pass', ...
    'Location', 'northoutside', 'Orientation', 'horizontal', 'Box', 'off');
ylim(ax, [-65, 15]);
xlim(ax, [frequency(1), frequency(end)]);
style(ax);
save_figure(fig, '03_filter_response', visible);
end

function events(ax, p)
limits = ylim(ax);
ylim(ax,[limits(1),limits(2)+0.15*diff(limits)]);
xline(ax, 1e3*p.sourceTime, ':', 'Source step', 'Color', [.4 .4 .4], ...
    'LabelOrientation', 'horizontal', 'FontSize', 10, 'HandleVisibility', 'off');
xline(ax, 1e3*p.secondStepTime, '--', sprintf('Second source step (+%.2f V)',p.secondStepVoltage), ...
    'Color', [.45 .2 .55], 'LabelOrientation', 'horizontal', ...
    'FontSize', 10, 'HandleVisibility', 'off');
end

function [fig, layout] = new_figure(name, panels, visible)
state = 'off';
if visible, state = 'on'; end
fig = figure('Name', name, 'Visible', state, 'Color', 'w', ...
    'Position', [100, 80, 980, 450 + 140*(panels-1)]);
layout = tiledlayout(fig, panels, 1, 'TileSpacing', 'compact', 'Padding', 'loose');
end

function style(ax)
set(ax, 'FontName', 'Arial', 'FontSize', 12, 'Box', 'off', ...
    'TickDir', 'out', 'YGrid', 'on', 'GridAlpha', .12, 'LineWidth', .8);
end

function save_figure(fig, name, visible)
exportgraphics(fig, fullfile('results', [name '.png']), 'Resolution', 200, ...
    'Padding', 8, 'Units', 'points');
exportgraphics(fig, fullfile('results', [name '.pdf']), 'ContentType', 'vector', ...
    'Padding', 8, 'Units', 'points');
if ~visible, close(fig); end
end
