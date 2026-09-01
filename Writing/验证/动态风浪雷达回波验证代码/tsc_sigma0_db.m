function sigma0Db = tsc_sigma0_db( ...
    frequencyGHz, seaState, grazingDeg, relativeWindDeg, windSpeed)
%TSC_SIGMA0_DB HH-polarized two-scale composite sea backscatter model.
% Output is normalized backscatter in dB. The model combines diffuse and
% quasi-specular components and represents unresolved X-band roughness.

if seaState < 1
    sigma0Db = -200 * ones(size(grazingDeg));
    return;
end
if nargin < 5 || isempty(windSpeed)
    windSpeed = 3.189 * seaState^0.8;
end

lambda = 0.3 / frequencyGHz;
phi = deg2rad(max(min(grazingDeg, 89.9), 0.001));
theta = deg2rad(relativeWindDeg);

sigmaH = 0.03505 * seaState^1.95;
sigmaTsc = 4.5416 .* phi .* (3.2808 * sigmaH + 0.25) / lambda;
aTsc = sigmaTsc.^1.5 ./ (1 + sigmaTsc.^1.5);

q = phi.^0.6;
a1 = (1 + (lambda / 0.009144)^3)^0.1;
a2 = (1 + (lambda / 0.03048)^3)^0.1;
a3 = (1 + (lambda / 0.09144)^3).^(q / 3);
a4 = 1 + 0.35 * q;
exponentA = 2.63 * a1 ./ (a2 .* a3 .* a4);
bTsc = ((1.9438 * windSpeed + 4) / 15).^exponentA;

cTsc = exp(0.3 .* cos(theta) .* exp(-phi / 0.17) ...
    ./ (10.7636 * lambda^2 + 0.005).^0.2);
dTsc = 1 - 0.6 * sin(theta).^2;

diffuseComponent = 1.7e-5 .* sqrt(phi) .* aTsc .* bTsc ...
    .* cTsc .* dTsc ./ (3.2808 * lambda + 0.05).^1.8;

if lambda < 0.05
    muDb = -5;
else
    muDb = -5 + 12.5 * (log10(lambda) - log10(0.05));
end
muLinear = 10^(muDb / 10);

if seaState <= 2
    betaDeg = 10.1 + 1.65 * seaState;
else
    betaDeg = 13.4 + 0.7 * (seaState - 2);
end
beta = deg2rad(betaDeg);
quasiComponent = muLinear * cot(beta)^2 .* ...
    exp(-tan(pi/2 - phi).^2 / tan(beta)^2);

sigma0Linear = max(diffuseComponent + quasiComponent, realmin('double'));
sigma0Db = 10 * log10(sigma0Linear);
end
