clear; close all; clc;

cfg = default_breaker_morphology_validation_config();
assert(isfolder(cfg.curlDirectory), ...
    'Curl directory not found: %s',cfg.curlDirectory);
addpath(cfg.curlDirectory);
cleanupPath = onCleanup(@() rmpath(cfg.curlDirectory)); %#ok<NASGU>

rng(cfg.monteCarlo.randomSeed,'twister');
groupNames = ["Original","Corrected"];
rangeSets = {cfg.monteCarlo.original,cfg.monteCarlo.corrected};
nPerGroup = cfg.monteCarlo.nPerGroup;
nRows = numel(groupNames)*nPerGroup;

group = strings(nRows,1);
iteration = zeros(nRows,1);
randomSeed = zeros(nRows,1);
amplitudeCurl = zeros(nRows,1);
curlMultiplier = zeros(nRows,1);
pivotDepth = zeros(nRows,1);
forwardGain = zeros(nRows,1);
verticalAngleRatio = zeros(nRows,1);
frontFaceAngleDeg = nan(nRows,1);
rxOverLambda = nan(nRows,1);
ryOverLambda = nan(nRows,1);
valid = false(nRows,1);
pass = false(nRows,1);
errorMessage = strings(nRows,1);

row = 0;
for g = 1:numel(groupNames)
    ranges = rangeSets{g};
    for k = 1:nPerGroup
        row = row+1;
        group(row) = groupNames(g);
        iteration(row) = k;
        randomSeed(row) = randi([1 2^31-1]);
        amplitudeCurl(row) = draw_uniform(ranges.amplitudeCurl);
        curlMultiplier(row) = draw_uniform(ranges.curlMultiplier);
        pivotDepth(row) = draw_uniform(ranges.pivotDepth);
        forwardGain(row) = draw_uniform(ranges.forwardGain);
        verticalAngleRatio(row) = draw_uniform(ranges.verticalAngleRatio);

        curlCfg = default_elfouhaily_ideal_curl_config();
        curlCfg.randomSeed = randomSeed(row);
        curlCfg.curl.amplitudeCurl = amplitudeCurl(row);
        curlCfg.curl.curlMultiplier = curlMultiplier(row);
        curlCfg.curl.pivotDepth = pivotDepth(row);
        curlCfg.curl.forwardGain = forwardGain(row);
        curlCfg.curl.verticalAngleRatio = verticalAngleRatio(row);

        try
            surfaceData = generate_elfouhaily_ideal_curl_surface(curlCfg);
            metrics = extract_breaker_morphology_metrics(surfaceData,cfg);
            frontFaceAngleDeg(row) = metrics.frontFaceAngleDeg;
            rxOverLambda(row) = metrics.rxOverLambda;
            ryOverLambda(row) = metrics.ryOverLambda;
            valid(row) = true;
            pass(row) = metrics.allPass;
        catch ME
            errorMessage(row) = string(ME.message);
        end

        if mod(k,10) == 0
            fprintf('%s: %d/%d complete\n',groupNames(g),k,nPerGroup);
        end
    end
end

raw = table(group,iteration,randomSeed,amplitudeCurl,curlMultiplier, ...
    pivotDepth,forwardGain,verticalAngleRatio,frontFaceAngleDeg, ...
    rxOverLambda,ryOverLambda,valid,pass,errorMessage);

summary = build_summary(raw,groupNames);
disp(summary);

if ~isfolder(cfg.outputDirectory)
    mkdir(cfg.outputDirectory);
end
writetable(raw,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_monte_carlo_raw.csv'));
writetable(summary,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_monte_carlo_summary.csv'));
save(fullfile(cfg.outputDirectory, ...
    'breaker_morphology_monte_carlo.mat'),'cfg','raw','summary');

fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[80 80 1120 470]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');

nexttile(layout,1);
plot_joint_distribution(raw,summary,cfg.reference.rxOverLambda, ...
    'r_x / \lambda_p');
title('(a) Horizontal curl scale');

nexttile(layout,2);
plot_joint_distribution(raw,summary,cfg.reference.ryOverLambda, ...
    'r_y / \lambda_p');
title('(b) Vertical curl scale');

set(findall(fig,'Type','axes'),'FontName','Times New Roman', ...
    'FontSize',11,'LineWidth',0.8,'Layer','top');
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_monte_carlo.png'),'Resolution',240);
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_monte_carlo.pdf'),'ContentType','vector');

function value = draw_uniform(bounds)
value = bounds(1)+(bounds(2)-bounds(1))*rand();
end

function summary = build_summary(raw,groupNames)
n = numel(groupNames);
group = groupNames(:);
requestedCount = zeros(n,1);
validCount = zeros(n,1);
passCount = zeros(n,1);
passRate = zeros(n,1);
angleMean = nan(n,1);
angleCi95 = nan(n,1);
rxMean = nan(n,1);
rxCi95 = nan(n,1);
ryMean = nan(n,1);
ryCi95 = nan(n,1);
for k = 1:n
    selected = raw.group == group(k);
    accepted = selected & raw.valid;
    requestedCount(k) = nnz(selected);
    validCount(k) = nnz(accepted);
    passCount(k) = nnz(accepted & raw.pass);
    passRate(k) = passCount(k)/max(validCount(k),1);
    [angleMean(k),angleCi95(k)] = mean_ci(raw.frontFaceAngleDeg(accepted));
    [rxMean(k),rxCi95(k)] = mean_ci(raw.rxOverLambda(accepted));
    [ryMean(k),ryCi95(k)] = mean_ci(raw.ryOverLambda(accepted));
end
summary = table(group,requestedCount,validCount,passCount,passRate, ...
    angleMean,angleCi95,rxMean,rxCi95,ryMean,ryCi95);
end

function [average,halfWidth] = mean_ci(values)
values = values(isfinite(values));
average = mean(values);
halfWidth = 1.96*std(values)/sqrt(max(numel(values),1));
end

function plot_joint_distribution(raw,summary,scaleBounds,yLabelText)
hold on;
angleBounds = [65 70];
patch(angleBounds([1 2 2 1]),scaleBounds([1 1 2 2]), ...
    [0.82 0.88 0.96],'EdgeColor','none','FaceAlpha',0.75, ...
    'DisplayName','Erinin envelope');
colors = [0.55 0.55 0.55; 0.05 0.35 0.75];
markers = {'x','o'};
for k = 1:height(summary)
    selected = raw.group == summary.group(k) & raw.valid;
    if contains(yLabelText,'r_x')
        scale = raw.rxOverLambda(selected);
    else
        scale = raw.ryOverLambda(selected);
    end
    label = sprintf('%s (pass %.1f%%)',summary.group(k), ...
        100*summary.passRate(k));
    scatter(raw.frontFaceAngleDeg(selected),scale,28,colors(k,:), ...
        markers{k},'LineWidth',1.0,'DisplayName',label);
end
xlabel('Front-face angle (deg)'); ylabel(yLabelText);
grid on; legend('Location','best');
end
