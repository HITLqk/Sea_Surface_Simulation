% Example only. Replace every TBD value after inspecting the source figure.
% Do not run this file with guessed axis limits or guessed stage positions.

thisDir = fileparts(mfilename('fullpath'));

imageFile = fullfile(thisDir, 'reference', 'figures', ...
    'West_2002_Figure_TBD.png');
outputCsv = fullfile(thisDir, 'reference', 'digitized', ...
    'West_2002_Figure_TBD_CEM.csv');

meta = struct();
meta.source = 'West_2002';
meta.figure = 'Figure_TBD';
meta.curve = 'CEM_reference';
meta.xMinimum = NaN;       % Read from the published x axis.
meta.xMaximum = NaN;
meta.yMinimum = NaN;       % Read from the published y axis.
meta.yMaximum = NaN;
meta.yScale = 'dB';        % Use linear or log10 if required by the figure.
meta.preX = NaN;           % Published pre-breaking profile/stage.
meta.matureX = NaN;        % Published pre-impact mature profile/stage.
meta.geometry = '2-D plunging';
meta.referenceType = 'numerical EM';
meta.frequencyGHz = 'TBD';
meta.grazingDeg = 'TBD';
meta.originalQuantity = 'TBD';
meta.notes = 'Use the high-confidence numerical curve, not EGO/GTD fit.';

assert(all(isfinite([meta.xMinimum,meta.xMaximum,meta.yMinimum, ...
    meta.yMaximum,meta.preX,meta.matureX])), ...
    'Fill the axis limits and stage positions from the source figure first.');

digitize_literature_scattering_curve(imageFile, outputCsv, meta);

