function cfg = wind_wave_simulation_config()
%WIND_WAVE_SIMULATION_CONFIG Wind-wave verification settings.
% Paths are relative to this file so the folder can be copied to a server.

thisDir = fileparts(mfilename('fullpath'));
radarEchoDir = fileparts(thisDir);

cfg.paths.simulationDir = thisDir;
cfg.paths.dataDir = fullfile(radarEchoDir, 'data');
cfg.paths.outputDir = fullfile(thisDir, 'simulation_output');
cfg.paths.measuredFile = fullfile(cfg.paths.dataDir, ...
    '20210106155330_01_staring.mat');
cfg.paths.measuredEchoVariable = 'amplitude_complex_T2';

cfg.randomSeed = 20260831;

% Environmental values interpolated at the radar location and acquisition
% time from the supplied wind/wave NetCDF files.
cfg.environment.U10 = 8.32;
cfg.environment.Hs = 0.839;
cfg.environment.T01 = 3.327;
cfg.environment.windFromDeg = 342.4;
cfg.environment.waveFromDeg = 353.0;
cfg.environment.seaState = 3;
cfg.environment.gravity = 9.81;

% The measured MAT header is read at runtime and overrides PRF, sample
% spacing, pulse count, first range and mean staring bearing.
cfg.radar.fcHz = 9.4e9;
cfg.radar.c = 299792458;
cfg.radar.heightM = 80;
cfg.radar.peakPowerW = 50;
cfg.radar.bandwidthHz = 25e6;
cfg.radar.azimuthHpbwDeg = 1.2;
cfg.radar.elevationHpbwDeg = 22;
cfg.radar.polarization = 'HH';

% The first run uses a clutter-dominated range interval instead of the
% complete 11 km record. Change these limits after inspecting measured RTI.
cfg.scene.requestedRangeLimitsM = [1000, 5000];
cfg.scene.crossRangeWidthM = 256;
cfg.scene.rangeMarginM = 80;

% Large gravity-wave mesh. X-band Bragg waves are unresolved and represented
% by the TSC scattering model, so a centimetre-scale geometry mesh is not
% required here.
cfg.surface.dx = 2.0;
cfg.surface.dy = 2.0;
cfg.surface.snapshotCount = 129;
cfg.surface.inverseWaveAgeBounds = [0.84, 5.0];
cfg.surface.rescaleRealizationToHs = true;
cfg.surface.evolutionFrameCount = 5;

% Narrow directional wind-wave band adapted from the Swell_Wave cos^(2s)
% spreading code. The measured period and direction are used, while total
% Hs is conserved by variance partition rather than adding extra energy.
cfg.windWave.enabled = true;
cfg.windWave.energyFraction = 0.35;
cfg.windWave.peakPeriodS = cfg.environment.T01;
cfg.windWave.relativeWavenumberBandwidth = 0.16;
cfg.windWave.directionalSpreadingExponent = 18;
cfg.windWave.seedOffset = 310;

% Proposed combines the organized wind-wave band with the same broadband
% realization before applying the nonlinear Lie/Creamer-type correction.
cfg.nonlinear.baseGain = 1.0;
cfg.nonlinear.referenceWindSpeed = 10.0;
cfg.nonlinear.windExponent = -0.25;
cfg.nonlinear.minimumWindGain = 0.70;
cfg.nonlinear.maximumWindGain = 1.20;
cfg.nonlinear.directionStrength = 0.35;
cfg.nonlinear.directionExponent = 2.0;
cfg.nonlinear.cutoffFraction = 0.65;
cfg.nonlinear.filterOrder = 8;
cfg.nonlinear.horizontalDisplacement = 0.75;
cfg.nonlinear.minimumJacobian = 0.20;
cfg.nonlinear.backoffFactor = 0.85;
cfg.nonlinear.maximumBackoffSteps = 30;

% TSC produces conditional mean facet power. The Linear baseline retains the
% measured two-scale Gaussian speckle calibration. Proposed additionally uses
% a sea-state-driven, correlated Gamma texture: this is a compound-Gaussian
% wind-wave modulation model, not a breaker/curl contribution. Its mean is
% fixed to one, so it changes intermittency and persistence rather than the
% average echo energy.
cfg.echo.numPulses = 4096;
% Two temporal scales estimated from the measured intensity ACF in the
% predeclared 2.5-3.0 km sea-clutter gate. These are calibration parameters,
% not independent validation evidence.
cfg.echo.fastSpeckleCorrelationTimeS = 0.0051;
cfg.echo.slowSpeckleCorrelationTimeS = 1.40;
cfg.echo.linearSlowSpecklePowerFraction = 0.41;
cfg.echo.proposedSlowSpecklePowerFraction = 0.90;
% Integer Gamma shape nu = dof/2. The resolution-cell response and residual
% geometric modulation soften this nominal nu=1 texture; the resulting echo
% is expected to approach the measured K-shape (about 1.6) without changing
% mean power or injecting isolated point targets.
cfg.echo.windWaveTextureEnabled = true;
cfg.echo.windWaveTextureDegreesOfFreedom = 2;
cfg.echo.windWaveTextureCorrelationTimeS = 1.80;
cfg.echo.windWaveTextureRangeCorrelationM = 90;
cfg.echo.windWaveTextureSeedOffset = 920;
cfg.echo.noiseRelativeDb = -45;
% Effective range-response bandwidth inferred from measured range ACF.
% It is deliberately separate from the nominal transmitted bandwidth.
cfg.echo.effectiveRangeCorrelationBandwidthHz = 10e6;
cfg.echo.pulseCompressionHalfWidth = 24;
cfg.echo.useHorizonShadowing = true;
cfg.echo.shadowToleranceDeg = 0.01;
cfg.echo.minimumAntennaPowerGain = 1e-7;
cfg.echo.minimumGrazingDeg = 0.05;

cfg.output.saveSpectralState = true;
cfg.output.saveSurfaceSnapshots = true;
cfg.output.makeSurfaceFigure = true;
cfg.output.generateRadarEcho = true;
end
