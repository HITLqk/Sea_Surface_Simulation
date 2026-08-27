function plot_two_group_validation_outputs(summary,reference,diagnostics,cfg)
%PLOT_TWO_GROUP_VALIDATION_OUTPUTS Generate the ten required figures.

figures = gobjects(10,1);
figures(1) = plot_total_mss(summary,reference,cfg);
figures(2) = plot_directional_mss(summary,reference,cfg);
figures(3) = plot_anisotropy(summary,reference,cfg);
figures(4) = plot_slope_pdf(diagnostics.pdf,cfg);
figures(5) = plot_cutoff(diagnostics.cutoff,cfg);
figures(6) = plot_dressing(diagnostics.spectral,cfg);
figures(7) = plot_delta(summary,cfg);
figures(8) = plot_wind_modes(diagnostics.windFactor,cfg);
figures(9) = plot_surfaces(diagnostics.examples,cfg);
figures(10) = plot_high_order(summary,cfg);
names = {'01_total_mss.png','02_along_cross_mss.png','03_anisotropy.png', ...
    '04_slope_pdf.png','05_mss_cutoff_sensitivity.png', ...
    '06_spectral_dressing.png','07_lie_delta_mss.png', ...
    '08_wind_factor_diagnostic.png','09_surface_examples.png', ...
    '10_high_order_statistics.png'};
for index = 1:numel(figures)
    exportgraphics(figures(index),fullfile(cfg.outputDirectory,names{index}), ...
        'Resolution',cfg.exportResolution);
    close(figures(index));
end
end

function fig = plot_total_mss(summary,reference,cfg)
fig = new_figure(cfg,[1300 620]); ax = axes(fig); hold(ax,'on');
groups = unique(summary.Group,'stable'); colors = lines(2);
for index = 1:2
    data = sortrows(summary(summary.Group == groups(index),:),'U10');
    fill(ax,[data.U10;flipud(data.U10)],[data.TotalQ05;flipud(data.TotalQ95)], ...
        colors(index,:),'FaceAlpha',0.10,'EdgeColor','none', ...
        'HandleVisibility','off');
    plot(ax,data.U10,data.TotalMedian,'o-','Color',colors(index,:), ...
        'LineWidth',1.8,'DisplayName',groups(index));
end
plot(ax,reference.U10,reference.ElfouhailyTotal,'k:','LineWidth',1.7, ...
    'DisplayName','Elfouhaily integral');
plot(ax,reference.U10,reference.CoxMunkTotal,'k--','LineWidth',1.5, ...
    'DisplayName','Cox-Munk');
plot(ax,reference.U10,reference.TgrsHuTotal,'-.','Color',[0.8 0.2 0.1], ...
    'LineWidth',1.5,'DisplayName','TGRS/Hu');
plot(ax,reference.U10,reference.GuerinTotal,'s','Color',[0.2 0.45 0.9], ...
    'MarkerFaceColor','none','DisplayName','Guerin IASI');
xlabel(ax,'U_{10} (m/s)'); ylabel(ax,'Total MSS'); grid(ax,'on'); box(ax,'on');
xlim(ax,[1 10]); legend(ax,'Location','northwest'); title(ax,'Total mean square slope');
end

function fig = plot_directional_mss(summary,reference,cfg)
fig = new_figure(cfg,[1500 620]); tiledlayout(fig,1,2,'TileSpacing','compact');
groups = unique(summary.Group,'stable'); colors = lines(2);
components = {'Along','Cross'};
for panel = 1:2
    ax = nexttile; hold(ax,'on');
    for index = 1:2
        data = sortrows(summary(summary.Group == groups(index),:),'U10');
        plot(ax,data.U10,data.([components{panel},'Median']),'o-', ...
            'Color',colors(index,:),'LineWidth',1.7,'DisplayName',groups(index));
    end
    plot(ax,reference.U10,reference.(['Elfouhaily',components{panel}]), ...
        'k:','LineWidth',1.6,'DisplayName','Elfouhaily integral');
    plot(ax,reference.U10,reference.(['CoxMunk',components{panel}]), ...
        'k--','LineWidth',1.4,'DisplayName','Cox-Munk');
    plot(ax,reference.U10,reference.(['Guerin',components{panel}]),'s', ...
        'Color',[0.2 0.45 0.9],'MarkerFaceColor','none','DisplayName','Guerin IASI');
    plot(ax,reference.U10,reference.(['TgrsHu',components{panel}]),'-.', ...
        'Color',[0.8 0.2 0.1],'LineWidth',1.4,'DisplayName','TGRS/Hu');
    xlabel(ax,'U_{10} (m/s)'); ylabel(ax,[components{panel},'-wind MSS']);
    title(ax,[components{panel},'-wind component']); grid(ax,'on'); box(ax,'on');
    xlim(ax,[1 10]); if panel==1, legend(ax,'Location','northwest'); end
