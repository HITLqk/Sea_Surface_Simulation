function summary = simulate_wind_wave_paired_echo(cfg)
%SIMULATE_WIND_WAVE_PAIRED_ECHO Generate wind-wave seas and complex echoes.
% Linear and Proposed share the same directional spectrum, random phases,
% radar geometry, TSC scattering model, speckle and receiver noise.

arguments
    cfg (1,1) struct = wind_wave_simulation_config()
end

validate_configuration(cfg);
if ~isfolder(cfg.paths.outputDir)
    mkdir(cfg.paths.outputDir);
end

[cfg, measuredMeta] = apply_measured_header(cfg);
[cfg, grid] = build_surface_grid(cfg);
[spectralState, spectrumMeta] = build_spectral_state(cfg, grid);
[windWaveState, windWaveMeta] = build_wind_wave_state( ...
    cfg, grid, spectralState);

snapshotTimes = linspace(0, measuredMeta.durationS, ...
    cfg.surface.snapshotCount).';
numberOfSnapshots = numel(snapshotTimes);
numberOfRangeBins = numel(cfg.radar.rangeMeters);

if cfg.output.generateRadarEcho
    linearTexturePower = zeros(numberOfSnapshots, numberOfRangeBins, 'single');
    proposedTexturePower = zeros(numberOfSnapshots, numberOfRangeBins, 'single');
else
    linearTexturePower = [];
    proposedTexturePower = [];
end

linearSnapshot = struct();
proposedSnapshot = struct();
evolutionIndices = unique(round(linspace(1, numberOfSnapshots, ...
    cfg.surface.evolutionFrameCount)));
evolutionTimes = snapshotTimes(evolutionIndices);
strideX = max(1, ceil(grid.Nx/500));
strideY = max(1, ceil(grid.Ny/160));
evolutionXIndex = 1:strideX:grid.Nx;
evolutionYIndex = 1:strideY:grid.Ny;
linearEvolutionZ = zeros(numel(evolutionYIndex), ...
    numel(evolutionXIndex), numel(evolutionIndices), 'single');
proposedEvolutionZ = zeros(size(linearEvolutionZ), 'single');
windWaveEvolutionZ = zeros(size(linearEvolutionZ), 'single');
linearFrameCorrelation = nan(numberOfSnapshots-1, 1);
proposedFrameCorrelation = nan(numberOfSnapshots-1, 1);
previousLinearZ = [];
previousProposedZ = [];

fprintf(['Generating %d geometry snapshots on a %d x %d grid ' ...
    'for %d range bins.\n'], numberOfSnapshots, grid.Ny, grid.Nx, ...
    numberOfRangeBins);

for snapshotIndex = 1:numberOfSnapshots
    t = snapshotTimes(snapshotIndex);
    etaLinear = synthesize_linear_surface(spectralState, grid, t);
    etaWindWave = synthesize_wind_wave_surface(windWaveState, grid, t);
    etaOrganized = windWaveState.combinedScale*( ...
        windWaveState.backgroundScale*etaLinear+etaWindWave);

    XLinear = grid.X0;
    YLinear = grid.Y0;
    ZLinear = etaLinear;

    [XProposed, YProposed, ZProposed, nonlinearDiagnostics] = ...
        apply_nonlinear_surface(etaOrganized, grid, spectralState, cfg);

    if snapshotIndex > 1
        linearFrameCorrelation(snapshotIndex-1) = ...
            spatial_correlation(previousLinearZ, ZLinear);
        proposedFrameCorrelation(snapshotIndex-1) = ...
            spatial_correlation(previousProposedZ, ZProposed);
    end
    previousLinearZ = ZLinear;
    previousProposedZ = ZProposed;

    evolutionSlot = find(evolutionIndices == snapshotIndex, 1);
    if ~isempty(evolutionSlot)
        linearEvolutionZ(:,:,evolutionSlot) = single( ...
            ZLinear(evolutionYIndex,evolutionXIndex));
        proposedEvolutionZ(:,:,evolutionSlot) = single( ...
            ZProposed(evolutionYIndex,evolutionXIndex));
        windWaveEvolutionZ(:,:,evolutionSlot) = single( ...
            etaWindWave(evolutionYIndex,evolutionXIndex));
    end

    if cfg.output.generateRadarEcho
        linearTexturePower(snapshotIndex, :) = single( ...
            range_power_from_surface(XLinear, YLinear, ZLinear, cfg));
        proposedTexturePower(snapshotIndex, :) = single( ...
            range_power_from_surface(XProposed, YProposed, ZProposed, cfg));
    end

    if snapshotIndex == 1
        linearSnapshot = make_surface_snapshot( ...
            XLinear, YLinear, ZLinear, struct(), cfg, 'Linear');
        proposedSnapshot = make_surface_snapshot( ...
            XProposed, YProposed, ZProposed, ...
            nonlinearDiagnostics, cfg, 'Proposed');
    end

    if snapshotIndex == 1 || snapshotIndex == numberOfSnapshots ...
            || mod(snapshotIndex, max(1, floor(numberOfSnapshots/10))) == 0
        fprintf('  geometry snapshot %d/%d, t = %.3f s\n', ...
            snapshotIndex, numberOfSnapshots, t);
    end
end

if cfg.output.generateRadarEcho
    assert(any(linearTexturePower(:) > 0), ...
        'Linear model produced no visible radar power.');
    assert(any(proposedTexturePower(:) > 0), ...
        'Proposed model produced no visible radar power.');
end

stateFile = fullfile(cfg.paths.outputDir, 'simulation_state.mat');
if cfg.output.saveSpectralState
    stateToSave = spectralState;
else
    stateToSave = rmfield(spectralState, 'H0');
end
save(stateFile, 'cfg', 'measuredMeta', 'grid', 'stateToSave', ...
    'spectrumMeta', 'windWaveState', 'windWaveMeta', ...
    'snapshotTimes', 'evolutionTimes', ...
    'evolutionXIndex', 'evolutionYIndex', 'linearEvolutionZ', ...
    'proposedEvolutionZ', 'windWaveEvolutionZ', ...
    'linearFrameCorrelation', ...
    'proposedFrameCorrelation', '-v7.3');

if cfg.output.saveSurfaceSnapshots
    save(fullfile(cfg.paths.outputDir, 'linear_surface_snapshot.mat'), ...
        'linearSnapshot', '-v7.3');
    save(fullfile(cfg.paths.outputDir, 'proposed_surface_snapshot.mat'), ...
        'proposedSnapshot', '-v7.3');
end
if cfg.output.makeSurfaceFigure
    plot_surface_pair(linearSnapshot, proposedSnapshot, cfg);
    plot_surface_evolution(grid, evolutionTimes, evolutionXIndex, ...
        evolutionYIndex, proposedEvolutionZ, cfg);
    plot_wind_wave_diagnostics(grid,windWaveState,evolutionTimes, ...
        evolutionXIndex,evolutionYIndex,windWaveEvolutionZ,cfg);
