function signal = circuit_response(t, p)
%CIRCUIT_RESPONSE Closed-form response, including both source-voltage steps.
signal = zeros(numel(t), 5);
events = [p.sourceTime, p.sourceVoltage; ...
    p.disturbanceTime, p.disturbanceVoltage];
wn = 1/sqrt(p.L*p.C);
alpha = p.R/(2*p.L);
for k = 1:size(events, 1)
    selected = t >= events(k, 1);
    tau = t(selected) - events(k, 1);
    if abs(alpha/wn - 1) < 1e-8
        capacitor = 1 - (1 + wn*tau).*exp(-wn*tau);
        current = tau.*exp(-wn*tau)/p.L;
    elseif alpha < wn
        wd = sqrt(wn^2 - alpha^2);
        capacitor = 1 - exp(-alpha*tau).*(cos(wd*tau) + alpha/wd*sin(wd*tau));
        current = exp(-alpha*tau).*sin(wd*tau)/(p.L*wd);
    else
        r1 = -alpha + sqrt(alpha^2 - wn^2);
        r2 = -alpha - sqrt(alpha^2 - wn^2);
        capacitor = 1 + (r2*exp(r1*tau) - r1*exp(r2*tau))/(r1-r2);
        current = p.C*r1*r2*(exp(r1*tau)-exp(r2*tau))/(r1-r2);
    end
    voltage = events(k, 2);
    resistor = p.R*current;
    inductor = 1 - resistor - capacitor;
    signal(selected, :) = signal(selected, :) + ...
        voltage*[current, capacitor, resistor, inductor, ones(size(tau))];
end
end