end
end

function fig = plot_anisotropy(summary,reference,cfg)
fig = new_figure(cfg,[1250 620]); ax = axes(fig); hold(ax,'on');
groups = unique(summary.Group,'stable'); colors = lines(2);
for index = 1:2
    data = sortrows(summary(summary.Group == groups(index),:),'U10');
    plot(ax,data.U10,data.GammaMedian,'o-','Color',colors(index,:), ...
        'LineWidth',1.8,'DisplayName',groups(index));
end
plot(ax,reference.U10,reference.ElfouhailyGamma,'k:','LineWidth',1.6, ...
    'DisplayName','Elfouhaily integral');
plot(ax,reference.U10,reference.GuerinGamma,'s','Color',[0.2 0.45 0.9], ...
    'MarkerFaceColor','none','DisplayName','Guerin IASI');
yline(ax,0.864,'-.','TGRS mean 0.864','Color',[0.8 0.2 0.1], ...
    'HandleVisibility','off');
yline(ax,0.84,'--','TGRS simulated 0.84','Color',[0.45 0.2 0.6], ...
    'HandleVisibility','off');
xlabel(ax,'U_{10} (m/s)'); ylabel(ax,'\gamma=(MSS_c/MSS_a)^{1/2}');
grid(ax,'on'); box(ax,'on'); xlim(ax,[1 10]); legend(ax,'Location','best');
title(ax,'Slope anisotropy');
end

function fig = plot_slope_pdf(pdfData,cfg)
fig = new_figure(cfg,[1500 980]); tiledlayout(fig,2,2,'TileSpacing','compact');
winds = reshape(cfg.slopePdfWinds,1,[]);
for windIndex = 1:numel(winds)
    data = pdfData.(sprintf('U%d',winds(windIndex)));
    pairs = {{data.linearAlong,data.modifiedAlong,'Along-wind'}, ...
        {data.linearCross,data.modifiedCross,'Cross-wind'}};
    for component = 1:2
        ax = nexttile; hold(ax,'on');
        linear = pairs{component}{1}; modified = pairs{component}{2};
        limits = robust_limits([linear;modified],0.002);
        edges = linspace(limits(1),limits(2),90);
        centers = (edges(1:end-1)+edges(2:end))/2;
        plot(ax,centers,histcounts(linear,edges,'Normalization','pdf'), ...
            'LineWidth',1.6,'DisplayName','Linear');
        plot(ax,centers,histcounts(modified,edges,'Normalization','pdf'), ...
            'LineWidth',1.6,'DisplayName','Modified Lie');
        plot(ax,centers,normal_pdf(centers,std(linear,1)),'--', ...
            'LineWidth',1.2,'DisplayName','Gaussian (linear variance)');
        plot(ax,centers,normal_pdf(centers,std(modified,1)),':', ...
            'LineWidth',1.4,'DisplayName','Gaussian (modified variance)');
        title(ax,sprintf('%s slopes, U_{10}=%d m/s', ...
            pairs{component}{3},winds(windIndex)));
        xlabel(ax,'Slope'); ylabel(ax,'PDF'); grid(ax,'on'); box(ax,'on');
        if windIndex==1 && component==1, legend(ax,'Location','best'); end
    end
end
end