end

[surfaceGeometryTable,surfaceTemporalTable,windWaveDesignTable] = ...
    write_surface_validation_tables(linearSnapshot,proposedSnapshot, ...
    linearFrameCorrelation,proposedFrameCorrelation,snapshotTimes, ...
    windWaveMeta,cfg);

if ~cfg.output.generateRadarEcho
    summary.outputDirectory = cfg.paths.outputDir;
    summary.stateFile = stateFile;
    summary.linearEchoFile = '';
    summary.proposedEchoFile = '';
    summary.surfaceFigure = fullfile( ...
        cfg.paths.outputDir, 'linear_proposed_surface.png');
    summary.surfaceEvolutionFigure = fullfile( ...
        cfg.paths.outputDir, 'proposed_surface_evolution.png');
    summary.measuredMeta = measuredMeta;
    summary.spectrumMeta = spectrumMeta;
    summary.windWaveMeta = windWaveMeta;
    summary.linearMetrics = linearSnapshot.metrics;
    summary.proposedMetrics = proposedSnapshot.metrics;
    summary.temporalContinuity = surface_temporal_summary( ...
        snapshotTimes,linearFrameCorrelation,proposedFrameCorrelation);
    summary.surfaceGeometryTable = surfaceGeometryTable;
    summary.surfaceTemporalTable = surfaceTemporalTable;
    summary.windWaveDesignTable = windWaveDesignTable;
    save(fullfile(cfg.paths.outputDir, 'simulation_summary.mat'), ...
        'summary', '-v7.3');
    fprintf('Dynamic surface generation complete; radar echo skipped.\n');
    return;
end

fprintf('Generating paired two-scale complex speckle.\n');
rng(cfg.randomSeed + 100, 'twister');
[fastSpeckle, slowSpeckle] = generate_speckle_components( ...
    cfg.radar.numPulses, numberOfRangeBins, cfg);
linearSpeckle = combine_speckle_components(fastSpeckle,slowSpeckle, ...
    cfg.echo.linearSlowSpecklePowerFraction);
proposedSpeckle = combine_speckle_components(fastSpeckle,slowSpeckle, ...
    cfg.echo.proposedSlowSpecklePowerFraction);
clear fastSpeckle slowSpeckle;

fprintf('Generating persistent compound-Gaussian wind-wave texture.\n');
proposedCompoundTexture = generate_wind_wave_texture( ...
    cfg.radar.numPulses,numberOfRangeBins,cfg);
sharedNoise = complex( ...
    randn(cfg.radar.numPulses, numberOfRangeBins, 'single'), ...
    randn(cfg.radar.numPulses, numberOfRangeBins, 'single')) / sqrt(2);

linearEcho = synthesize_echo_from_texture( ...
    linearTexturePower,snapshotTimes,linearSpeckle,[],cfg,'Linear');
proposedEcho = synthesize_echo_from_texture( ...
    proposedTexturePower,snapshotTimes,proposedSpeckle, ...
    proposedCompoundTexture,cfg,'Proposed');
clear linearSpeckle proposedSpeckle proposedCompoundTexture;
[linearEcho, proposedEcho] = add_common_receiver_noise( ...
    linearEcho, proposedEcho, sharedNoise, cfg);
save(fullfile(cfg.paths.outputDir, 'linear_radar_echo.mat'), ...
    'linearEcho', '-v7.3');
save(fullfile(cfg.paths.outputDir, 'proposed_radar_echo.mat'), ...
    'proposedEcho', '-v7.3');

summary.outputDirectory = cfg.paths.outputDir;
summary.stateFile = stateFile;
summary.linearEchoFile = fullfile( ...
    cfg.paths.outputDir, 'linear_radar_echo.mat');
summary.proposedEchoFile = fullfile( ...
    cfg.paths.outputDir, 'proposed_radar_echo.mat');
summary.surfaceFigure = fullfile( ...
    cfg.paths.outputDir, 'linear_proposed_surface.png');
summary.surfaceEvolutionFigure = fullfile( ...
    cfg.paths.outputDir, 'proposed_surface_evolution.png');
summary.measuredMeta = measuredMeta;
summary.spectrumMeta = spectrumMeta;
summary.windWaveMeta = windWaveMeta;
summary.linearMetrics = linearSnapshot.metrics;
summary.proposedMetrics = proposedSnapshot.metrics;
summary.temporalContinuity = surface_temporal_summary( ...
    snapshotTimes,linearFrameCorrelation,proposedFrameCorrelation);
summary.surfaceGeometryTable = surfaceGeometryTable;
summary.surfaceTemporalTable = surfaceTemporalTable;
summary.windWaveDesignTable = windWaveDesignTable;
save(fullfile(cfg.paths.outputDir, 'simulation_summary.mat'), ...
    'summary', '-v7.3');
end

function validate_configuration(cfg)
assert(isfile(cfg.paths.measuredFile), ...
    'Measured MAT file not found: %s', cfg.paths.measuredFile);
assert(cfg.surface.dx > 0 && cfg.surface.dy > 0, ...
    'Surface sampling intervals must be positive.');
assert(cfg.surface.snapshotCount >= 2, ...
    'At least two geometry snapshots are required.');
assert(cfg.surface.evolutionFrameCount >= 2, ...
    'At least two saved evolution frames are required.');
assert(cfg.windWave.energyFraction >= 0 ...
    && cfg.windWave.energyFraction < 1, ...
    'Wind-wave energy fraction must lie in [0,1).');
assert(cfg.windWave.peakPeriodS > 0 ...
    && cfg.windWave.relativeWavenumberBandwidth > 0 ...
    && cfg.windWave.directionalSpreadingExponent > 0, ...
    'Wind-wave period, bandwidth and spreading exponent must be positive.');
assert(cfg.echo.numPulses >= 2, 'At least two pulses are required.');
assert(cfg.echo.fastSpeckleCorrelationTimeS > 0 ...
    && cfg.echo.slowSpeckleCorrelationTimeS > 0, ...
    'Speckle correlation times must be positive.');
assert(cfg.echo.linearSlowSpecklePowerFraction >= 0 ...
    && cfg.echo.linearSlowSpecklePowerFraction <= 1 ...
    && cfg.echo.proposedSlowSpecklePowerFraction >= 0 ...
    && cfg.echo.proposedSlowSpecklePowerFraction <= 1, ...
    'Speckle power fractions must lie in [0,1].');
assert(mod(cfg.echo.windWaveTextureDegreesOfFreedom,2) == 0 ...
    && cfg.echo.windWaveTextureDegreesOfFreedom >= 2, ...
    'Texture degrees of freedom must be a positive even integer.');
