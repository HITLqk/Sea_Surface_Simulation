function cfg = default_elfouhaily_ideal_curl_config()
%DEFAULT_ELFOUHAILY_IDEAL_CURL_CONFIG Configuration for a 2-D curled sea.

cfg.randomSeed = 20260825;

cfg.domain.Lx = 32.0;
cfg.domain.Ly = 32.0;
cfg.domain.dx = 0.05;
cfg.domain.dy = 0.05;

cfg.sea.U10 = 5.0;
cfg.sea.inverseWaveAge = 0.84;
cfg.sea.windDirectionDeg = 0.0;
cfg.sea.targetHs = 0.35;

% The curl location is selected from the 2-D sea by elevation.
cfg.detection.heightSigmaThreshold = 1.25;
cfg.detection.smoothingLength = 0.20;
cfg.detection.refineRadius = 0.25;
cfg.detection.edgeMargin = 4.0;

% Ideal_Curl_Wave_Echo-style local rotation. The propagation coordinate u
% replaces the original script's Y coordinate. A finite crest window in v
% prevents the original cylindrical extrusion.
cfg.curl.propagationDirectionDeg = 0.0;
cfg.curl.crestLength = 6.0;
cfg.curl.amplitudeCurl = 0.20;
cfg.curl.curlMultiplier = 0.50;
cfg.curl.pivotDepth = 1.50;
cfg.curl.forwardGain = 1.0;
cfg.curl.verticalAngleRatio = 1.0;
cfg.curl.scaleU = 1.0;
cfg.curl.scaleZ = 1.0;
cfg.curl.maskAngleFraction = 0.08;

cfg.output.figureVisible = 'on';
cfg.output.outputDirectory = fullfile(fileparts(mfilename('fullpath')), ...
    'output');
end

