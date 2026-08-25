clear; close all; clc;

cfg = default_nonlinear_lie_config();
surfaceData = generate_nonlinear_lie_elfouhaily_surface(cfg);

assert(all(isfinite(surfaceData.Z),'all'), ...
    'The nonlinear surface contains non-finite elevations.');
assert(surfaceData.metrics.minimumHorizontalJacobian >= ...
    cfg.lie.minimumJacobian, ...
    'The horizontal Lie mapping contains folded cells.');
assert(surfaceData.metrics.nonlinearSkewness > ...
    surfaceData.metrics.linearSkewness, ...
    'The nonlinear correction did not increase crest-trough asymmetry.');

if ~exist(cfg.output.outputDirectory,'dir')
    mkdir(cfg.output.outputDirectory);
end

fprintf('Nonlinear Lie-improved Elfouhaily sea generated.\n');
fprintf('  U10                       : %.2f m/s\n',cfg.sea.U10);
fprintf('  wind direction            : %.2f deg\n', ...
    cfg.sea.windDirectionDeg);
fprintf('  spectral peak wavelength  : %.3f m\n', ...
    surfaceData.spectrumMeta.peakWavelength);
fprintf('  applied nonlinear gain    : %.4f\n', ...
    surfaceData.metrics.appliedWindGain);
fprintf('  applied horizontal gain   : %.4f\n', ...
    surfaceData.metrics.appliedHorizontalGain);
fprintf('  minimum map Jacobian      : %.4f\n', ...
    surfaceData.metrics.minimumHorizontalJacobian);
fprintf('  linear/nonlinear Hs       : %.4f / %.4f m\n', ...
    surfaceData.metrics.linearHs,surfaceData.metrics.nonlinearHs);
fprintf('  linear/nonlinear skewness : %.4f / %.4f\n', ...
    surfaceData.metrics.linearSkewness, ...
    surfaceData.metrics.nonlinearSkewness);
fprintf('  linear/nonlinear MSS      : %.5f / %.5f\n', ...
    surfaceData.metrics.linearMss,surfaceData.metrics.nonlinearMss);
fprintf('  nonlinear crest/trough    : %.4f / %.4f m\n', ...
    surfaceData.metrics.maximumCrest, ...
    surfaceData.metrics.minimumTrough);

zMin = min([surfaceData.ZLinear(:);surfaceData.Z(:)]);
zMax = max([surfaceData.ZLinear(:);surfaceData.Z(:)]);
commonLimits = [zMin,zMax];

figLinear = new_figure(cfg.output.figureVisible,[80 80 1040 720]);
surf(surfaceData.X0,surfaceData.Y0,surfaceData.ZLinear, ...
    surfaceData.ZLinear,'EdgeColor','none');
axis tight; pbaspect([1 1 0.22]); view(44,26); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Linear Directional Elfouhaily Sea');
colormap(turbo); clim(commonLimits); colorbar;

figNonlinear = new_figure(cfg.output.figureVisible,[110 110 1040 720]);
surf(surfaceData.X,surfaceData.Y,surfaceData.Z, ...
    surfaceData.Z,'EdgeColor','none');
axis tight; pbaspect([1 1 0.22]); view(44,26); grid on;
xlabel('x (m)'); ylabel('y (m)'); zlabel('z (m)');
title('Nonlinear Lie-improved Elfouhaily Sea');
colormap(turbo); clim(commonLimits); colorbar;

row = round(size(surfaceData.Z,1)/2);
figSection = new_figure(cfg.output.figureVisible,[140 140 940 620]);
plot(surfaceData.X0(row,:),surfaceData.ZLinear(row,:), ...
    'Color',[0.25 0.25 0.25],'LineWidth',1.2); hold on;
plot(surfaceData.X(row,:),surfaceData.Z(row,:), ...
    'r-','LineWidth',1.7);
grid on; xlim([0 cfg.domain.Lx]);
xlabel('x (m)'); ylabel('z (m)');
legend('Linear Elfouhaily','Nonlinear Lie surface', ...
    'Location','best');
title('Central Along-wind Section');

exportgraphics(figLinear,fullfile(cfg.output.outputDirectory, ...
    '01_linear_elfouhaily_surface.png'),'Resolution',180);
exportgraphics(figNonlinear,fullfile(cfg.output.outputDirectory, ...
    '02_nonlinear_lie_elfouhaily_surface.png'),'Resolution',180);
exportgraphics(figSection,fullfile(cfg.output.outputDirectory, ...
    '03_linear_nonlinear_section.png'),'Resolution',200);

if cfg.output.saveSurfaceMat
    X = surfaceData.X;
    Y = surfaceData.Y;
    Z = surfaceData.Z;
    XLinear = surfaceData.X0;
    YLinear = surfaceData.Y0;
    ZLinear = surfaceData.ZLinear;
    metrics = surfaceData.metrics;
    save(fullfile(cfg.output.outputDirectory, ...
        'nonlinear_lie_elfouhaily_surface.mat'), ...
        'X','Y','Z','XLinear','YLinear','ZLinear','metrics','cfg','-v7.3');
end

function fig = new_figure(visibility,position)
fig = figure('Visible',visibility,'Color','w','Position',position);
set(gca,'Color','w','FontName','Times New Roman','FontSize',12, ...
    'LineWidth',0.8,'Layer','top');
end
