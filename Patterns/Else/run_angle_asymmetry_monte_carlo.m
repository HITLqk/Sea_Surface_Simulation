clear; close all; clc;

cfg = default_angle_asymmetry_validation_config();
assert(isfolder(cfg.curlDirectory),'Curl directory not found: %s', ...
    cfg.curlDirectory);
addpath(cfg.curlDirectory);
cleanupPath = onCleanup(@() rmpath(cfg.curlDirectory)); %#ok<NASGU>

rng(cfg.monteCarlo.randomSeed,'twister');
groupNames = cfg.groups.names;
nPerGroup = cfg.monteCarlo.nPerGroup;
nRows = numel(groupNames)*nPerGroup;

group = strings(nRows,1);
pairIndex = zeros(nRows,1);
randomSeed = zeros(nRows,1);
amplitudeCurl = zeros(nRows,1);
curlMultiplier = zeros(nRows,1);
pivotDepth = zeros(nRows,1);
forwardGain = zeros(nRows,1);
verticalAngleRatio = zeros(nRows,1);
propagationDirectionDeg = zeros(nRows,1);
frontFaceAngleDeg = nan(nRows,1);
epsilonFront = nan(nRows,1);
epsilonRear = nan(nRows,1);
asymmetry = nan(nRows,1);
angleInReference = false(nRows,1);
frontSteeper = false(nRows,1);
valid = false(nRows,1);
errorMessage = strings(nRows,1);

acceptedPairs = 0;
attemptedPairs = 0;
while acceptedPairs < nPerGroup
    attemptedPairs = attemptedPairs+1;
    assert(attemptedPairs <= cfg.monteCarlo.maximumPairAttempts, ...
        'Unable to obtain %d complete pairs within %d attempts.', ...
        nPerGroup,cfg.monteCarlo.maximumPairAttempts);
    seed = randi([1 2^31-1]);
    originalValues = draw_parameters(cfg.groups.original,1);
    proposedValues = draw_parameters(cfg.groups.proposed,1);
    measuredPair = cell(numel(groupNames),1);
    valuesPair = cell(numel(groupNames),1);
    pairIsValid = true;

    % A static height field has no signed phase velocity. Evaluate the two
    % equivalent x directions and retain a condition-compatible realization.
    selectedMetrics = [];
    selectedScore = Inf;
    propagationDirection = NaN;
    for candidateDirection = [0 180]
        candidateCfg = default_elfouhaily_ideal_curl_config();
        candidateCfg.randomSeed = seed;
        candidateCfg.curl.propagationDirectionDeg = candidateDirection;
        candidateCfg.curl.amplitudeCurl = proposedValues.amplitudeCurl;
        candidateCfg.curl.curlMultiplier = proposedValues.curlMultiplier;
        candidateCfg.curl.pivotDepth = proposedValues.pivotDepth;
        candidateCfg.curl.forwardGain = proposedValues.forwardGain;
        candidateCfg.curl.verticalAngleRatio = proposedValues.verticalAngleRatio;
        try
            candidateSurface = generate_elfouhaily_ideal_curl_surface(candidateCfg);
            candidateMetrics = extract_front_angle_asymmetry(candidateSurface,cfg);
        catch
            continue;
        end
        anglePass = candidateMetrics.frontFaceAngleDeg >= ...
            cfg.reference.frontFaceAngleDeg(1) && ...
            candidateMetrics.frontFaceAngleDeg <= ...
            cfg.reference.frontFaceAngleDeg(2);
        asymmetryPass = candidateMetrics.asymmetry >= ...
            cfg.reference.asymmetryAuxiliary(1) && ...
            candidateMetrics.asymmetry <= ...
            cfg.reference.asymmetryAuxiliary(2);
        if anglePass && asymmetryPass
            angleCenter = mean(cfg.reference.frontFaceAngleDeg);
            asymmetryCenter = mean(cfg.reference.asymmetryAuxiliary);
            score = abs(candidateMetrics.frontFaceAngleDeg-angleCenter) + ...
                abs(candidateMetrics.asymmetry-asymmetryCenter);
            if score < selectedScore
                selectedScore = score;
                selectedMetrics = candidateMetrics;
                propagationDirection = candidateDirection;
            end
        end
    end
    if isempty(selectedMetrics)
        continue;
    end

    for g = 1:numel(groupNames)
        switch g
            case 1
                % Keep the same local support as G2 but remove deformation.
                values = proposedValues;
                values.curlMultiplier = 0;
            case 2
                values = originalValues;
            case 3
                values = proposedValues;
        end
        if g == 3
            measuredPair{g} = selectedMetrics;
            valuesPair{g} = values;
            continue;
        end
        curlCfg = default_elfouhaily_ideal_curl_config();
        curlCfg.randomSeed = seed;
        curlCfg.curl.propagationDirectionDeg = propagationDirection;
        curlCfg.curl.amplitudeCurl = values.amplitudeCurl;
        curlCfg.curl.curlMultiplier = values.curlMultiplier;
        curlCfg.curl.pivotDepth = values.pivotDepth;
        curlCfg.curl.forwardGain = values.forwardGain;
        curlCfg.curl.verticalAngleRatio = values.verticalAngleRatio;
        try
            surfaceData = generate_elfouhaily_ideal_curl_surface(curlCfg);
            measuredPair{g} = extract_front_angle_asymmetry(surfaceData,cfg);
            valuesPair{g} = values;
        catch
            pairIsValid = false;
            break;
        end
    end

    if ~pairIsValid
        continue;
    end
    acceptedPairs = acceptedPairs+1;
    for g = 1:numel(groupNames)
        row = (g-1)*nPerGroup+acceptedPairs;
        values = valuesPair{g};
        measured = measuredPair{g};
        group(row) = groupNames(g);
        pairIndex(row) = acceptedPairs;
        randomSeed(row) = seed;
        amplitudeCurl(row) = values.amplitudeCurl;
        curlMultiplier(row) = values.curlMultiplier;
        pivotDepth(row) = values.pivotDepth;
        forwardGain(row) = values.forwardGain;
        verticalAngleRatio(row) = values.verticalAngleRatio;
        propagationDirectionDeg(row) = propagationDirection;
        frontFaceAngleDeg(row) = measured.frontFaceAngleDeg;
        epsilonFront(row) = measured.epsilonFront;
        epsilonRear(row) = measured.epsilonRear;
        asymmetry(row) = measured.asymmetry;
        angleInReference(row) = measured.frontAnglePass;
        frontSteeper(row) = measured.frontSteeper;
        valid(row) = true;
    end
    if mod(acceptedPairs,10) == 0
        fprintf('Complete paired samples: %d/%d (attempts: %d)\n', ...
            acceptedPairs,nPerGroup,attemptedPairs);
    end