assert(cfg.echo.windWaveTextureCorrelationTimeS > 0 ...
    && cfg.echo.windWaveTextureRangeCorrelationM > 0, ...
    'Wind-wave texture correlation scales must be positive.');
assert(cfg.echo.effectiveRangeCorrelationBandwidthHz > 0 ...
    && cfg.echo.effectiveRangeCorrelationBandwidthHz ...
    <= cfg.radar.bandwidthHz, ...
    'Effective range-correlation bandwidth must lie in (0, radar bandwidth].');
assert(diff(cfg.scene.requestedRangeLimitsM) > 0, ...
    'Requested range limits must be increasing.');
end

function [cfg, meta] = apply_measured_header(cfg)
variableInfo = whos('-file', cfg.paths.measuredFile);
names = {variableInfo.name};
echoIndex = find(strcmp(names, cfg.paths.measuredEchoVariable), 1);
assert(~isempty(echoIndex), 'Measured echo variable %s was not found.', ...
    cfg.paths.measuredEchoVariable);

loaded = load(cfg.paths.measuredFile, 'amplitude_complex_info');
info = double(loaded.amplitude_complex_info);
clear loaded;

actualPulseCount = variableInfo(echoIndex).size(1);
actualRangeCount = variableInfo(echoIndex).size(2);
assert(size(info, 1) == actualPulseCount, ...
    'Measured header rows do not match measured pulses.');

if strcmp(cfg.paths.measuredEchoVariable, 'amplitude_complex_T1')
    firstRangeM = info(1, 11) * 1000;
elseif strcmp(cfg.paths.measuredEchoVariable, 'amplitude_complex_T2')
    firstRangeM = info(1, 12) * 1000;
else
    error('Only T1 or T2 measured echo variables are supported.');
end

samplingRateHz = median(info(:, 10), 'omitnan') * 1e6;
rangeSpacingM = cfg.radar.c / (2 * samplingRateHz);
allRangesM = firstRangeM + (0:actualRangeCount-1) * rangeSpacingM;
rangeIndex = find(allRangesM >= cfg.scene.requestedRangeLimitsM(1) ...
    & allRangesM <= cfg.scene.requestedRangeLimitsM(2));
assert(~isempty(rangeIndex), 'Requested range interval is outside the MAT data.');

cfg.radar.samplingRateHz = samplingRateHz;
cfg.radar.rangeSpacingM = rangeSpacingM;
cfg.radar.rangeIndices = rangeIndex;
cfg.radar.rangeMeters = allRangesM(rangeIndex);
cfg.radar.prfHz = median(info(:, 26), 'omitnan');
cfg.radar.boresightBearingDeg = mean(info(:, 9), 'omitnan');
cfg.radar.lambdaM = cfg.radar.c / cfg.radar.fcHz;
cfg.radar.numPulses = min([cfg.echo.numPulses, actualPulseCount]);
cfg.radar.slowTimeS = (0:cfg.radar.numPulses-1).' / cfg.radar.prfHz;

durationS = (cfg.radar.numPulses - 1) / cfg.radar.prfHz;
meta.sourceFile = cfg.paths.measuredFile;
meta.echoVariable = cfg.paths.measuredEchoVariable;
meta.actualPulseCount = actualPulseCount;
meta.actualRangeCount = actualRangeCount;
meta.usedPulseCount = cfg.radar.numPulses;
meta.usedRangeIndices = rangeIndex;
meta.rangeMeters = cfg.radar.rangeMeters;
meta.rangeSpacingM = rangeSpacingM;
meta.prfHz = cfg.radar.prfHz;
meta.meanBearingDeg = cfg.radar.boresightBearingDeg;
meta.startTimeCode = info(1, 14);
meta.endTimeCode = info(cfg.radar.numPulses, 14);
meta.durationS = durationS;
meta.scanModeCode = info(1, 22);
meta.stcCode = info(1, 21);

fprintf(['Measured header: %d pulses used, %d range bins from %.3f to ' ...
    '%.3f km, PRF %.1f Hz, mean bearing %.2f deg.\n'], ...
    cfg.radar.numPulses, numel(rangeIndex), ...
    cfg.radar.rangeMeters(1)/1000, cfg.radar.rangeMeters(end)/1000, ...
    cfg.radar.prfHz, cfg.radar.boresightBearingDeg);
end

function [cfg, grid] = build_surface_grid(cfg)
height = cfg.radar.heightM;
rangeNear = cfg.radar.rangeMeters(1);
rangeFar = cfg.radar.rangeMeters(end);
xStart = sqrt(max(rangeNear^2 - height^2, 0)) ...
    - cfg.scene.rangeMarginM;
xEndRequested = sqrt(max(rangeFar^2 - height^2, 0)) ...
    + cfg.scene.rangeMarginM;
xStart = max(0, xStart);

Nx = ceil((xEndRequested - xStart) / cfg.surface.dx) + 1;
Nx = 2 * ceil(Nx / 2);
Ny = ceil(cfg.scene.crossRangeWidthM / cfg.surface.dy);
Ny = 2 * ceil(Ny / 2);

x = xStart + (0:Nx-1) * cfg.surface.dx;
y = ((0:Ny-1) - Ny/2) * cfg.surface.dy;
[X0, Y0] = meshgrid(x, y);

grid.x = x;
grid.y = y;
grid.X0 = X0;
grid.Y0 = Y0;
grid.Nx = Nx;
grid.Ny = Ny;
grid.Lx = Nx * cfg.surface.dx;
grid.Ly = Ny * cfg.surface.dy;

centreHorizontalRange = mean([x(1), x(end)]);
cfg.radar.boresightElevationDeg = ...
    -atan2d(cfg.radar.heightM, centreHorizontalRange);
end

function [state, meta] = build_spectral_state(cfg, grid)
Nx = grid.Nx;
Ny = grid.Ny;
dkx = 2*pi/grid.Lx;
dky = 2*pi/grid.Ly;
kx = ifftshift((-Nx/2:Nx/2-1) * dkx);
ky = ifftshift((-Ny/2:Ny/2-1) * dky);
[KX, KY] = meshgrid(kx, ky);
[phi, K] = cart2pol(KX, KY);

waveToDeg = mod(cfg.environment.waveFromDeg + 180, 360);
directionAxisLocalDeg = wrap_to_180( ...
    cfg.radar.boresightBearingDeg - waveToDeg);
directionAxisRad = deg2rad(directionAxisLocalDeg);

[inverseWaveAge, periodDiagnostics] = calibrate_wave_age( ...
    K, phi, dkx, dky, directionAxisRad, cfg);
[PsiUnscaled, elfouhailyMeta] = elfouhaily_spectrum( ...
    K, phi, cfg.environment.U10, inverseWaveAge, directionAxisRad);

