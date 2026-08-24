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
cfg.patch.propagationDirectionDeg = 25.0;
cfg.patch.crestLength = 3.2;
cfg.patch.crossWaveWidth = 1.25;
cfg.patch.crestHeight = 0.42;
cfg.patch.maxCurlDeg = 62.0;
cfg.patch.pivotDepth = 0.24;
cfg.patch.forwardLean = 0.10;
cfg.patch.maskThreshold = 0.12;

% A small deterministic modulation avoids an unrealistically perfect oval
% while preserving reproducibility and a single connected breaking patch.
cfg.patch.edgeIrregularity = 0.12;
cfg.patch.centerlineMeander = 0.08;

cfg.output.saveMat = true;
cfg.output.saveFigure = true;
cfg.output.figureVisible = 'on';
cfg.output.outputDirectory = fullfile(fileparts(mfilename('fullpath')), 'output');
end

