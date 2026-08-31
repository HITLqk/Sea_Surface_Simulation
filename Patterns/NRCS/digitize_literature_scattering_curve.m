function curve = digitize_literature_scattering_curve(imageFile, outputCsv, meta)
%DIGITIZE_LITERATURE_SCATTERING_CURVE Digitize one published curve image.
%   The user calibrates x/y axes with four clicks, then clicks curve points.
%   No value is inferred from an abstract or an unavailable figure.

arguments
    imageFile (1,:) char
    outputCsv (1,:) char
    meta (1,1) struct
end

required = {'source','figure','curve','xMinimum','xMaximum', ...
    'yMinimum','yMaximum','yScale','preX','matureX'};
for i = 1:numel(required)
    assert(isfield(meta, required{i}), ...
        'Missing metadata field: %s', required{i});
end
assert(exist(imageFile, 'file') == 2, 'Figure image not found: %s', imageFile);
assert(meta.xMaximum > meta.xMinimum, 'xMaximum must exceed xMinimum.');
assert(meta.yMaximum > meta.yMinimum, 'yMaximum must exceed yMinimum.');
assert(meta.matureX ~= meta.preX, 'preX and matureX must differ.');

imageData = imread(imageFile);
figure('Color', 'w', 'Name', sprintf('%s %s', ...
    meta.source, meta.figure), 'Position', [80 80 1200 820]);
imshow(imageData, 'InitialMagnification', 'fit'); axis on;
title({'Axis calibration', ...
    'Click x-min tick, x-max tick, y-min tick, y-max tick'});

[calX, calY] = ginput(4);
assert(numel(calX) == 4, 'Axis calibration requires exactly four clicks.');
hold on;
plot(calX, calY, 'ro', 'MarkerSize', 9, 'LineWidth', 1.5);

title({'Curve digitization', ...
    'Click the selected reference curve from pre to mature; press Enter to finish'});
[pixelX, pixelY] = ginput();
assert(numel(pixelX) >= 2, 'At least two curve points are required.');
plot(pixelX, pixelY, 'c.-', 'MarkerSize', 13, 'LineWidth', 1.0);

xOriginal = map_axis(pixelX, calX(1), calX(2), ...
    meta.xMinimum, meta.xMaximum, 'linear');
yOriginal = map_axis(pixelY, calY(3), calY(4), ...
    meta.yMinimum, meta.yMaximum, meta.yScale);

[xOriginal, order] = sort(xOriginal);
yOriginal = yOriginal(order);
pixelX = pixelX(order);
pixelY = pixelY(order);

switch lower(char(meta.yScale))
    case 'db'
        scattering_dB = yOriginal;
    case {'linear','log10'}
        assert(all(yOriginal > 0), ...
            'Linear/log scattering values must be positive.');
        scattering_dB = 10*log10(yOriginal);
    otherwise
        error('yScale must be db, linear, or log10.');
end

preScattering_dB = interp1(xOriginal, scattering_dB, meta.preX, ...
    'linear', 'extrap');
chi = (xOriginal-meta.preX)/(meta.matureX-meta.preX);
gb_dB = scattering_dB-preScattering_dB;

n = numel(xOriginal);
curve = table(repmat(string(meta.source),n,1), ...
    repmat(string(meta.figure),n,1), repmat(string(meta.curve),n,1), ...
    xOriginal(:), yOriginal(:), scattering_dB(:), chi(:), gb_dB(:), ...
    pixelX(:), pixelY(:), ...
    'VariableNames', {'Source','Figure','Curve','XOriginal', ...
    'YOriginal','Scattering_dB','Chi','Gb_dB','PixelX','PixelY'});

optional = {'geometry','referenceType','frequencyGHz','grazingDeg', ...
    'originalQuantity','notes'};
for i = 1:numel(optional)
    name = optional{i};
    if isfield(meta, name)
        value = meta.(name);
    else
        value = missing;
    end
    curve.(name) = repmat(string(value), n, 1);
end

outputDir = fileparts(outputCsv);
if ~isempty(outputDir) && ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
writetable(curve, outputCsv);

metaFile = replace(outputCsv, '.csv', '_metadata.mat');
calibration = struct('calibrationPixelX',calX, ...
    'calibrationPixelY',calY,'imageFile',imageFile);
save(metaFile, 'meta', 'calibration');

fprintf('Digitized %d points from %s %s.\n', n, meta.source, meta.figure);
fprintf('  pre scattering : %.3f dB\n', preScattering_dB);
fprintf('  mature Gb      : %.3f dB\n', ...
    interp1(chi, gb_dB, 1, 'linear', 'extrap'));
fprintf('  output          : %s\n', outputCsv);
end

function values = map_axis(pixel, pixelMinimum, pixelMaximum, ...
        dataMinimum, dataMaximum, scale)
fraction = (pixel-pixelMinimum)/(pixelMaximum-pixelMinimum);
switch lower(char(scale))
    case {'linear','db'}
        values = dataMinimum + fraction*(dataMaximum-dataMinimum);
    case 'log10'
        assert(dataMinimum > 0 && dataMaximum > 0, ...
            'Log-axis limits must be positive.');
        values = 10.^(log10(dataMinimum) + ...
            fraction*(log10(dataMaximum)-log10(dataMinimum)));
    otherwise
        error('Unsupported axis scale: %s', scale);
end
end
