function [Psi,meta] = thesis_elfouhaily_spectrum( ...
    K,KX,KY,U10,age,windDirectionDeg,cfg)
%THESIS_ELFOUHAILY_SPECTRUM Directional elevation PSD Psi(kx,ky), m^4.
%   S(k)=k^-3[B_l+B_h] [m^3] and Psi=S(k)D(k,phi)/k.

arguments
    K double
    KX double
    KY double
    U10 (1,1) double {mustBePositive}
    age (1,1) double {mustBePositive}
    windDirectionDeg (1,1) double
    cfg (1,1) struct = default_thesis_two_group_config()
end

g = 9.81;                                    % m/s^2
km = 370;                                    % rad/m
cm = 0.23;                                   % m/s
switch string(cfg.dragCoefficientMode)
    case "wu"
        Cd10N = (0.8+0.065*U10)*1e-3;
    case "fixed_legacy"
        Cd10N = cfg.legacyDragCoefficient;
    otherwise
        error('Unknown dragCoefficientMode: %s',cfg.dragCoefficientMode);
end
uStar = sqrt(Cd10N)*U10;                     % m/s
kp = g*(age/U10)^2;                          % rad/m
cp = sqrt(g/kp);                             % m/s
sigma = 0.08*(1+4*age^(-3));

% Elfouhaily et al. (1997), long-wave equilibrium-range level.
alphaP = 0.006*sqrt(age);
if uStar <= cm
    rawAlphaM = 0.01*(1+log(uStar/cm));
else
    rawAlphaM = 0.01*(1+3*log(uStar/cm));
end
alphaM = max(rawAlphaM,0);                   % a PSD cannot be negative
if age <= 1
    gammaPeak = 1.7;
else
    gammaPeak = 1.7+6*log(age);
end

Ksafe = max(K,realmin);
c = sqrt((g./Ksafe).*(1+(Ksafe/km).^2));
Lpm = exp(-1.25*(kp./Ksafe).^2);
Gamma = exp(-0.5*((sqrt(Ksafe/kp)-1)/sigma).^2);
Jp = gammaPeak.^Gamma;
Fp = Lpm.*Jp.*exp(-age/sqrt(10).*(sqrt(Ksafe/kp)-1));
Fm = Lpm.*Jp.*exp(-0.25*(Ksafe/km-1).^2);
Bl = 0.5*alphaP*(cp./c).*Fp;
Bh = 0.5*alphaM*(cm./c).*Fm;
S = (Bl+Bh)./Ksafe.^3;

delta = tanh(log(2)/4 + 4*(c/cp).^2.5 + ...
    0.13*(uStar/cm)*(cm./c).^2.5);
phi = atan2(KY,KX);
phiWind = deg2rad(windDirectionDeg);
spread = (1+delta.*cos(2*(phi-phiWind)))/(2*pi);
Psi = max(S.*spread./Ksafe,0);
Psi(K == 0) = 0;

meta.peakWavenumber = kp;
meta.frictionVelocity = uStar;
meta.dragCoefficient = Cd10N;
meta.dragCoefficientMode = string(cfg.dragCoefficientMode);
meta.alphaLong = alphaP;
meta.rawShortWaveCoefficient = rawAlphaM;
meta.shortWaveCoefficient = alphaM;
meta.shortWaveCoefficientClamped = rawAlphaM < 0;
end