function fig = plot_cutoff(data,cfg)
fig = new_figure(cfg,[1450 620]); tiledlayout(fig,1,2,'TileSpacing','compact');
winds = reshape(cfg.slopePdfWinds,1,[]); colors = lines(numel(winds));
ax = nexttile; hold(ax,'on');
for index = 1:numel(winds)
    selected = data.U10==winds(index) & data.Series=="sweep";
    semilogx(ax,data.Kmax(selected),data.MssTotal(selected),'o-', ...
        'Color',colors(index,:),'LineWidth',1.7, ...
        'DisplayName',sprintf('U_{10}=%d',winds(index)));
end
xlabel(ax,'Optical cutoff k_{max} (rad/m)'); ylabel(ax,'Integrated MSS');
title(ax,'Cutoff sweep'); grid(ax,'on'); box(ax,'on'); legend(ax,'Location','best');
ax = nexttile; hold(ax,'on');
for index = 1:numel(winds)
    selected = data.U10==winds(index) & data.Series=="cumulative";
    semilogx(ax,data.Kmax(selected),data.MssTotal(selected), ...
        'Color',colors(index,:),'LineWidth',1.7, ...
        'DisplayName',sprintf('U_{10}=%d',winds(index)));
end
xlabel(ax,'Upper wavenumber k (rad/m)'); ylabel(ax,'Cumulative MSS');
title(ax,'Cumulative MSS contribution'); grid(ax,'on'); box(ax,'on');
end

function fig = plot_dressing(data,cfg)
fig = new_figure(cfg,[1550 1180]);
tiledlayout(fig,3,3,'TileSpacing','compact','Padding','compact');
winds = reshape(cfg.spectralDiagnosticWinds,1,[]);
for row = 1:numel(winds)
    selected = data(data.U10==winds(row),:);
    selected = selected(isfinite(selected.DressingRatio),:);
    ax=nexttile; loglog(ax,selected.K,selected.LinearSpectrum,'LineWidth',1.4); hold(ax,'on');
    loglog(ax,selected.K,selected.ModifiedSpectrum,'LineWidth',1.4);
    title(ax,sprintf('S(k), U_{10}=%d (MSS-effective)',winds(row))); grid(ax,'on'); box(ax,'on');
    if row==1, legend(ax,{'Linear','Modified'},'Location','best'); end
    ax=nexttile; loglog(ax,selected.K,selected.LinearMssIntegrand,'LineWidth',1.4); hold(ax,'on');
    loglog(ax,selected.K,selected.ModifiedMssIntegrand,'LineWidth',1.4);
    title(ax,'k^2S(k)'); grid(ax,'on'); box(ax,'on');
    ax=nexttile; semilogx(ax,selected.K,selected.DressingRatio,'LineWidth',1.4); hold(ax,'on');
    yline(ax,1,'k--'); title(ax,'S_{modified}/S_{linear}'); grid(ax,'on'); box(ax,'on');
end
end

function fig = plot_delta(summary,cfg)
fig = new_figure(cfg,[1450 620]); tiledlayout(fig,1,2,'TileSpacing','compact');
data = sortrows(summary(summary.Group=="Modified Lie Nonlinear",:),'U10');
ax=nexttile; hold(ax,'on');
plot(ax,data.U10,data.DeltaPrimaryMssMedian,'o-','LineWidth',1.7, ...
    'DisplayName','Primary MSS increment');
plot(ax,data.U10,data.DeltaTotalMssMedian,'s-','LineWidth',1.7, ...
    'DisplayName','Total MSS increment');
xlabel(ax,'U_{10} (m/s)'); ylabel(ax,'\Delta MSS'); grid(ax,'on'); box(ax,'on');
legend(ax,'Location','best'); title(ax,'Absolute nonlinear MSS increment');
ax=nexttile; hold(ax,'on');
plot(ax,data.U10,100*data.RelativeDeltaPrimaryMssMedian,'o-','LineWidth',1.7, ...
    'DisplayName','Primary');
plot(ax,data.U10,100*data.RelativeDeltaTotalMssMedian,'s-','LineWidth',1.7, ...
    'DisplayName','Total');
xlabel(ax,'U_{10} (m/s)'); ylabel(ax,'Relative increment (%)');
grid(ax,'on'); box(ax,'on'); legend(ax,'Location','best');
title(ax,'Relative nonlinear MSS increment');
end