targetM0 = (cfg.environment.Hs/4)^2;
unscaledM0 = sum(PsiUnscaled, 'all') * dkx * dky;
Psi = PsiUnscaled * targetM0 / max(unscaledM0, eps);

    rng(cfg.randomSeed, 'twister');
    phaseSeed = fft2(randn(Ny, Nx));
    randomPhase = angle(phaseSeed);
    H0 = sqrt(2 * Psi * dkx * dky) .* exp(1i*randomPhase);
    H0(1,1) = 0;
    H0(:,Nx/2+1) = 0;
    H0(Ny/2+1,:) = 0;

g = cfg.environment.gravity;
km = 370;
    omega = sqrt(g*K .* (1 + (K/km).^2));
    propagationProjection = KX*cos(directionAxisRad) ...
        + KY*sin(directionAxisRad);
    signedOmega = omega.*sign(propagationProjection);

eta0 = real(ifft2(H0) * Nx * Ny);
eta0 = eta0 - mean(eta0, 'all');
realizationScale = 1;
if cfg.surface.rescaleRealizationToHs
    realizationScale = (cfg.environment.Hs/4) ...
        / max(std(eta0, 1, 'all'), eps);
    H0 = H0 * realizationScale;
end

state.H0 = single(H0);
    state.omega = single(omega);
    state.signedOmega = single(signedOmega);
state.KX = single(KX);
state.KY = single(KY);
state.K = single(K);
state.kx = kx;
state.ky = ky;
state.directionAxisRad = directionAxisRad;
state.inverseWaveAge = inverseWaveAge;
state.realizationScale = realizationScale;

meta = elfouhailyMeta;
meta.periodDiagnostics = periodDiagnostics;
meta.directionAxisLocalDeg = directionAxisLocalDeg;
meta.targetHs = cfg.environment.Hs;
meta.inverseWaveAge = inverseWaveAge;
meta.realizationScale = realizationScale;
end

function [state,meta] = build_wind_wave_state(cfg,grid,backgroundState)
fraction = cfg.windWave.energyFraction;
if ~cfg.windWave.enabled
    fraction = 0;
end
assert(fraction >= 0 && fraction < 1, ...
    'windWave.energyFraction must lie in [0,1).');

K = double(backgroundState.K);
KX = double(backgroundState.KX);
KY = double(backgroundState.KY);
[phi,~] = cart2pol(KX,KY);
directionAxisRad = double(backgroundState.directionAxisRad);
g = cfg.environment.gravity;
peakOmega = 2*pi/cfg.windWave.peakPeriodS;
kp = peakOmega^2/g;
relativeBandwidth = cfg.windWave.relativeWavenumberBandwidth;
spreadingExponent = cfg.windWave.directionalSpreadingExponent;

radialShape = exp(-0.5*((K-kp)/max(relativeBandwidth*kp,eps)).^2);
axialOffset = acos(min(abs(cos(phi-directionAxisRad)),1));
directionalShape = cos(axialOffset).^(2*spreadingExponent);
shape = radialShape.*directionalShape;
shape(K == 0 | ~isfinite(shape)) = 0;

rng(cfg.randomSeed+cfg.windWave.seedOffset,'twister');
phaseSeed = fft2(randn(grid.Ny,grid.Nx));
H0 = sqrt(shape).*exp(1i*angle(phaseSeed));
H0(1,1) = 0;
H0(:,grid.Nx/2+1) = 0;
H0(grid.Ny/2+1,:) = 0;

targetWindStd = (cfg.environment.Hs/4)*sqrt(fraction);
etaWind0 = real(ifft2(H0)*grid.Nx*grid.Ny);
etaWind0 = etaWind0-mean(etaWind0,'all');
if targetWindStd > 0
    H0 = H0*(targetWindStd/max(std(etaWind0,1,'all'),eps));
else
    H0(:) = 0;
end

backgroundScale = sqrt(1-fraction);
etaBackground0 = synthesize_linear_surface(backgroundState,grid,0);
etaWind0 = real(ifft2(H0)*grid.Nx*grid.Ny);
combined0 = backgroundScale*etaBackground0+etaWind0;
targetStd = cfg.environment.Hs/4;
combinedScale = targetStd/max(std(combined0,1,'all'),eps);

state.H0 = single(H0);
state.signedOmega = backgroundState.signedOmega;
state.backgroundScale = backgroundScale;
state.combinedScale = combinedScale;
state.directionAxisRad = directionAxisRad;
state.kp = kp;

meta.enabled = cfg.windWave.enabled;
meta.energyFraction = fraction;
meta.peakPeriodS = cfg.windWave.peakPeriodS;
meta.peakWavenumberRadM = kp;
meta.peakWavelengthM = 2*pi/kp;
meta.phaseSpeedMps = peakOmega/kp;
meta.groupSpeedMps = 0.5*peakOmega/kp;
meta.relativeWavenumberBandwidth = relativeBandwidth;
meta.directionalSpreadingExponent = spreadingExponent;
meta.directionalHalfPowerWidthDeg = rad2deg( ...
    acos(0.5^(1/(2*spreadingExponent))));
meta.directionAxisLocalDeg = rad2deg(directionAxisRad);
meta.backgroundScale = backgroundScale;
meta.combinedScale = combinedScale;
meta.realizedInitialHs = 4*std(combinedScale*combined0,1,'all');
end

function eta = synthesize_wind_wave_surface(state,grid,t)
phaseEvolution = exp(-1i*double(state.signedOmega)*t);
complexEta = ifft2(double(state.H0).*phaseEvolution)*grid.Nx*grid.Ny;
imaginaryLeakage = rms(imag(complexEta),'all') ...
    / max(rms(real(complexEta),'all'),eps);
assert(imaginaryLeakage < 1e-6, ...
    'Wind-wave evolution lost Hermitian symmetry (relative leak %.3g).', ...
    imaginaryLeakage);
eta = real(complexEta);
eta = eta-mean(eta,'all');
end

function eta = synthesize_linear_surface(state, grid, t)
phaseEvolution = exp(-1i * double(state.signedOmega) * t);
complexEta = ifft2(double(state.H0) .* phaseEvolution) ...
    * grid.Nx * grid.Ny;
imaginaryLeakage = rms(imag(complexEta), 'all') ...
    / max(rms(real(complexEta), 'all'), eps);
assert(imaginaryLeakage < 1e-6, ...
    'Spectral evolution lost Hermitian symmetry (relative leak %.3g).', ...
    imaginaryLeakage);
eta = real(complexEta);
eta = eta - mean(eta, 'all');
end

function [X, Y, Z, diagnostics] = apply_nonlinear_surface(eta, grid, state, cfg)
KX = double(state.KX);
KY = double(state.KY);
K = double(state.K);
Ksafe = max(K, eps);

nyquistRadius = min(pi/cfg.surface.dx, pi/cfg.surface.dy);
cutoff = cfg.nonlinear.cutoffFraction * nyquistRadius;
antiAlias = exp(-(K/max(cutoff, eps)).^cfg.nonlinear.filterOrder);

