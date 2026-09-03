function cfg = default_elfouhaily_ideal_curl_config()
%DEFAULT_ELFOUHAILY_IDEAL_CURL_CONFIG Configuration for a local 2-D curl.

cfg.randomSeed = 20260825;

cfg.domain.Lx = 32.0;
cfg.domain.Ly = 32.0;
cfg.domain.dx = 0.05;
cfg.domain.dy = 0.05;

cfg.sea.U10 = 5.0;
cfg.sea.inverseWaveAge = 0.84;
cfg.sea.windDirectionDeg = 0.0;
cfg.sea.targetHs = 0.35;

% A static surface supplies a geometric breaking-eligible crest, not a
% universal hydrodynamic breaking-onset prediction.
cfg.detection.propagationDirectionDeg = 0.0;
cfg.detection.smoothingLength = 0.25;
cfg.detection.heightQuantile = 0.88;
cfg.detection.slopeToleranceFactor = 0.32;
cfg.detection.curvatureQuantile = 0.70;
cfg.detection.forwardSlopeDistance = 0.80;
cfg.detection.edgeMargin = 4.0;
cfg.detection.refineRadius = 0.30;
cfg.detection.heightWeight = 0.50;
cfg.detection.curvatureWeight = 0.35;
cfg.detection.forwardSlopeWeight = 0.15;

% The material patch follows the detected crest ridge. Lengths are small
% relative to the 32 m sea and to the old 0.915 m pivot depth.
cfg.curl.crestHalfLength = 2.20;
cfg.curl.ridgeSearchHalfWidth = 0.55;
cfg.curl.ridgeSmoothSamples = 9;
cfg.curl.coreHalfWidth = 0.42;
cfg.curl.transitionWidth = 0.58;
cfg.curl.shoulderOffset = -0.14;
cfg.curl.forwardPivotOffset = 0.03;
cfg.curl.pivotAdvanceFraction = 0.85;
cfg.curl.rotationWidth = 0.16;
cfg.curl.thetaMax = 0.25;

% The pivot depth is scaled by the selected local wave height and clipped.
cfg.curl.pivotDepthFraction = 0.65;
cfg.curl.minimumPivotDepth = 0.07;
cfg.curl.maximumPivotDepth = 0.10;
cfg.curl.localHeightRadius = 1.25;

% Low-amplitude pre-shaping changes the neighboring noncurling surface too.
cfg.curl.crestLiftFraction = 0.08;
cfg.curl.evolutionLiftFraction = 0.025;
cfg.curl.forwardLeanFraction = 0.16;
cfg.curl.lipAdvanceFraction = 2.00;
cfg.curl.lipAdvanceWidth = 0.14;
cfg.curl.lipDropFraction = 0.18;
cfg.curl.lipDropOffset = 0.12;
cfg.curl.lipDropWidth = 0.14;
cfg.curl.rearSigmaFraction = 0.72;
cfg.curl.frontSigmaFraction = 0.42;
cfg.curl.evolutionSigmaFraction = 1.20;
cfg.curl.coreMaskThreshold = 0.08;

cfg.output.figureVisible = 'on';
cfg.output.outputDirectory = fullfile(fileparts(mfilename('fullpath')), ...
    'output');
end
