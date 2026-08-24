function cfg = default_localized_curl_config()
%DEFAULT_LOCALIZED_CURL_CONFIG Default settings for one localized breaker patch.

cfg.randomSeed = 20260813;

% Computational domain. End points are not repeated, which is convenient
% for the periodic FFT sea realization.
cfg.domain.Lx = 12.0;
cfg.domain.Ly = 12.0;
cfg.domain.dx = 0.04;
cfg.domain.dy = 0.04;

% Elfouhaily background sea.
cfg.sea.U10 = 8.321;
cfg.sea.inverseWaveAge = 1.20;
cfg.sea.windDirectionDeg = 0.0;
cfg.sea.targetHs = 0.36;

% Local coordinates: u is the propagation direction and v is the crest
% direction. The compact windows make the deformation exactly zero outside
% the finite patch.
cfg.patch.centerXY = [6.0, 6.0];
% By default, place the breaker on the highest resolved background crest
% that leaves enough room for the complete compact patch. Set centerMode to
% 'manual' to use centerXY directly.
cfg.patch.centerMode = 'highest_crest';
cfg.patch.crestSearchSmoothingLength = 0.20;
cfg.patch.crestRefineRadius = 0.25;
cfg.patch.edgeClearance = 0.15;
cfg.patch.propagationDirectionDeg = 25.0;
cfg.patch.crestLength = 3.2;
cfg.patch.crossWaveWidth = 1.80;
cfg.patch.transitionLength = 1.20;
cfg.patch.crestHeight = 0.055;
cfg.patch.evolutionHeight = 0.035;
cfg.patch.evolutionLean = 0.045;
% Negative u is the approaching shoulder before the detected crest.
cfg.patch.curlCenterOffset = -0.22;
cfg.patch.maxCurlDeg = 18.0;
cfg.patch.pivotDepth = 0.05;
cfg.patch.forwardLean = 0.020;
cfg.patch.maskThreshold = 0.08;

% A small deterministic modulation avoids an unrealistically perfect oval
% while preserving reproducibility and a single connected breaking patch.
cfg.patch.edgeIrregularity = 0.06;
cfg.patch.centerlineMeander = 0.04;

cfg.output.saveMat = true;
cfg.output.saveFigure = true;
cfg.output.figureVisible = 'on';
cfg.output.outputDirectory = fullfile(fileparts(mfilename('fullpath')), 'output');
end