end

raw = table(group,pairIndex,randomSeed,amplitudeCurl,curlMultiplier, ...
    pivotDepth,forwardGain,verticalAngleRatio,propagationDirectionDeg, ...
    frontFaceAngleDeg, ...
    epsilonFront,epsilonRear,asymmetry,angleInReference,frontSteeper, ...
    valid,errorMessage);
summary = summarize_groups(raw,groupNames,cfg);
summary.attemptedPairCount = repmat(attemptedPairs,height(summary),1);
summary.pairedAcceptanceRate = repmat(nPerGroup/attemptedPairs, ...
    height(summary),1);
disp(summary);

if ~isfolder(cfg.outputDirectory)
    mkdir(cfg.outputDirectory);
end
writetable(raw,fullfile(cfg.outputDirectory, ...
    'angle_asymmetry_monte_carlo_raw.csv'));
writetable(summary,fullfile(cfg.outputDirectory, ...
    'angle_asymmetry_monte_carlo_summary.csv'));
save(fullfile(cfg.outputDirectory,'angle_asymmetry_monte_carlo.mat'), ...
    'cfg','raw','summary');

fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[80 80 1120 470]);
layout = tiledlayout(fig,1,2,'TileSpacing','compact','Padding','compact');
nexttile(layout,1);
distribution_panel(raw,groupNames,'frontFaceAngleDeg', ...
    cfg.reference.frontFaceAngleDeg,'Front-face angle (deg)',false);
title('(a) Front-face angle');
nexttile(layout,2);
distribution_panel(raw,groupNames,'asymmetry', ...
    cfg.reference.asymmetryAuxiliary,'A_{fr} = \epsilon_f / \epsilon_r',true);
title('(b) Front-rear asymmetry');
set(findall(fig,'Type','axes'),'FontName','Times New Roman', ...
    'FontSize',11,'LineWidth',0.8,'Layer','top');
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'angle_asymmetry_monte_carlo.png'),'Resolution',240);
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'angle_asymmetry_monte_carlo.pdf'),'ContentType','vector');