directionAxisRad = local_wave_axis(cfg);
projection = abs((KX*cos(directionAxisRad) ...
    + KY*sin(directionAxisRad)) ./ Ksafe);
directionWeight = (1-cfg.nonlinear.directionStrength) ...
    + cfg.nonlinear.directionStrength ...
    * projection.^cfg.nonlinear.directionExponent;
directionWeight(K == 0) = 0;

windGain = cfg.nonlinear.baseGain ...
    * (cfg.environment.U10/cfg.nonlinear.referenceWindSpeed) ...
    ^ cfg.nonlinear.windExponent;
windGain = min(max(windGain, cfg.nonlinear.minimumWindGain), ...
    cfg.nonlinear.maximumWindGain);

etaSquared = eta.^2 - mean(eta.^2, 'all');
etaSecond = real(ifft2(0.5*K .* directionWeight .* antiAlias ...
    .* fft2(etaSquared)));
etaSecond = etaSecond - mean(etaSecond, 'all');
Z = eta + windGain*etaSecond;
Z = Z - mean(Z, 'all');

etaHat = fft2(eta);
Dx = real(ifft2(-1i*(KX./Ksafe).*etaHat.*antiAlias));
Dy = real(ifft2(-1i*(KY./Ksafe).*etaHat.*antiAlias));

lambda = cfg.nonlinear.horizontalDisplacement * windGain;
[lambda, minimumJacobian, backoffSteps] = stable_horizontal_gain( ...
    Dx, Dy, cfg.surface.dx, cfg.surface.dy, lambda, cfg.nonlinear);
X = grid.X0 + lambda*Dx;
Y = grid.Y0 + lambda*Dy;

diagnostics.windGain = windGain;
diagnostics.horizontalGain = lambda;
diagnostics.minimumHorizontalJacobian = minimumJacobian;
diagnostics.horizontalBackoffSteps = backoffSteps;
diagnostics.secondOrderRms = sqrt(mean(etaSecond.^2, 'all'));
end

function axisRad = local_wave_axis(cfg)
waveToDeg = mod(cfg.environment.waveFromDeg + 180, 360);
axisRad = deg2rad(wrap_to_180( ...
    cfg.radar.boresightBearingDeg - waveToDeg));
end

function [lambda, minimumJacobian, steps] = stable_horizontal_gain( ...
    Dx, Dy, dx, dy, lambda, nonlinear)
[Dxx, Dxy] = gradient(Dx, dx, dy);
[Dyx, Dyy] = gradient(Dy, dx, dy);
for steps = 0:nonlinear.maximumBackoffSteps
    J = (1+lambda*Dxx).*(1+lambda*Dyy) ...
        - lambda^2.*Dxy.*Dyx;
    minimumJacobian = min(J, [], 'all');
    if minimumJacobian >= nonlinear.minimumJacobian
        return;
    end
    lambda = lambda * nonlinear.backoffFactor;
end
error('Unable to obtain a non-folding Proposed horizontal mapping.');
end

function rangePower = range_power_from_surface(X, Y, Z, cfg)
% Two upward triangles per structured cell, evaluated without storing a
% global face list. This keeps memory bounded for the server-scale scene.
X00 = X(1:end-1, 1:end-1); Y00 = Y(1:end-1, 1:end-1); Z00 = Z(1:end-1, 1:end-1);
X10 = X(1:end-1, 2:end);   Y10 = Y(1:end-1, 2:end);   Z10 = Z(1:end-1, 2:end);
X01 = X(2:end, 1:end-1);   Y01 = Y(2:end, 1:end-1);   Z01 = Z(2:end, 1:end-1);
X11 = X(2:end, 2:end);     Y11 = Y(2:end, 2:end);     Z11 = Z(2:end, 2:end);

[a1x, a1y, a1z] = cross_components( ...
    X10-X00, Y10-Y00, Z10-Z00, X11-X00, Y11-Y00, Z11-Z00);
[a2x, a2y, a2z] = cross_components( ...
    X11-X00, Y11-Y00, Z11-Z00, X01-X00, Y01-Y00, Z01-Z00);

area = 0.5*(sqrt(a1x.^2+a1y.^2+a1z.^2) ...
    + sqrt(a2x.^2+a2y.^2+a2z.^2));
avx = a1x+a2x; avy = a1y+a2y; avz = a1z+a2z;
normalNorm = sqrt(avx.^2+avy.^2+avz.^2);
nx = avx./max(normalNorm, eps);
ny = avy./max(normalNorm, eps);
nz = avz./max(normalNorm, eps);

xc = 0.25*(X00+X10+X01+X11);
yc = 0.25*(Y00+Y10+Y01+Y11);
zc = 0.25*(Z00+Z10+Z01+Z11);

lx = -xc;
ly = -yc;
lz = cfg.radar.heightM-zc;
slantRange = sqrt(lx.^2+ly.^2+lz.^2);
cosIncidence = (nx.*lx+ny.*ly+nz.*lz) ./ max(slantRange, eps);
grazingDeg = asind(max(min(cosIncidence, 1), -1));

visible = cosIncidence > 0 ...
    & grazingDeg >= cfg.echo.minimumGrazingDeg;
if cfg.echo.useHorizonShadowing
    visible = visible & horizon_visibility(xc, yc, zc, cfg);
end

horizontalRange = hypot(xc, yc);
azimuthOffsetDeg = atan2d(yc, xc);
elevationDeg = atan2d(zc-cfg.radar.heightM, horizontalRange);
elevationOffsetDeg = elevationDeg-cfg.radar.boresightElevationDeg;
azimuthGain = exp(-4*log(2) ...
    * (azimuthOffsetDeg/cfg.radar.azimuthHpbwDeg).^2);
elevationGain = exp(-4*log(2) ...
    * (elevationOffsetDeg/cfg.radar.elevationHpbwDeg).^2);
antennaPowerGain = azimuthGain.*elevationGain;

globalBearingDeg = mod(cfg.radar.boresightBearingDeg ...
    - azimuthOffsetDeg, 360);
relativeWindDeg = abs(wrap_to_180( ...
    cfg.environment.windFromDeg-globalBearingDeg));

sigma0Db = tsc_sigma0_db(cfg.radar.fcHz/1e9, ...
    cfg.environment.seaState, grazingDeg, relativeWindDeg, ...
    cfg.environment.U10);
sigma0Linear = 10.^(sigma0Db/10);
effectiveArea = area.*max(nz, 0);
facetRcs = sigma0Linear.*effectiveArea;

rangeBin = round((slantRange-cfg.radar.rangeMeters(1)) ...
    / cfg.radar.rangeSpacingM)+1;
