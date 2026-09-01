clear; close all; clc;

cfg = default_wind_components_config();
surfaceData = generate_directional_wind_components_surface(cfg);

assert(surfaceData.metrics.residualReconstructionError < 1e-10, ...
    'Background band separation does not reconstruct the input surface.');
assert(surfaceData.metrics.directionErrorDeg <= ...
    2*cfg.wind.angularSpreadStdDeg, ...
    'The synthesized component does not follow the requested direction.');
assert(surfaceData.metrics.previewChangeRms > 0, ...
    'The short-wave component does not propagate in time.');
assert(surfaceData.detection.alongCurvature < 0, ...
    'The selected Curl target is not a crest in the propagation direction.');

if ~exist(cfg.output.outputDirectory,'dir')
    mkdir(cfg.output.outputDirectory);
end

fprintf('Directional short-scale wind-wave surface generated.\n');
fprintf('  wavelength band             : %.3f - %.3f m\n', ...
    cfg.wind.minimumWavelength,cfg.wind.maximumWavelength);
fprintf('  central wavelength          : %.3f m\n', ...
    surfaceData.metrics.centralWavelength);
fprintf('  requested direction         : %.2f deg\n', ...
    cfg.wind.propagationDirectionDeg);
fprintf('  estimated direction         : %.2f deg\n', ...
    surfaceData.metrics.estimatedPropagationDirectionDeg);
fprintf('  direction error             : %.3f deg\n', ...
    surfaceData.metrics.directionErrorDeg);
fprintf('  removed/component RMS       : %.5f / %.5f m\n', ...
    surfaceData.metrics.removedBandRms, ...
    surfaceData.metrics.windComponentRms);
fprintf('  total RMS relative change   : %.3f %%\n', ...
    100*surfaceData.metrics.relativeRmsChange);
fprintf('  original/combined MSS       : %.5f / %.5f\n', ...
    surfaceData.metrics.originalMss,surfaceData.metrics.combinedMss);
fprintf('  selected crest              : (%.3f, %.3f, %.3f) m\n', ...
    surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z);
fprintf('  crest steepness proxy       : %.4f\n', ...
    surfaceData.detection.localSteepnessProxy);
fprintf('  crest candidate count       : %d\n', ...
    surfaceData.detection.candidateCount);

zMin = min([surfaceData.ZOriginalBackground(:);surfaceData.Z(:)]);
zMax = max([surfaceData.ZOriginalBackground(:);surfaceData.Z(:)]);
commonLimits = [zMin,zMax];

figBackground = new_figure(cfg.output.figureVisible,[80 80 1040 720]);
surf(surfaceData.X,surfaceData.Y,surfaceData.ZOriginalBackground, ...
    surfaceData.ZOriginalBackground,'EdgeColor','none');
axis tight; pbaspect([1 1 0.22]); view(44,26); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Nonlinear Elfouhaily Background');
colormap(turbo); clim(commonLimits); colorbar;

figComponent = new_figure(cfg.output.figureVisible,[110 110 1040 720]);
imagesc(surfaceData.XLinear(1,:),surfaceData.YLinear(:,1), ...
    surfaceData.ZWindComponent);
axis xy image; hold on;
quiver(8,8,10*cosd(cfg.wind.propagationDirectionDeg), ...
    10*sind(cfg.wind.propagationDirectionDeg),0,'k', ...
    'LineWidth',1.8,'MaxHeadSize',0.8);
xlabel('x (m)'); ylabel('y (m)');
title('Directional Short-scale Wind-wave Component');
colormap(turbo); colorbar;

figCombined = new_figure(cfg.output.figureVisible,[70 70 1280 820]);
surf(surfaceData.X,surfaceData.Y,surfaceData.Z, ...
    surfaceData.Z,'EdgeColor','none'); hold on;
plot3(surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z,'kp','MarkerFaceColor','w', ...
    'MarkerSize',12,'LineWidth',1.4);
arrowLength = 8;
psi = deg2rad(cfg.wind.propagationDirectionDeg);
quiver3(surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z+0.15,arrowLength*cos(psi), ...
    arrowLength*sin(psi),0,0,'k','LineWidth',1.8, ...
    'MaxHeadSize',0.8);
shading interp;
axis tight vis3d; pbaspect([1 1 0.40]); view(42,31); grid on;
camproj orthographic; camzoom(0.68);
camlight('headlight'); lighting gouraud; material dull;
rotate3d on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Complete Nonlinear Sea with Directional Short Wind Waves');
colormap(turbo); clim(commonLimits);
combinedAxes = gca;
combinedColorbar = colorbar;
set(combinedAxes,'Position',[0.07 0.10 0.75 0.82]);
set(combinedColorbar,'Position',[0.87 0.16 0.022 0.70]);

% A full-domain view necessarily compresses the 1.5--5 m wind-wave band.
% Plot a separate physical 3-D neighborhood so its directional relief and
% the selected steep crest remain directly inspectable.
detailHalfWidth = 14;
xVector = surfaceData.XLinear(1,:);
yVector = surfaceData.YLinear(:,1);
detailColumns = find(abs(xVector-surfaceData.detection.parameterX) <= ...
    detailHalfWidth);