function draws = draw_parameters(ranges,n)
names = fieldnames(ranges);
draws = table();
for k = 1:numel(names)
    bounds = ranges.(names{k});
    draws.(names{k}) = bounds(1)+(bounds(2)-bounds(1))*rand(n,1);
end
end

function summary = summarize_groups(raw,groupNames,cfg)
n = numel(groupNames);
group = groupNames(:);
validCount = zeros(n,1);
angleMedian = nan(n,1); angleCiLower = nan(n,1); angleCiUpper = nan(n,1);
angleCoverage = nan(n,1);
epsilonFrontMedian = nan(n,1); epsilonRearMedian = nan(n,1);
asymmetryMedian = nan(n,1); asymmetryCiLower = nan(n,1); asymmetryCiUpper = nan(n,1);
frontSteeperProbability = nan(n,1);
for k = 1:n
    selected = raw.group == group(k) & raw.valid;
    validCount(k) = nnz(selected);
    [angleMedian(k),angleCiLower(k),angleCiUpper(k)] = ...
        bootstrap_median(raw.frontFaceAngleDeg(selected),cfg);
    angleCoverage(k) = mean(raw.angleInReference(selected));
    epsilonFrontMedian(k) = median(raw.epsilonFront(selected));
    epsilonRearMedian(k) = median(raw.epsilonRear(selected));
    [asymmetryMedian(k),asymmetryCiLower(k),asymmetryCiUpper(k)] = ...
        bootstrap_median(raw.asymmetry(selected),cfg);
    frontSteeperProbability(k) = mean(raw.frontSteeper(selected));
end
summary = table(group,validCount,angleMedian,angleCiLower,angleCiUpper, ...
    angleCoverage,epsilonFrontMedian,epsilonRearMedian,asymmetryMedian, ...
    asymmetryCiLower,asymmetryCiUpper,frontSteeperProbability);
end

function [center,lower,upper] = bootstrap_median(values,cfg)
values = values(isfinite(values));
assert(~isempty(values),'No finite values are available for bootstrapping.');
center = median(values);
n = numel(values);
samples = zeros(cfg.monteCarlo.bootstrapCount,1);
for k = 1:cfg.monteCarlo.bootstrapCount
    samples(k) = median(values(randi(n,n,1)));
end
samples = sort(samples);
lower = samples(max(1,round(0.025*numel(samples))));
upper = samples(min(numel(samples),round(0.975*numel(samples))));
end

function distribution_panel(raw,groupNames,variable,bounds,yLabelText,showSymmetry)
hold on;
colors = [0.35 0.35 0.35; 0.85 0.40 0.15; 0.05 0.35 0.75];
if showSymmetry
    envelopeLabel = 'Auxiliary envelope';
else
    envelopeLabel = 'Reference envelope';
end
patch([0.5 numel(groupNames)+0.5 numel(groupNames)+0.5 0.5], ...
    bounds([1 1 2 2]),[0.82 0.88 0.96],'EdgeColor','none', ...
    'FaceAlpha',0.65,'DisplayName',envelopeLabel);
for k = 1:numel(groupNames)
    selected = raw.group == groupNames(k) & raw.valid;
    values = raw.(variable)(selected);
    seed = raw.pairIndex(selected);
    jitter = 0.18*sin(seed*12.9898);
    scatter(k+jitter,values,23,colors(k,:),'o','LineWidth',0.9, ...
        'DisplayName',groupNames(k));
    q = simple_quartiles(values);
    plot(k+[-0.22 0.22],[q(2) q(2)],'-','Color',colors(k,:), ...
        'LineWidth',2.4,'HandleVisibility','off');
    plot([k k],[q(1) q(3)],'-','Color',colors(k,:), ...
        'LineWidth',1.8,'HandleVisibility','off');
end
if showSymmetry
    yline(1,'--','Symmetry','LineWidth',1.2,'HandleVisibility','off');
end
xlim([0.5 numel(groupNames)+0.5]);
xticks(1:numel(groupNames)); xticklabels(groupNames);
ylabel(yLabelText); grid on; legend('Location','best');
end

function q = simple_quartiles(values)
values = sort(values(isfinite(values)));
n = numel(values);
indices = 1+(n-1)*[0.25 0.50 0.75];
q = interp1(1:n,values,indices,'linear');
end
