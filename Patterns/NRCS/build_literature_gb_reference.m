function reference = build_literature_gb_reference(digitizedDirectory, outputCsv)
%BUILD_LITERATURE_GB_REFERENCE Combine audited digitized literature curves.

if nargin < 1 || isempty(digitizedDirectory)
    thisDir = fileparts(mfilename('fullpath'));
    digitizedDirectory = fullfile(thisDir, 'reference', 'digitized');
end
if nargin < 2 || isempty(outputCsv)
    outputCsv = fullfile(fileparts(digitizedDirectory), ...
        'literature_gb_reference.csv');
end

files = dir(fullfile(digitizedDirectory, '*.csv'));
assert(~isempty(files), ...
    'No digitized curve CSV files found in %s.', digitizedDirectory);

reference = table();
for i = 1:numel(files)
    file = fullfile(files(i).folder, files(i).name);
    curve = readtable(file, 'TextType', 'string', 'Delimiter', ',');
    required = {'Source','Figure','Curve','Chi','Gb_dB'};
    assert(all(ismember(required, curve.Properties.VariableNames)), ...
        'Digitized file lacks required columns: %s', file);
    valid = isfinite(curve.Chi) & isfinite(curve.Gb_dB) ...
        & curve.Chi >= 0 & curve.Chi <= 1;
    curve = curve(valid,:);
    if isempty(reference)
        reference = curve;
    else
        reference = [reference; curve]; %#ok<AGROW>
    end
end

assert(~isempty(reference), ...
    'No finite pre-to-mature reference points were found.');
writetable(reference, outputCsv);
fprintf('Combined %d reference points from %d digitized curves.\n', ...
    height(reference), numel(files));
fprintf('  output: %s\n', outputCsv);
end
