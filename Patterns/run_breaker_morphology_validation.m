clear; close all; clc;

cfg = default_breaker_morphology_validation_config();
assert(isfolder(cfg.curlDirectory), ...
    'Curl directory not found: %s',cfg.curlDirectory);
addpath(cfg.curlDirectory);
cleanupPath = onCleanup(@() rmpath(cfg.curlDirectory)); %#ok<NASGU>

curlCfg = default_elfouhaily_ideal_curl_config();
names = fieldnames(cfg.curlOverrides);
for k = 1:numel(names)
    curlCfg.curl.(names{k}) = cfg.curlOverrides.(names{k});
end

surfaceData = generate_elfouhaily_ideal_curl_surface(curlCfg);
assert(surfaceData.metrics.overturningPointCount > 0, ...
    'The generated surface has no geometrically overturning points.');
result = extract_breaker_morphology_metrics(surfaceData,cfg);

if ~isfolder(cfg.outputDirectory)
    mkdir(cfg.outputDirectory);
end

fprintf('Breaker morphology validation\n');
fprintf('  front-face angle : %.2f deg (reference %.1f-%.1f) [%s]\n', ...
    result.frontFaceAngleDeg,cfg.reference.frontFaceAngleDeg, ...
    pass_text(result.anglePass));
fprintf('  rx/lambda        : %.4f (reference %.3f-%.3f) [%s]\n', ...
    result.rxOverLambda,cfg.reference.rxOverLambda, ...
    pass_text(result.rxPass));
fprintf('  ry/lambda        : %.4f (reference %.3f-%.3f) [%s]\n', ...
    result.ryOverLambda,cfg.reference.ryOverLambda, ...
    pass_text(result.ryPass));
fprintf('  wavelength       : %.4f m (%s)\n',result.wavelength, ...
    cfg.normalization.mode);

metric = ["front_face_angle_deg";"rx_over_lambda";"ry_over_lambda"];
value = [result.frontFaceAngleDeg;result.rxOverLambda;result.ryOverLambda];
referenceLower = [cfg.reference.frontFaceAngleDeg(1); ...
    cfg.reference.rxOverLambda(1);cfg.reference.ryOverLambda(1)];
referenceUpper = [cfg.reference.frontFaceAngleDeg(2); ...
    cfg.reference.rxOverLambda(2);cfg.reference.ryOverLambda(2)];
pass = [result.anglePass;result.rxPass;result.ryPass];
summary = table(metric,value,referenceLower,referenceUpper,pass);
writetable(summary,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_metrics.csv'));
save(fullfile(cfg.outputDirectory,'breaker_morphology_validation.mat'), ...
    'cfg','curlCfg','result','summary');

fig = figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[80 80 1420 470]);
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');

nexttile(layout,1);
p = result.profile;
plot(p.u0/result.wavelength,p.z0/result.wavelength,'-', ...
    'Color',[0.45 0.45 0.45],'LineWidth',1.2); hold on;
plot(p.u/result.wavelength,p.z/result.wavelength,'-', ...
    'Color',[0.05 0.35 0.75],'LineWidth',1.8);
scatter(p.u(p.front)/result.wavelength,p.z(p.front)/result.wavelength, ...
    28,[0.85 0.15 0.12],'filled');
plot_front_fit(result,result.wavelength);
activeU = p.u(p.active)/result.wavelength;
activeZ = p.z(p.active)/result.wavelength;
xPadding = 0.12*(max(activeU)-min(activeU));
xBounds = [min(activeU)-xPadding,max(activeU)+xPadding];
zCenter = 0.5*(min(activeZ)+max(activeZ));
xlim(xBounds);
ylim(zCenter+0.5*diff(xBounds)*[-1 1]);
axis equal; grid on;
xlabel('u / \lambda_p'); ylabel('z / \lambda_p');
title('(a) Center-plane profile (physical aspect)');
legend('G0 background','G1 curled profile','Front-face samples', ...
    'Front-face fit','Location','best');

nexttile(layout,2);
plot_reference_point(result.frontFaceAngleDeg, ...
    cfg.reference.frontFaceAngleDeg,'Front-face angle (deg)');
title('(b) Front-face angle');

nexttile(layout,3);
hold on;
plot_range(1,cfg.reference.rxOverLambda);
plot_range(2,cfg.reference.ryOverLambda);
plot(1,result.rxOverLambda,'o','MarkerSize',8,'LineWidth',1.5, ...
    'MarkerFaceColor',[0.05 0.35 0.75],'Color',[0.05 0.35 0.75]);
plot(2,result.ryOverLambda,'o','MarkerSize',8,'LineWidth',1.5, ...
    'MarkerFaceColor',[0.05 0.35 0.75],'Color',[0.05 0.35 0.75]);
xlim([0.5 2.5]); ylim([0 max([0.08,result.rxOverLambda*1.15, ...
    result.ryOverLambda*1.15])]);
xticks([1 2]); xticklabels({'r_x / \lambda_p','r_y / \lambda_p'});
ylabel('Normalized scale'); grid on;
title('(c) Curl scale');

set(findall(fig,'Type','axes'),'FontName','Times New Roman', ...
    'FontSize',11,'LineWidth',0.8,'Layer','top');
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_validation.png'),'Resolution',240);
exportgraphics(fig,fullfile(cfg.outputDirectory, ...
    'breaker_morphology_validation.pdf'),'ContentType','vector');

function plot_front_fit(result,wavelength)
points = [result.profile.u(result.profile.front), ...
    result.profile.z(result.profile.front)];
t = max(vecnorm(points-result.frontFit.mean,2,2));
linePoints = result.frontFit.mean + [-t;t]*result.frontFit.direction';
plot(linePoints(:,1)/wavelength,linePoints(:,2)/wavelength,'--', ...
    'Color',[0.85 0.15 0.12],'LineWidth',1.4);
end

function plot_reference_point(value,bounds,labelText)
hold on;
patch([0.7 1.3 1.3 0.7],bounds([1 1 2 2]),[0.82 0.88 0.96], ...
    'EdgeColor','none','FaceAlpha',0.8);
plot(1,value,'o','MarkerSize',8,'LineWidth',1.5, ...
    'MarkerFaceColor',[0.05 0.35 0.75],'Color',[0.05 0.35 0.75]);
xlim([0.5 1.5]);
ylim([min([bounds(1)*0.9,value*0.9]),max([bounds(2)*1.1,value*1.1])]);
xticks(1); xticklabels({'G1'}); ylabel(labelText); grid on;
end

function plot_range(x,bounds)
patch(x+[-0.28 0.28 0.28 -0.28],bounds([1 1 2 2]), ...
    [0.82 0.88 0.96],'EdgeColor','none','FaceAlpha',0.8);
end

function textValue = pass_text(tf)
if tf
    textValue = 'PASS';
else
    textValue = 'OUTSIDE';
end
end
