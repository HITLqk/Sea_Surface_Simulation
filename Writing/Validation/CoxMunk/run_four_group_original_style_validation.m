function [rawResults,summaryResults,assessment,figureHandle] = ...
    run_four_group_original_style_validation(cfg)
%RUN_FOUR_GROUP_ORIGINAL_STYLE_VALIDATION Validate four sampled surfaces.
%   The wind range, wave age, Cox-Munk bounds, and single-panel styling
%   follow the original cox_munk.m. Every method curve is calculated from
%   an actual sampled (X,Y,Z) surface using paired random phases.

arguments
    cfg (1,1) struct = default_cox_munk_validation_config()
end

if isequal(cfg.windSpeeds,[3 5 7 10])
    cfg.windSpeeds = 1:10;
end
if isequal(cfg.randomSeeds,20260801:20260820)
    cfg.randomSeeds = 20260825:20260827;
end
defaultOutput = fullfile(fileparts(mfilename('fullpath')),'output');
if strcmp(cfg.output.directory,defaultOutput)
    cfg.output.directory = fullfile(fileparts(mfilename('fullpath')), ...
        'output_four_group_original_style');
end

diagnosticVisibility = cfg.output.figureVisible;
cfg.output.figureVisible = 'off';
[rawResults,summaryResults,coxMunk] = run_surface_mss_diagnostic(cfg);
cfg.output.figureVisible = diagnosticVisibility;

assessment = assess_groups(summaryResults,coxMunk);
writetable(assessment,fullfile(cfg.output.directory, ...
    'cox_munk_four_group_assessment.csv'));

figureHandle = plot_original_style(summaryResults,coxMunk,cfg);
exportgraphics(figureHandle,fullfile(cfg.output.directory, ...
    'cox_munk_four_group_validation.png'),'Resolution',220);
save(fullfile(cfg.output.directory,'cox_munk_four_group_validation.mat'), ...
    'rawResults','summaryResults','coxMunk','assessment','cfg','-v7.3');

fprintf('\nFour-group Cox-Munk assessment:\n');
disp(assessment);
end

function assessment = assess_groups(summary,reference)
groups = ["Linear","G0_Nonlinear","G1_Upward","G1_Background"];
nGroups = numel(groups);
Group = groups(:);
BandCoverage = zeros(nGroups,1);
RMSE = zeros(nGroups,1);
MeanAbsoluteRelativeError = zeros(nGroups,1);
TrendCorrelation = zeros(nGroups,1);

for groupIndex = 1:nGroups
    selected = summary.Group == groups(groupIndex);
    [wind,order] = sort(summary.U10(selected));
    mss = summary.MssTotalMean(selected);
    mss = mss(order);
    [~,referenceOrder] = sort(reference.U10);
    center = reference.MssTotal(referenceOrder);
    lower = reference.MssTotalLower(referenceOrder);
    upper = reference.MssTotalUpper(referenceOrder);
    assert(isequal(wind,sort(reference.U10)), ...
        'Summary and Cox-Munk wind grids do not match.');
    BandCoverage(groupIndex) = mean(mss >= lower & mss <= upper);
    RMSE(groupIndex) = sqrt(mean((mss-center).^2));
    MeanAbsoluteRelativeError(groupIndex) = mean(abs(mss-center)./center);
    correlation = corrcoef(wind,mss);
    TrendCorrelation(groupIndex) = correlation(1,2);
end

assessment = table(Group,BandCoverage,RMSE, ...
    MeanAbsoluteRelativeError,TrendCorrelation);
end

function fig = plot_original_style(summary,reference,cfg)
fig = figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[50 50 675 480]);
ax = axes(fig);
hold(ax,'on');

plot_group(ax,summary,"G0_Nonlinear",[1 0 0],'G0 Nonlinear','o',1);
plot_group(ax,summary,"Linear",[0 0 1],'Linear','none',1);
plot_group(ax,summary,"G1_Upward",[0.10 0.55 0.20], ...
    'G1 Upward','s',2);
plot_group(ax,summary,"G1_Background",[0.75 0.10 0.65], ...
    'G1 Background','d',3);
plot(ax,reference.U10,reference.MssTotalUpper,'--', ...
    'Color',[0.929 0.694 0.125],'LineWidth',2, ...
    'DisplayName','Cox-Munk upper bound');
plot(ax,reference.U10,reference.MssTotalLower,'--', ...
    'Color',[0.494 0.184 0.556],'LineWidth',2, ...
    'DisplayName','Cox-Munk lower bound');

xMaximum = max(reference.U10);
xlim(ax,[0 xMaximum]);
if xMaximum <= 10
    tickStep = 2;
else
    tickStep = 5;
end
xticks(ax,0:tickStep:xMaximum);
yMaximum = max([summary.MssTotalMean;reference.MssTotalUpper]);
ylim(ax,[0,1.05*yMaximum]);
xlabel(ax,'Wind Speed(m/s)','FontName','Times New Roman','FontSize',12);
ylabel(ax,'Mean Square Slopes','FontName','Times New Roman','FontSize',12);
grid(ax,'on');
box(ax,'on');
legend(ax,'Location','northwest','FontName','Times New Roman', ...
    'FontSize',10);
set(ax,'FontName','Times New Roman','FontSize',12);
end

function plot_group(ax,summary,group,color,label,marker,markerOffset)
selected = summary.Group == group;
[wind,order] = sort(summary.U10(selected));
mss = summary.MssTotalMean(selected);
lineHandle = plot(ax,wind,mss(order),'Color',color,'LineWidth',2, ...
    'Marker',marker,'MarkerSize',5,'MarkerFaceColor','w', ...
    'DisplayName',label);
if ~strcmp(marker,'none')
    lineHandle.MarkerIndices = markerOffset:4:numel(wind);
end
end
