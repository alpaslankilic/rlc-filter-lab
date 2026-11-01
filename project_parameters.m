function p = project_parameters()
%PROJECT_PARAMETERS Series circuit values in SI units.
p.R = 12;
p.L = 8e-3;
p.C = 12e-6;
p.sourceVoltage = 5;
p.sourceTime = 1e-3;
p.disturbanceVoltage = 0.75;
p.disturbanceTime = 9e-3;
p.sampleTime = 2e-6;
p.stopTime = 0.015232;
end
