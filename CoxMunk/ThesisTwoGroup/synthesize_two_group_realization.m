function realization = synthesize_two_group_realization(U10,seed,cfg)
%SYNTHESIZE_TWO_GROUP_REALIZATION Paired linear and modified-Lie sea states.

g = 9.81;                                    % m/s^2
kp = g*(cfg.inverseWaveAge/U10)^2;           % rad/m
dk = kp/cfg.primaryPeakSamples;              % rad/m
N = cfg.primaryGridSize;
kAxis = [0:N/2-1,-N/2:-1]*dk;
[KX,KY] = meshgrid(kAxis,kAxis);
K = hypot(KX,KY);
windAngle = deg2rad(cfg.windDirectionDeg);
KAlong = KX*cos(windAngle)+KY*sin(windAngle);
KCross = -KX*sin(windAngle)+KY*cos(windAngle);

[PsiTarget,meta] = thesis_elfouhaily_spectrum(K,KX,KY,U10, ...
    cfg.inverseWaveAge,cfg.windDirectionDeg,cfg);
primaryMask = K <= cfg.primaryMaximumPeakMultiple*kp;
PsiTarget = PsiTarget.*primaryMask;
if cfg.enableSpectralUndressing
    [PsiInput,undressingHistory] = undress_spectrum_for_lie( ...
        PsiTarget,KX,KY,K,dk,U10,kp,cfg);
else
    PsiInput = PsiTarget;
    undressingHistory = table();
end

% Reset after any diagnostic undressing so paired physical realizations use
% the requested seed and identical Fourier phases.
rng(seed,'twister');
[Hlinear,white] = sample_hermitian_spectrum(PsiTarget,dk,dk);
HmodifiedInput = sample_hermitian_spectrum(PsiInput,dk,dk,white);
[Hmodified,lieDiagnostics] = apply_modified_lie_transform( ...
    HmodifiedInput,KX,KY,K,U10,kp,cfg);
linearPrimary = spectral_surface_metrics(Hlinear,KAlong,KCross);
modifiedPrimary = spectral_surface_metrics(Hmodified,KAlong,KCross);

sampleCount = cfg.slopePdfSamplesPerRealization;
primaryIndices = round(linspace(1,numel(linearPrimary.sx),sampleCount));
shortAlongSamples = zeros(sampleCount,1);
shortCrossSamples = zeros(sampleCount,1);
shortMss = zero_mss();
maximumShortMssError = 0;
maximumShortHermitianResidual = 0;

bandLow = cfg.primaryMaximumPeakMultiple*kp;
while bandLow < cfg.maximumOpticalWavenumber
    bandHigh = min(2*bandLow,cfg.maximumOpticalWavenumber);
    tileDk = bandLow/cfg.shortWaveModesBelowBand;
    tileN = cfg.shortWaveTileSize;
    tileAxis = [0:tileN/2-1,-tileN/2:-1]*tileDk;
    [tileKX,tileKY] = meshgrid(tileAxis,tileAxis);
    tileK = hypot(tileKX,tileKY);
    tileAlong = tileKX*cos(windAngle)+tileKY*sin(windAngle);
    tileCross = -tileKX*sin(windAngle)+tileKY*cos(windAngle);
    tilePsi = thesis_elfouhaily_spectrum(tileK,tileKX,tileKY,U10, ...
        cfg.inverseWaveAge,cfg.windDirectionDeg,cfg);
    bandMask = tileK >= bandLow & tileK < bandHigh;
    Hband = sample_hermitian_spectrum(tilePsi.*bandMask,tileDk,tileDk);
    bandMetrics = spectral_surface_metrics(Hband,tileAlong,tileCross);
    shortMss.along = shortMss.along+bandMetrics.along;
    shortMss.cross = shortMss.cross+bandMetrics.cross;
    shortMss.total = shortMss.along+shortMss.cross;
    tileIndices = round(linspace(1,numel(bandMetrics.sx),sampleCount));
    tileAlongSamples = bandMetrics.sx(tileIndices);
    tileCrossSamples = bandMetrics.sy(tileIndices);
    shortAlongSamples = shortAlongSamples+tileAlongSamples(:);
    shortCrossSamples = shortCrossSamples+tileCrossSamples(:);
    maximumShortMssError = max(maximumShortMssError,bandMetrics.mssRelativeError);
    maximumShortHermitianResidual = max(maximumShortHermitianResidual, ...
        bandMetrics.hermitianResidual);
    bandLow = bandHigh;
end