valid = visible ...
    & antennaPowerGain >= cfg.echo.minimumAntennaPowerGain ...
    & rangeBin >= 1 & rangeBin <= numel(cfg.radar.rangeMeters) ...
    & isfinite(facetRcs) & facetRcs > 0;

radarConstant = cfg.radar.peakPowerW*cfg.radar.lambdaM^2/(4*pi)^3;
facetPower = radarConstant.*facetRcs.*antennaPowerGain.^2 ...
    ./ max(slantRange, 1).^4;
rangePower = accumarray(rangeBin(valid), facetPower(valid), ...
    [numel(cfg.radar.rangeMeters), 1], @sum, 0).';
end

function visible = horizon_visibility(xc, yc, zc, cfg)
horizontalRange = hypot(xc, yc);
elevation = atan2(zc-cfg.radar.heightM, horizontalRange);
previousMaximum = [-inf(size(elevation,1),1), ...
    cummax(elevation(:,1:end-1),2)];
visible = elevation >= previousMaximum ...
    - deg2rad(cfg.echo.shadowToleranceDeg);
end

function [cx, cy, cz] = cross_components(ax, ay, az, bx, by, bz)
cx = ay.*bz-az.*by;
cy = az.*bx-ax.*bz;
cz = ax.*by-ay.*bx;
end

function snapshot = make_surface_snapshot(X, Y, Z, diagnostics, cfg, name)
[sx, sy] = gradient(Z, cfg.surface.dx, cfg.surface.dy);
snapshot.name = name;
snapshot.X = single(X);
snapshot.Y = single(Y);
snapshot.Z = single(Z);
snapshot.metrics.Hs = 4*std(Z, 1, 'all');
snapshot.metrics.skewness = standardized_moment(Z, 3);
snapshot.metrics.kurtosis = standardized_moment(Z, 4);
snapshot.metrics.parameterDomainMss = mean(sx.^2+sy.^2, 'all');
snapshot.metrics.maximumCrest = max(Z, [], 'all');
snapshot.metrics.minimumTrough = min(Z, [], 'all');
snapshot.metrics.diagnostics = diagnostics;
snapshot.cfg = cfg;
end

function value = standardized_moment(z, order)
centred = z-mean(z, 'all');
scale = std(centred, 1, 'all');
value = mean((centred/max(scale,eps)).^order, 'all');
end

function [fast,slow] = generate_speckle_components(numPulses,numBins,cfg)
fast = generate_ar_speckle(numPulses,numBins, ...
    cfg.radar.prfHz,cfg.echo.fastSpeckleCorrelationTimeS);
slow = generate_ar_speckle(numPulses,numBins, ...
    cfg.radar.prfHz,cfg.echo.slowSpeckleCorrelationTimeS);
end

function speckle = combine_speckle_components(fast,slow,slowFraction)
speckle = sqrt(1-slowFraction)*fast+sqrt(slowFraction)*slow;
powerPerRange = mean(abs(speckle).^2, 1);
speckle = speckle./sqrt(max(powerPerRange,realmin('single')));
end

function speckle = generate_ar_speckle(numPulses,numBins,prfHz,tauS)
rho = exp(-1/(prfHz*tauS));
innovationScale = sqrt(max(1-rho^2, 0));
speckle = complex(zeros(numPulses, numBins, 'single'));
speckle(1,:) = complex(randn(1,numBins,'single'), ...
    randn(1,numBins,'single'))/sqrt(2);
for pulseIndex = 2:numPulses
    innovation = complex(randn(1,numBins,'single'), ...
        randn(1,numBins,'single'))/sqrt(2);
    speckle(pulseIndex,:) = rho*speckle(pulseIndex-1,:) ...
        + innovationScale*innovation;
end
end

function texture = generate_wind_wave_texture(numPulses,numBins,cfg)
if ~cfg.echo.windWaveTextureEnabled
    texture = [];
    return;
end

% Squared correlated normal fields produce Gamma texture with shape nu=dof/2.
% Separate AR recursions set the slow-time and range persistence directly.
rng(cfg.randomSeed+cfg.echo.windWaveTextureSeedOffset,'twister');
rhoTime = exp(-1/(cfg.radar.prfHz ...
    *cfg.echo.windWaveTextureCorrelationTimeS));
rhoRange = exp(-cfg.radar.rangeSpacingM ...
    /cfg.echo.windWaveTextureRangeCorrelationM);
timeInnovation = sqrt(max(1-rhoTime^2,0));
rangeInnovation = sqrt(max(1-rhoRange^2,0));
dof = cfg.echo.windWaveTextureDegreesOfFreedom;
texture = zeros(numPulses,numBins,'single');

for componentIndex = 1:dof
    field = randn(numPulses,numBins,'single');
    for pulseIndex = 2:numPulses
        field(pulseIndex,:) = rhoTime*field(pulseIndex-1,:) ...
            + timeInnovation*field(pulseIndex,:);
    end
    for rangeIndex = 2:numBins
        field(:,rangeIndex) = rhoRange*field(:,rangeIndex-1) ...
            + rangeInnovation*field(:,rangeIndex);
    end
    texture = texture+field.^2;
    clear field;
end
texture = texture/dof;
texture = texture/max(mean(texture,'all'),realmin('single'));
end

function echoData = synthesize_echo_from_texture(textureSnapshots, ...
    snapshotTimes,speckle,compoundTexture,cfg,modelName)
pulseTimes = cfg.radar.slowTimeS;
positive = textureSnapshots(textureSnapshots > 0);
powerFloor = max(max(positive)*1e-12, realmin('single'));
logSnapshots = log(max(double(textureSnapshots), double(powerFloor)));
logPower = interp1(snapshotTimes, logSnapshots, pulseTimes, 'pchip');
texturePower = exp(logPower);
physicalMeanPower = mean(texturePower, 'all');

rangePhase = exp(-1i*4*pi*cfg.radar.rangeMeters/cfg.radar.lambdaM);
echo = single(sqrt(texturePower)).*speckle;
echo = echo.*single(rangePhase);

halfWidth = cfg.echo.pulseCompressionHalfWidth;
sampleIndex = -halfWidth:halfWidth;
argument = (cfg.echo.effectiveRangeCorrelationBandwidthHz ...
    /cfg.radar.samplingRateHz)*sampleIndex;
kernel = normalized_sinc(argument) ...
    .* (0.54+0.46*cos(pi*sampleIndex/(halfWidth+1)));
kernel = kernel/sqrt(sum(abs(kernel).^2));
echo = conv2(echo, single(kernel), 'same');
% The Gamma field is the resolution-cell-scale hydrodynamic texture. Apply
% it after coherent pulse compression so the receiver response does not
% incorrectly average away the slowly varying compound-Gaussian modulation.
if ~isempty(compoundTexture)
    echo = echo.*sqrt(compoundTexture);
end