detailRows = find(abs(yVector-surfaceData.detection.parameterY) <= ...
    detailHalfWidth);
detailZ = surfaceData.Z(detailRows,detailColumns);
detailZLimits = [min(detailZ,[],'all'),max(detailZ,[],'all')];
detailPadding = max(0.08,0.08*diff(detailZLimits));

figDetail = new_figure(cfg.output.figureVisible,[100 100 1080 760]);
surf(surfaceData.X(detailRows,detailColumns), ...
    surfaceData.Y(detailRows,detailColumns),detailZ,detailZ, ...
    'EdgeColor','none'); hold on;
plot3(surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z,'kp','MarkerFaceColor','w', ...
    'MarkerSize',13,'LineWidth',1.5);
localArrowLength = 4;
quiver3(surfaceData.detection.x,surfaceData.detection.y, ...
    surfaceData.detection.z+detailPadding, ...
    localArrowLength*cos(psi),localArrowLength*sin(psi),0,0,'k', ...
    'LineWidth',2.0,'MaxHeadSize',0.9);
shading interp;
axis tight vis3d;
zlim(detailZLimits+[-detailPadding,detailPadding]);
pbaspect([1 1 0.52]); view(42,30); grid on;
camproj orthographic; camzoom(0.72);
camlight('headlight'); lighting gouraud; material dull;
rotate3d on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Local 3-D Detail around Selected Crest');
colormap(turbo); clim(commonLimits);
detailAxes = gca;
detailColorbar = colorbar;
set(detailAxes,'Position',[0.07 0.10 0.75 0.76]);
set(detailColorbar,'Position',[0.87 0.16 0.022 0.70]);

% Extract an interpolated section through the selected crest along the
% requested propagation direction.
s = linspace(-12,12,600);
xSection = surfaceData.detection.parameterX+s*cos(psi);
ySection = surfaceData.detection.parameterY+s*sin(psi);
zBackground = interp2(surfaceData.XLinear,surfaceData.YLinear, ...
    surfaceData.ZOriginalBackground,xSection,ySection,'linear',NaN);
zCombined = interp2(surfaceData.XLinear,surfaceData.YLinear, ...
    surfaceData.Z,xSection,ySection,'linear',NaN);
figSection = new_figure(cfg.output.figureVisible,[170 170 940 620]);
plot(s,zBackground,'Color',[0.25 0.25 0.25], ...
    'LineWidth',1.2); hold on;
plot(s,zCombined,'r-','LineWidth',1.7);
plot(0,surfaceData.detection.z,'kp','MarkerFaceColor','w', ...
    'MarkerSize',11,'LineWidth',1.3);
grid on;
xlabel('Propagation coordinate u (m)'); ylabel('z (m)');
sectionLegend = legend('Nonlinear background','With short wind waves', ...
    'Selected crest','Location','best');
set(sectionLegend,'Color','w','TextColor','k', ...
    'EdgeColor',[0.35 0.35 0.35]);
title('Propagation-direction Section through the Selected Crest');

exportgraphics(figBackground,fullfile(cfg.output.outputDirectory, ...
    '01_nonlinear_background.png'),'Resolution',180, ...
    'BackgroundColor','white');
exportgraphics(figComponent,fullfile(cfg.output.outputDirectory, ...
    '02_directional_short_wind_component.png'),'Resolution',180, ...
    'BackgroundColor','white');
exportgraphics(figCombined,fullfile(cfg.output.outputDirectory, ...
    '03_combined_wind_component_surface.png'),'Resolution',180, ...
    'BackgroundColor','white');
exportgraphics(figDetail,fullfile(cfg.output.outputDirectory, ...
    '04_selected_crest_3d_detail.png'),'Resolution',200, ...
    'BackgroundColor','white');
exportgraphics(figSection,fullfile(cfg.output.outputDirectory, ...
    '05_selected_crest_directional_section.png'),'Resolution',200, ...
    'BackgroundColor','white');

if cfg.output.saveSurfaceMat
    X = surfaceData.X;
    Y = surfaceData.Y;
    Z = surfaceData.Z;
    ZBackground = surfaceData.ZOriginalBackground;
    ZWindComponent = surfaceData.ZWindComponent;
    dZWindDt = surfaceData.dZWindDt;
    detection = surfaceData.detection;
    detection = rmfield(detection,{'alongSlopeMap','alongCurvatureMap'});
    metrics = surfaceData.metrics;
    save(fullfile(cfg.output.outputDirectory, ...
        'directional_wind_components_surface.mat'), ...
        'X','Y','Z','ZBackground','ZWindComponent','dZWindDt', ...
        'detection','metrics','cfg','-v7.3');
end

function fig = new_figure(visibility,position)
fig = figure('Visible',visibility,'Color','w','Position',position);
set(fig,'DefaultTextColor','k');
set(gca,'Color','w','XColor','k','YColor','k','ZColor','k', ...
    'GridColor',[0.65 0.65 0.65],'FontName','Times New Roman', ...
    'FontSize',12,'LineWidth',0.8,'Layer','top');
hold(gca,'on');
end