primaryLinearAlong = linearPrimary.sx(primaryIndices);
primaryLinearCross = linearPrimary.sy(primaryIndices);
primaryModifiedAlong = modifiedPrimary.sx(primaryIndices);
primaryModifiedCross = modifiedPrimary.sy(primaryIndices);
linearAlongSamples = primaryLinearAlong(:)+shortAlongSamples;
linearCrossSamples = primaryLinearCross(:)+shortCrossSamples;
modifiedAlongSamples = primaryModifiedAlong(:)+shortAlongSamples;
modifiedCrossSamples = primaryModifiedCross(:)+shortCrossSamples;

realization.linear = add_mss(linearPrimary,shortMss);
realization.modifiedLie = add_mss(modifiedPrimary,shortMss);
realization.primaryLinear = strip_fields(linearPrimary);
realization.primaryModifiedLie = strip_fields(modifiedPrimary);
realization.shortWave = shortMss;
realization.deltaPrimaryMss = modifiedPrimary.total-linearPrimary.total;
realization.deltaTotalMss = realization.modifiedLie.total-realization.linear.total;
realization.relativeDeltaPrimaryMss = realization.deltaPrimaryMss/ ...
    max(linearPrimary.total,realmin);
realization.relativeDeltaTotalMss = realization.deltaTotalMss/ ...
    max(realization.linear.total,realmin);

realization.statistics.linear = calculate_statistics( ...
    linearPrimary.eta,linearAlongSamples,linearCrossSamples);
realization.statistics.modifiedLie = calculate_statistics( ...
    modifiedPrimary.eta,modifiedAlongSamples,modifiedCrossSamples);
realization.slopeSamples.linearAlong = linearAlongSamples;
realization.slopeSamples.linearCross = linearCrossSamples;
realization.slopeSamples.modifiedAlong = modifiedAlongSamples;
realization.slopeSamples.modifiedCross = modifiedCrossSamples;

realization.diagnostics.linearMssRelativeError = linearPrimary.mssRelativeError;
realization.diagnostics.modifiedMssRelativeError = modifiedPrimary.mssRelativeError;
realization.diagnostics.maximumShortMssRelativeError = maximumShortMssError;
realization.diagnostics.linearHermitianResidual = linearPrimary.hermitianResidual;
realization.diagnostics.modifiedHermitianResidual = modifiedPrimary.hermitianResidual;
realization.diagnostics.maximumShortHermitianResidual = maximumShortHermitianResidual;
realization.diagnostics.lie = lieDiagnostics;
realization.diagnostics.shortWaveCoefficientClamped = ...
    meta.shortWaveCoefficientClamped;
realization.diagnostics.rawShortWaveCoefficient = meta.rawShortWaveCoefficient;
realization.diagnostics.dragCoefficient = meta.dragCoefficient;
realization.diagnostics.undressingHistory = undressingHistory;

realization.Hlinear = Hlinear;
realization.Hmodified = Hmodified;
realization.K = K;
realization.KX = KX;
realization.KY = KY;
realization.dk = dk;
realization.peakWavenumber = kp;
realization.primaryDomainLength = 2*pi/dk;
realization.primarySpacing = realization.primaryDomainLength/N;
realization.linearSurface = linearPrimary.eta;
realization.modifiedLieSurface = modifiedPrimary.eta;
end

function stats = calculate_statistics(elevation,alongSlope,crossSlope)
elevationMoments = field_standardized_moments(elevation);
alongMoments = field_standardized_moments(alongSlope);
crossMoments = field_standardized_moments(crossSlope);
stats.ElevationSkewness = elevationMoments.skewness;
stats.ElevationExcessKurtosis = elevationMoments.excessKurtosis;
stats.AlongSlopeSkewness = alongMoments.skewness;
stats.AlongSlopeExcessKurtosis = alongMoments.excessKurtosis;
stats.CrossSlopeSkewness = crossMoments.skewness;
stats.CrossSlopeExcessKurtosis = crossMoments.excessKurtosis;
end

function result = add_mss(primary,shortWave)
result.along = primary.along+shortWave.along;
result.cross = primary.cross+shortWave.cross;
result.total = result.along+result.cross;
result.gamma = sqrt(result.cross/max(result.along,realmin));
end

function result = strip_fields(metrics)
result.along = metrics.along;
result.cross = metrics.cross;
result.total = metrics.total;
result.gamma = metrics.gamma;
result.spatialTotal = metrics.spatialTotal;
result.mssRelativeError = metrics.mssRelativeError;
result.hermitianResidual = metrics.hermitianResidual;
end

function result = zero_mss()
result.along = 0;
result.cross = 0;
result.total = 0;
end
