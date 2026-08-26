function [curves,figureHandle] = run_cox_munk_validation(options)
%RUN_COX_MUNK_VALIDATION Reproduce the original spectrum-integral MSS plot.
%   This function intentionally follows source/matlab/cox_munk.m. Both
%   simulation-labelled curves integrate the same Elfouhaily spectrum; only
%   their high-wavenumber cutoffs differ. No random surface or Lie transform
%   is generated in this reproduction.

arguments
    options.FigureVisible (1,:) char = 'on'
    options.OutputDirectory (1,:) char = fullfile( ...
        fileparts(mfilename('fullpath')),'output_original_reproduction')
    options.SourceDirectory (1,:) char = ''
end

thisDirectory = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(thisDirectory));
sourceDirectory = options.SourceDirectory;
if isempty(sourceDirectory)
    sourceDirectory = thisDirectory;
end
addpath(sourceDirectory);
assert(exist('Elfouhaily','file') == 2, ...
    'Elfouhaily.m is not available in the selected source directory.');

age = 0.84;
windSpeed = (1:20)';

% Exact numerical bandwidths from the original cox_munk.m.
proposedDomainLength = 100;
proposedSampleCount = 1000*proposedDomainLength;
proposedLowerK = 2*pi/proposedDomainLength;
proposedUpperK = (proposedSampleCount/2+1)*proposedLowerK;

standardDomainLength = 50;
standardSampleCount = 100*standardDomainLength;
standardLowerK = 2*pi/standardDomainLength;
standardUpperK = (standardSampleCount/2+1)*standardLowerK;

proposedMss = zeros(size(windSpeed));
standardLieMss = zeros(size(windSpeed));
for index = 1:numel(windSpeed)
    integrand = @(k) k.^2.*Elfouhaily(k,windSpeed(index),age);
    proposedMss(index) = integral(integrand,proposedLowerK,proposedUpperK);
    standardLieMss(index) = integral(integrand,standardLowerK,standardUpperK);
end

% The archived figure was generated through the now-missing U10_U12.m.
% Its curve is reproduced by the legacy relation U12 = 1.6*U10^0.8.
legacyCoxMunkWind = U10_U12(windSpeed);
coxMunkCenter = 0.003+5.12e-3*legacyCoxMunkWind;
coxMunkUpper = coxMunkCenter+0.0055;
coxMunkLower = coxMunkCenter-0.0055;

curves = table(windSpeed,legacyCoxMunkWind,proposedMss,standardLieMss, ...
    coxMunkUpper,coxMunkLower,coxMunkCenter);
curves.Properties.VariableNames = {'U10','LegacyCoxMunkWind', ...
    'ProposedMethod', ...
    'StandardLieLabel','CoxMunkUpper','CoxMunkLower','CoxMunkCenter'};

if ~exist(options.OutputDirectory,'dir')
    mkdir(options.OutputDirectory);
end
writetable(curves,fullfile(options.OutputDirectory, ...
    'cox_munk_original_reproduction.csv'));

figureHandle = figure('Visible',options.FigureVisible,'Color','w', ...
    'Position',[80 80 675 480]);
axesHandle = axes(figureHandle);
hold(axesHandle,'on');
plot(axesHandle,windSpeed,proposedMss,'-','Color',[1 0 0], ...
    'LineWidth',2.2,'DisplayName','所提方法');
plot(axesHandle,windSpeed,standardLieMss,'-','Color',[0 0 1], ...
    'LineWidth',2.2,'DisplayName','标准 Lie 变换海面');
plot(axesHandle,windSpeed,coxMunkUpper,'--','Color',[0.929 0.694 0.125], ...
    'LineWidth',2.0,'DisplayName','Cox-Munk 上界');
plot(axesHandle,windSpeed,coxMunkLower,'--','Color',[0.494 0.184 0.556], ...
    'LineWidth',2.0,'DisplayName','Cox-Munk 下界');

xlim(axesHandle,[0 20]);
ylim(axesHandle,[0 0.10]);
xticks(axesHandle,0:5:20);
yticks(axesHandle,0:0.02:0.10);
grid(axesHandle,'on');
box(axesHandle,'on');
xlabel(axesHandle,'Wind Speed(m/s)','FontName','Times New Roman', ...
    'FontSize',15);
ylabel(axesHandle,'Mean Square Slopes','FontName','Times New Roman', ...
    'FontSize',15);
set(axesHandle,'FontName','Times New Roman','FontSize',13, ...
    'LineWidth',0.8,'Layer','top');
legendHandle = legend(axesHandle,'Location','northwest');
set(legendHandle,'FontName','Microsoft YaHei','FontSize',12, ...
    'Box','on');

exportgraphics(figureHandle,fullfile(options.OutputDirectory, ...
    'cox_munk_original_reproduction.png'),'Resolution',220);
save(fullfile(options.OutputDirectory,'cox_munk_original_reproduction.mat'), ...
    'curves','age','proposedLowerK','proposedUpperK', ...
    'standardLowerK','standardUpperK');
end
