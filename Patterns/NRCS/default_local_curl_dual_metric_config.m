function cfg = default_local_curl_dual_metric_config()
%DEFAULT_LOCAL_CURL_DUAL_METRIC_CONFIG Paired local curl validation setup.

thisDir = fileparts(mfilename('fullpath'));

cfg.sampleCount = 60;
cfg.randomSeed = 20260831;
cfg.maximumAttempts = 180;

% G1 uses a continuous morphology control. There are no weak, moderate,
% and strong validation groups. G0 is always the paired non-curl surface.
% Start after the current generator's geometric overturning onset
% (approximately chi = 0.51). The experiment remains continuously sampled.
cfg.chi.minimum = 0.55;
cfg.chi.maximum = 1.00;
cfg.chi.maximumCurlMultiplier = 1.35;
cfg.chi.binCount = 8;

% Fixed material window centred on the detected crest. Face membership is
% determined on G0 and reused for G1.
cfg.window.propagationLength = 1.2;
cfg.window.crestwiseLength = 4.4;

% The current project echo code uses sigma_i = A_i*cos(theta_i)^2. This is
% retained as a fixed single-channel RCS proxy; no polarization comparison
% is performed. Frequency is metadata for later replacement of the kernel.
cfg.radar.frequencyGHz = 10.0;
cfg.radar.grazingAngleDeg = 12.0;
cfg.radar.lookAzimuthOffsetDeg = 0.0;
cfg.scattering.model = 'facet_plus_nonbragg_breaker_proxy';

% Semi-empirical fixed-channel breaker contribution:
% sigma_nb/sigma_pre = C_nb*chi*(1+w_J*max(0,-J_min)).
% C_nb is calibrated once to the 6.10 dB literature median. It must not be
% presented as an independently validated parameter.
cfg.scattering.nonBraggPowerCoefficient = 2.50;
cfg.scattering.jacobianSeverityWeight = 1.00;

cfg.generator.domainLx = 32.0;
cfg.generator.domainLy = 32.0;
cfg.generator.dx = 0.05;
cfg.generator.dy = 0.05;
cfg.generator.U10 = 5.0;
cfg.generator.targetHs = 0.35;
cfg.generator.heightSigmaThreshold = 1.25;

cfg.output.figureVisible = 'on';
cfg.output.directory = fullfile(thisDir, 'output');
cfg.output.referenceCsv = fullfile(thisDir, 'reference', ...
    'literature_gb_reference.csv');
cfg.output.savePdf = true;
end
