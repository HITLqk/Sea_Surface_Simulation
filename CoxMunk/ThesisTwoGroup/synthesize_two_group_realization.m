function realization = synthesize_two_group_realization(U10,seed,cfg)
%SYNTHESIZE_TWO_GROUP_REALIZATION Paired linear and modified-Lie surfaces.

rng(seed,'twister');
g = 9.81;
kp = g*(cfg.inverseWaveAge/U10)^2;
dk = kp/cfg.primaryPeakSamples;
N = cfg.primaryGridSize;
kAxis = [0:N/2-1,-N/2:-1]*dk;
[KX,KY] = meshgrid(kAxis,kAxis);
K = hypot(KX,KY);

[Psi,meta] = thesis_elfouhaily_spectrum(K,KX,KY,U10, ...
    cfg.inverseWaveAge,cfg.windDirectionDeg);
primaryMask = K <= cfg.primaryMaximumPeakMultiple*kp;
Hlinear = sample_hermitian_coefficients(Psi.*primaryMask,dk,dk);

Hbreaking = apply_thesis_modified_lie(Hlinear,KX,KY,K,U10,kp,cfg);
linearMss = spectral_mss(Hlinear,KX,KY);
breakingMss = spectral_mss(Hbreaking,KX,KY);

bandLow = cfg.primaryMaximumPeakMultiple*kp;
shortMss = struct('along',0,'cross',0,'total',0);
while bandLow < cfg.maximumOpticalWavenumber
    bandHigh = min(2*bandLow,cfg.maximumOpticalWavenumber);
    tileDk = bandLow/cfg.shortWaveModesBelowBand;
    tileN = cfg.shortWaveTileSize;
    tileAxis = [0:tileN/2-1,-tileN/2:-1]*tileDk;
    [tileKX,tileKY] = meshgrid(tileAxis,tileAxis);
    tileK = hypot(tileKX,tileKY);
    tilePsi = thesis_elfouhaily_spectrum(tileK,tileKX,tileKY,U10, ...
        cfg.inverseWaveAge,cfg.windDirectionDeg);
    bandMask = tileK >= bandLow & tileK < bandHigh;
    Hband = sample_hermitian_coefficients(tilePsi.*bandMask,tileDk,tileDk);
    bandMss = spectral_mss(Hband,tileKX,tileKY);
    shortMss.along = shortMss.along+bandMss.along;
    shortMss.cross = shortMss.cross+bandMss.cross;
    shortMss.total = shortMss.total+bandMss.total;
    bandLow = bandHigh;
end

realization.linear = add_mss(linearMss,shortMss);
realization.breaking = add_mss(breakingMss,shortMss);
realization.primaryLinear = linearMss;
realization.primaryBreaking = breakingMss;
realization.shortWave = shortMss;
realization.peakWavenumber = meta.peakWavenumber;
realization.primaryDomainLength = 2*pi/dk;
realization.primarySpacing = realization.primaryDomainLength/N;
realization.rawShortWaveCoefficient = meta.rawShortWaveCoefficient;
realization.linearSurface = real(ifft2(Hlinear))*N^2;
realization.breakingSurface = real(ifft2(Hbreaking))*N^2;
end

function H = sample_hermitian_coefficients(Psi,dkx,dky)
[Ny,Nx] = size(Psi);
white = (randn(Ny,Nx)+1i*randn(Ny,Nx))/sqrt(2);
negativeX = [1,Nx:-1:2];
negativeY = [1,Ny:-1:2];
white = (white+conj(white(negativeY,negativeX)))/sqrt(2);
H = sqrt(Psi*dkx*dky).*white;
end

function Hnonlinear = apply_thesis_modified_lie(H,KX,KY,K,U10,kp,cfg)
Ksafe = max(K,realmin);
inputMask = K <= cfg.lieInputPeakMultiple*kp;
outputMask = K <= cfg.lieOutputPeakMultiple*kp;
N = size(H,1);

% h_tx and h_ty in the Lie/Creamer formulation are the two Riesz
% (multidimensional Hilbert) components of elevation, not spatial slopes.
% Treating them as derivatives introduces an erroneous k^2 amplification.
Htx = -1i*(KX./Ksafe).*H.*inputMask;
Hty = -1i*(KY./Ksafe).*H.*inputMask;
htx = real(ifft2(Htx))*N^2;
hty = real(ifft2(Hty))*N^2;
Fxx = fft2(htx.^2)/N^2;
Fxy = fft2(htx.*hty)/N^2;
Fyy = fft2(hty.^2)/N^2;

% Thesis equation (2.31). Absolute directional projections are the
% real-surface form of the wind factors; signed odd multipliers would
% destroy Hermitian symmetry and yield an imaginary elevation field.
windX = U10*abs(KX)./Ksafe;
windY = U10*abs(KY)./Ksafe;
Lstar = -(KX.^2./(2*Ksafe)).*windX.*Fxx ...
    -(KX.*KY./Ksafe).*Fxy ...
    -(KY.^2./(2*Ksafe)).*windY.*Fyy;
Lstar = cfg.modifiedLieScale*Lstar.*outputMask;
Lstar(K == 0) = 0;
Hnonlinear = H+Lstar;

negative = [1,N:-1:2];
Hnonlinear = (Hnonlinear+conj(Hnonlinear(negative,negative)))/2;
end

function stats = spectral_mss(H,KX,KY)
stats.along = sum(KX.^2.*abs(H).^2,'all');
stats.cross = sum(KY.^2.*abs(H).^2,'all');
stats.total = stats.along+stats.cross;
stats.gamma = sqrt(stats.cross/max(stats.along,realmin));
end

function result = add_mss(primary,shortWave)
result.along = primary.along+shortWave.along;
result.cross = primary.cross+shortWave.cross;
result.total = result.along+result.cross;
result.gamma = sqrt(result.cross/max(result.along,realmin));
end
