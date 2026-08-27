function [Hmodified,diagnostics] = apply_modified_lie_transform( ...
    H,KX,KY,K,U10,kp,cfg)
%APPLY_MODIFIED_LIE_TRANSFORM Second-order Riesz/Lie elevation correction.
%   H and the returned correction have units of metres. The Riesz fields
%   h_ta and h_tc also have units of metres; F[h_t^2] has m^2 and the
%   leading wavenumber has 1/m. Therefore only dimensionless directional
%   multipliers are admissible in the corrected model.

Ksafe = max(K,realmin);
inputMask = K <= cfg.lieInputPeakMultiple*kp;
outputMask = K <= cfg.lieOutputPeakMultiple*kp;
[Ny,Nx] = size(H);

windAngle = deg2rad(cfg.windDirectionDeg);
KAlong = KX*cos(windAngle)+KY*sin(windAngle);
KCross = -KX*sin(windAngle)+KY*cos(windAngle);

% Riesz transforms are dimensionless Fourier multipliers. They do not
% contain an extra factor of k and therefore cannot amplify high k by k^2.
Hta = -1i*(KAlong./Ksafe).*H.*inputMask;
Htc = -1i*(KCross./Ksafe).*H.*inputMask;
hta = real(ifft2(Hta))*Nx*Ny;
htc = real(ifft2(Htc))*Nx*Ny;
Faa = fft2(hta.^2)/(Nx*Ny);
Fac = fft2(hta.*htc)/(Nx*Ny);
Fcc = fft2(htc.^2)/(Nx*Ny);

termAlong = -(KAlong.^2./(2*Ksafe)).*Faa;
termMixed = -(KAlong.*KCross./Ksafe).*Fac;
termCross = -(KCross.^2./(2*Ksafe)).*Fcc;

switch string(cfg.windFactorMode)
    case "none"
        % Dimensionally consistent standard second-order Lie/Creamer form.
        Lcandidate = termAlong+termMixed+termCross;
        dimensionalStatus = "consistent";
    case "direction_only"
        % i*k_direction/k is dimensionless and satisfies
        % M(-k)=conj(M(k)); it retains signed phase information.
        alongProjection = 1i*KAlong./Ksafe;
        crossProjection = 1i*KCross./Ksafe;
        Lcandidate = alongProjection.*termAlong+termMixed+ ...
            crossProjection.*termCross;
        dimensionalStatus = "consistent";
    case "current"
        % Legacy failure-control mode: U10 makes this m^2/s, not metres.
        alongProjection = U10*abs(KAlong)./Ksafe;
        crossProjection = U10*abs(KCross)./Ksafe;
        Lcandidate = alongProjection.*termAlong+termMixed+ ...
            crossProjection.*termCross;
        dimensionalStatus = "inconsistent_legacy";
    otherwise
        error('Unknown windFactorMode: %s',cfg.windFactorMode);
end

Lcandidate = cfg.modifiedLieScale*Lcandidate.*outputMask;
Lcandidate(K == 0) = 0;
diagnostics.preProjectionHermitianResidual = hermitian_residual(Lcandidate);
Lstar = hermitian_from_half_plane(Lcandidate);
Hmodified = H+Lstar;

inputElevation = real(ifft2(H.*inputMask))*Nx*Ny;
inputVariance = mean(inputElevation.^2,'all');
diagnostics.rieszEnergyRatio = ...
    (mean(hta.^2,'all')+mean(htc.^2,'all'))/max(inputVariance,realmin);
diagnostics.rieszAlongRms = sqrt(mean(hta.^2,'all'));
diagnostics.rieszCrossRms = sqrt(mean(htc.^2,'all'));
diagnostics.inputElevationRms = sqrt(inputVariance);
diagnostics.hermitianResidual = hermitian_residual(Hmodified);
diagnostics.correctionHermitianResidual = hermitian_residual(Lstar);
diagnostics.dimensionalStatus = dimensionalStatus;
diagnostics.windFactorMode = string(cfg.windFactorMode);
diagnostics.correctionMss = sum((KX.^2+KY.^2).*abs(Lstar).^2,'all');
diagnostics.Lstar = Lstar;
end