echoData.modelName = modelName;
echoData.echo = echo;
echoData.orientation = 'pulse_by_range';
echoData.rangeMeters = cfg.radar.rangeMeters;
echoData.slowTimeS = cfg.radar.slowTimeS;
echoData.textureSnapshotTimesS = snapshotTimes;
echoData.texturePowerSnapshots = textureSnapshots;
echoData.meanEchoPowerByRange = mean(abs(echo).^2,1);
echoData.physicalMeanPowerBeforeNormalization = physicalMeanPower;
echoData.compoundTextureApplied = ~isempty(compoundTexture);
if isempty(compoundTexture)
    echoData.compoundTextureMean = 1;
    echoData.compoundTextureShapeNu = Inf;
else
    echoData.compoundTextureMean = mean(compoundTexture,'all');
    echoData.compoundTextureShapeNu = ...
        cfg.echo.windWaveTextureDegreesOfFreedom/2;
end
echoData.signalRmsBeforeNoise = sqrt(mean(abs(echo).^2, 'all'));
echoData.amplitudeNormalizationApplied = false;
echoData.pulseCompressionKernel = kernel;
echoData.cfg = cfg;
end

function [linearEcho, proposedEcho] = add_common_receiver_noise( ...
    linearEcho, proposedEcho, sharedNoise, cfg)
referenceRms = linearEcho.signalRmsBeforeNoise;
noiseRms = referenceRms*10^(cfg.echo.noiseRelativeDb/20);
noise = single(noiseRms)*sharedNoise;
linearEcho.echo = linearEcho.echo+noise;
proposedEcho.echo = proposedEcho.echo+noise;
linearEcho.commonNoiseRms = noiseRms;
proposedEcho.commonNoiseRms = noiseRms;
linearEcho.noiseReference = 'Linear signal RMS before receiver noise';
proposedEcho.noiseReference = 'Linear signal RMS before receiver noise';
linearEcho.meanEchoPowerByRange = mean(abs(linearEcho.echo).^2,1);
proposedEcho.meanEchoPowerByRange = mean(abs(proposedEcho.echo).^2,1);
end

function y = normalized_sinc(x)
y = ones(size(x));
nonzero = x ~= 0;
y(nonzero) = sin(pi*x(nonzero))./(pi*x(nonzero));
end