function fig = plot_wind_modes(data,cfg)
fig = new_figure(cfg,[1550 560]); tiledlayout(fig,1,3,'TileSpacing','compact');
modes = cfg.windFactorModes; colors = lines(numel(modes));
fields = {'MssTotal','DeltaMss','Gamma'};
labels = {'Modified total MSS','\Delta total MSS','\gamma'};
for panel=1:3
    ax=nexttile; hold(ax,'on');
    for index=1:numel(modes)
        selected = data(data.WindFactorMode==modes(index),:);
        plot(ax,selected.U10,selected.(fields{panel}),'o-', ...
            'Color',colors(index,:),'LineWidth',1.6,'DisplayName',modes(index));
    end
    xlabel(ax,'U_{10} (m/s)'); ylabel(ax,labels{panel});
    grid(ax,'on'); box(ax,'on'); title(ax,labels{panel});
    if panel==1, legend(ax,'Location','best'); end
end
end

function fig = plot_surfaces(examples,cfg)
fig = new_figure(cfg,[1550 850]); tiledlayout(fig,2,3,'TileSpacing','compact');
for U10 = [5 10]
    result = examples.(sprintf('U%d',U10));
    fields = {result.linearSurface,result.modifiedLieSurface};
    limit = max(abs([fields{1}(:);fields{2}(:)]));
    x = (0:size(fields{1},1)-1)*result.primarySpacing;
    for group=1:2
        ax=nexttile; imagesc(ax,x,x,fields{group}); axis(ax,'image'); axis(ax,'xy');
        clim(ax,[-limit limit]); colorbar(ax); colormap(ax,parula);
        names={'Linear Elfouhaily','Modified Lie Nonlinear'};
        title(ax,sprintf('%s, U_{10}=%d',names{group},U10));
        xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
    end
    ax=nexttile; center=floor(size(fields{1},1)/2)+1; hold(ax,'on');
    plot(ax,x,fields{1}(center,:),'LineWidth',1.3,'DisplayName','Linear');
    plot(ax,x,fields{2}(center,:),'LineWidth',1.3,'DisplayName','Modified');
    xlabel(ax,'x (m)'); ylabel(ax,'Elevation (m)'); grid(ax,'on'); box(ax,'on');
    title(ax,sprintf('Paired section, U_{10}=%d',U10)); legend(ax,'Location','best');
end
end

function fig = plot_high_order(summary,cfg)
fig = new_figure(cfg,[1550 930]); tiledlayout(fig,2,3,'TileSpacing','compact');
groups=unique(summary.Group,'stable'); colors=lines(2);
fields={'ElevationSkewnessMedian','ElevationExcessKurtosisMedian', ...
    'AlongSlopeSkewnessMedian','AlongSlopeExcessKurtosisMedian', ...
    'CrossSlopeSkewnessMedian','CrossSlopeExcessKurtosisMedian'};
titles={'Elevation skewness','Elevation excess kurtosis', ...
    'Along-slope skewness','Along-slope excess kurtosis', ...
    'Cross-slope skewness','Cross-slope excess kurtosis'};
for panel=1:numel(fields)
    ax=nexttile; hold(ax,'on');
    for index=1:2
        data=sortrows(summary(summary.Group==groups(index),:),'U10');
        plot(ax,data.U10,data.(fields{panel}),'o-','Color',colors(index,:), ...
            'LineWidth',1.5,'DisplayName',groups(index));
    end
    yline(ax,0,'k:','HandleVisibility','off'); xlabel(ax,'U_{10} (m/s)');
    title(ax,titles{panel}); grid(ax,'on'); box(ax,'on');
    if panel==1, legend(ax,'Location','best'); end
end
end

function fig = new_figure(cfg,sizePixels)
fig=figure('Visible',cfg.figureVisible,'Color','w', ...
    'Position',[100 80 sizePixels(1) sizePixels(2)]);
end

function limits = robust_limits(values,tailFraction)
values=sort(values(:)); n=numel(values);
lo=values(max(1,round(tailFraction*n)));
hi=values(min(n,round((1-tailFraction)*n)));
span=max(abs([lo hi])); limits=[-span span];
end

function density = normal_pdf(x,sigma)
density=exp(-0.5*(x/sigma).^2)/(sqrt(2*pi)*sigma);
end