function value = spatial_correlation(a,b)
a = double(a(:));
b = double(b(:));
a = a-mean(a);
b = b-mean(b);
value = (a.'*b)/max(norm(a)*norm(b),eps);
end

function temporal = surface_temporal_summary( ...
    snapshotTimes,linearCorrelation,proposedCorrelation)
temporal.snapshotIntervalS = median(diff(snapshotTimes));
temporal.linearMeanFrameCorrelation = ...
    mean(linearCorrelation,'omitnan');
temporal.proposedMeanFrameCorrelation = ...
    mean(proposedCorrelation,'omitnan');
temporal.linearMinimumFrameCorrelation = ...
    min(linearCorrelation,[],'omitnan');
temporal.proposedMinimumFrameCorrelation = ...
    min(proposedCorrelation,[],'omitnan');
end

function [geometryTable,temporalTable,designTable] = ...
    write_surface_validation_tables(linearSnapshot,proposedSnapshot, ...
    linearCorrelation,proposedCorrelation,snapshotTimes,windMeta,cfg)
linearMetrics = linearSnapshot.metrics;
proposedMetrics = proposedSnapshot.metrics;
relativeDifference = rms(double(proposedSnapshot.Z-linearSnapshot.Z),'all') ...
    / max(rms(double(linearSnapshot.Z),'all'),eps);
geometryTable = table( ...
    {'Linear';'Proposed'}, ...
    [linearMetrics.Hs;proposedMetrics.Hs], ...
    [linearMetrics.skewness;proposedMetrics.skewness], ...
    [linearMetrics.kurtosis;proposedMetrics.kurtosis], ...
    [linearMetrics.parameterDomainMss;proposedMetrics.parameterDomainMss], ...
    [linearMetrics.maximumCrest;proposedMetrics.maximumCrest], ...
    [linearMetrics.minimumTrough;proposedMetrics.minimumTrough], ...
    [0;relativeDifference], ...
    'VariableNames',{'Group','HsM','HeightSkewness','HeightKurtosis', ...
    'MeanSquareSlope','MaximumCrestM','MinimumTroughM', ...
    'RelativeHeightDifferenceFromLinear'});

temporal = surface_temporal_summary( ...
    snapshotTimes,linearCorrelation,proposedCorrelation);
temporalTable = table( ...
    {'Linear';'Proposed'}, ...
    [temporal.linearMeanFrameCorrelation; ...
    temporal.proposedMeanFrameCorrelation], ...
    [temporal.linearMinimumFrameCorrelation; ...
    temporal.proposedMinimumFrameCorrelation], ...
    repmat(temporal.snapshotIntervalS,2,1), ...
    'VariableNames',{'Group','MeanAdjacentFrameCorrelation', ...
    'MinimumAdjacentFrameCorrelation','SnapshotIntervalS'});

designTable = struct2table(windMeta,'AsArray',true);
writetable(geometryTable,fullfile(cfg.paths.outputDir, ...
    'surface_geometry_metrics.csv'));
writetable(temporalTable,fullfile(cfg.paths.outputDir, ...
    'surface_temporal_continuity_metrics.csv'));
writetable(designTable,fullfile(cfg.paths.outputDir, ...
    'wind_wave_design_metrics.csv'));
end

function plot_wind_wave_diagnostics(surfaceGrid,state,times,ix,iy,windZ,cfg)
fig = figure('Color','w','Position',[60 70 1500 620]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
nexttile(layout);
imagesc(surfaceGrid.x(ix)/1000,surfaceGrid.y(iy),double(windZ(:,:,1)));
axis xy tight;
xlabel('Range (km)'); ylabel('Cross-range (m)');
title('Organized wind-wave component at t = 0');
colorbar;

nexttile(layout);
centreRow = round(size(windZ,1)/2);
centreRange = mean(surfaceGrid.x);
window = surfaceGrid.x(ix) >= centreRange-250 ...
    & surfaceGrid.x(ix) <= centreRange+250;
hold on;
for index = 1:numel(times)
    plot(surfaceGrid.x(ix(window))/1000, ...
        double(squeeze(windZ(centreRow,window,index))), ...
        'LineWidth',1.2,'DisplayName',sprintf('t=%.2f s',times(index)));
end
hold off; grid on;
xlabel('Range (km)'); ylabel('Wind-wave height (m)');
title('Continuous propagation through a fixed transect');
legend('Location','eastoutside');
colormap(turbo(256));
title(layout,sprintf(['Wind-wave band: T_p=%.3f s, ' ...
    'lambda_p=%.2f m, local direction=%.1f deg'], ...
    cfg.windWave.peakPeriodS,2*pi/state.kp, ...
    rad2deg(state.directionAxisRad)));
exportgraphics(fig,fullfile(cfg.paths.outputDir, ...
    'wind_wave_component_diagnostics.png'),'Resolution',180);
close(fig);
end

function plot_surface_evolution(grid, times, ix, iy, proposedZ, cfg)
heightLimit = max(abs(proposedZ), [], 'all');
columnCount = min(3,numel(times));
rowCount = ceil(numel(times)/columnCount);
fig = figure('Color','w','Position',[50 50 1500 760]);
layout = tiledlayout(fig,rowCount,columnCount, ...
    'TileSpacing','compact','Padding','compact');
for index = 1:numel(times)
    nexttile(layout);
    imagesc(grid.x(ix)/1000,grid.y(iy),double(proposedZ(:,:,index)));
    axis xy tight;
    clim([-heightLimit,heightLimit]);
    xlabel('Range (km)');
    ylabel('Cross-range (m)');
    title(sprintf('t = %.3f s',times(index)));
end
colormap(turbo(256));
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'Surface height (m)';
title(layout,'Continuous evolution of the Proposed wind-wave sea');
exportgraphics(fig,fullfile(cfg.paths.outputDir, ...
    'proposed_surface_evolution.png'),'Resolution',180);
close(fig);
end

function plot_surface_pair(linearSnapshot, proposedSnapshot, cfg)
strideX = max(1, ceil(size(linearSnapshot.Z,2)/500));
strideY = max(1, ceil(size(linearSnapshot.Z,1)/140));
ix = 1:strideX:size(linearSnapshot.Z,2);
iy = 1:strideY:size(linearSnapshot.Z,1);
commonLimits = [min([linearSnapshot.Z(:); proposedSnapshot.Z(:)]), ...
    max([linearSnapshot.Z(:); proposedSnapshot.Z(:)])];

fig = figure('Color','w','Position',[60 60 1500 620]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
nexttile(layout);
surf(double(linearSnapshot.X(iy,ix))/1000, ...
    double(linearSnapshot.Y(iy,ix)), double(linearSnapshot.Z(iy,ix)), ...
    'EdgeColor','none');
view(40,28); axis tight; clim(commonLimits); colorbar;
xlabel('Range (km)'); ylabel('Cross-range (m)'); zlabel('Height (m)');
title('Linear Elfouhaily sea');
nexttile(layout);
surf(double(proposedSnapshot.X(iy,ix))/1000, ...
    double(proposedSnapshot.Y(iy,ix)), double(proposedSnapshot.Z(iy,ix)), ...
    'EdgeColor','none');
view(40,28); axis tight; clim(commonLimits); colorbar;
xlabel('Range (km)'); ylabel('Cross-range (m)'); zlabel('Height (m)');
title('Proposed nonlinear wind-wave sea');
colormap(turbo(256));
title(layout, sprintf('U10 %.2f m/s, Hs %.3f m, T01 %.3f s', ...
    cfg.environment.U10, cfg.environment.Hs, cfg.environment.T01));
exportgraphics(fig, fullfile(cfg.paths.outputDir, ...
    'linear_proposed_surface.png'), 'Resolution', 180);
close(fig);
end

function [age, diagnostics] = calibrate_wave_age( ...
    K, phi, dkx, dky, directionAxisRad, cfg)
targetT01 = cfg.environment.T01;
objective = @(candidate) period_error(candidate, K, phi, dkx, dky, ...
    directionAxisRad, cfg.environment.U10, targetT01);
options = optimset('Display','off','TolX',1e-3);
age = fminbnd(objective, cfg.surface.inverseWaveAgeBounds(1), ...
    cfg.surface.inverseWaveAgeBounds(2), options);
[~, modelT01] = period_error(age, K, phi, dkx, dky, ...
    directionAxisRad, cfg.environment.U10, targetT01);
diagnostics.targetT01 = targetT01;
diagnostics.modelT01 = modelT01;
diagnostics.relativeError = (modelT01-targetT01)/targetT01;
end

function [errorValue, modelT01] = period_error(age, K, phi, dkx, dky, ...
    directionAxisRad, U10, targetT01)
[Psi, ~] = elfouhaily_spectrum(K, phi, U10, age, directionAxisRad);
omega = sqrt(9.81*K.*(1+(K/370).^2));
m0 = sum(Psi, 'all')*dkx*dky;
m1 = sum(omega.*Psi, 'all')*dkx*dky;
modelT01 = 2*pi*m0/max(m1,eps);
errorValue = ((modelT01-targetT01)/targetT01)^2;
end

function [Psi, meta] = elfouhaily_spectrum( ...
    K, phi, U10, inverseWaveAge, directionAxisRad)
g = 9.81; Cd10N = 0.00144; km = 370; cm = 0.23;
Ksafe = max(K,1e-12);
uStar = sqrt(Cd10N)*U10;
kp = (g/U10^2)*inverseWaveAge^2;
cp = sqrt(g/kp);
sigma = 0.08*(1+4*inverseWaveAge^(-3));
alphaP = 0.006*inverseWaveAge^0.55;
if uStar <= cm
    alphaM = 0.01*(1+log(uStar/cm));
else
    alphaM = 0.01*(1+3*log(uStar/cm));
end
if inverseWaveAge <= 1
    gammaPeak = 1.7;
else
    gammaPeak = 1.7+6*log(inverseWaveAge);
end
phaseSpeed = sqrt((g./Ksafe).*(1+(Ksafe/km).^2));
Lpm = exp(-1.25*(kp./Ksafe).^2);
Gamma = exp(-(sqrt(Ksafe/kp)-1).^2/(2*sigma^2));
Jp = gammaPeak.^Gamma;
Fp = Lpm.*Jp.*exp(-inverseWaveAge/sqrt(10) ...
    .*(sqrt(Ksafe/kp)-1));
Fm = Lpm.*Jp.*exp(-0.25*(Ksafe/km-1).^2);
Bl = 0.5*alphaP.*(cp./phaseSpeed).*Fp;
Bh = 0.5*alphaM.*(cm./phaseSpeed).*Fm;
omnidirectional = (Bl+Bh)./Ksafe.^3;
a0 = log(2)/4; ap = 4; am = 0.13*uStar/cm;
Delta = tanh(a0+ap*(phaseSpeed/cp).^2.5 ...
    + am*(cm./phaseSpeed).^2.5);
directional = (1+Delta.*cos(2*(phi-directionAxisRad)))/(2*pi);
Psi = omnidirectional./Ksafe.*directional;
Psi(K == 0 | ~isfinite(Psi) | Psi < 0) = 0;
meta.kp = kp;
meta.cp = cp;
meta.gammaPeak = gammaPeak;
meta.uStar = uStar;
end

function angle = wrap_to_180(angle)
angle = mod(angle+180,360)-180;
end
