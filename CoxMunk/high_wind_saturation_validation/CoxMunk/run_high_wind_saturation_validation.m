function [raw,summary,reference,assessment,closure] = ...
    run_high_wind_saturation_validation(cfg)
%RUN_HIGH_WIND_SATURATION_VALIDATION Held-out hurricane MSS experiment.

arguments
    cfg (1,1) struct = default_high_wind_saturation_config()
end
validate_config(cfg);
addpath(cfg.source.nonlinearDirectory);
if ~isfolder(cfg.output.directory), mkdir(cfg.output.directory); end

reference = make_reference(cfg.windSpeeds);
closure = calibrate_tail_dissipation(cfg);

nRows = numel(cfg.windSpeeds)*numel(cfg.randomSeeds)*numel(cfg.groups);
U10 = zeros(nRows,1); Seed = zeros(nRows,1); Group = strings(nRows,1);
MssTotal = zeros(nRows,1); MssAlong = zeros(nRows,1);
MssCross = zeros(nRows,1); AppliedNonlinearScale = ones(nRows,1);
AppliedMu = zeros(nRows,1); AppliedGain = ones(nRows,1); row = 0;

for windIndex = 1:numel(cfg.windSpeeds)
    windSpeed = cfg.windSpeeds(windIndex);
    for seedIndex = 1:numel(cfg.randomSeeds)
        seed = cfg.randomSeeds(seedIndex);
        baseCfg = make_surface_config(cfg,windSpeed,seed,[],false);
        base = generate_nonlinear_lie_elfouhaily_surface(baseCfg);
        saturatedCfg = make_surface_config(cfg,windSpeed,seed,closure,true);
        saturated = generate_nonlinear_lie_elfouhaily_surface(saturatedCfg);

        linear = calculate_spectral_surface_mss(base.ZLinear, ...
            base.KX,base.KY,cfg.sea.windDirectionDeg);
        [rawLie,rawScale] = constrained_lie_stats(base,linear.mssTotal, ...
            cfg.rawConstraint.maximumRelativeMssIncrease,cfg);
        saturatedLinear = calculate_spectral_surface_mss( ...
            saturated.ZLinear,saturated.KX,saturated.KY, ...
            cfg.sea.windDirectionDeg);
        [saturatedLie,saturatedScale] = constrained_lie_stats( ...
            saturated,saturatedLinear.mssTotal, ...
            cfg.saturationConstraint.maximumRelativeMssIncrease,cfg);

        add_row(cfg.groups(1),linear,1,0,1);
        add_row(cfg.groups(2),rawLie,rawScale,0,1);
        add_row(cfg.groups(3),saturatedLie,saturatedScale, ...
            saturated.saturationMeta.mu,saturated.saturationMeta.gain);
    end
    fprintf('Completed U10 = %.1f m/s (%d/%d).\n',windSpeed, ...
        windIndex,numel(cfg.windSpeeds));
end

raw = table(U10,Seed,Group,MssAlong,MssCross,MssTotal, ...
    AppliedNonlinearScale,AppliedMu,AppliedGain);
summary = summarize_results(raw,cfg);
assessment = assess_results(summary,reference,cfg);
verify_acceptance(summary,assessment,cfg);

writetable(raw,fullfile(cfg.output.directory,'high_wind_raw.csv'));
writetable(summary,fullfile(cfg.output.directory,'high_wind_summary.csv'));
writetable(reference,fullfile(cfg.output.directory,'high_wind_reference.csv'));
writetable(assessment,fullfile(cfg.output.directory,'high_wind_assessment.csv'));
writetable(closure.table,fullfile(cfg.output.directory, ...
    'saturation_closure_calibration.csv'));
fig = plot_results(raw,summary,reference,cfg);
exportgraphics(fig,fullfile(cfg.output.directory, ...
    'high_wind_saturation_validation.png'),'Resolution',240);
close(fig);
if cfg.output.saveMat
    save(fullfile(cfg.output.directory,'high_wind_validation.mat'), ...
        'raw','summary','reference','assessment','closure','cfg','-v7.3');
end
disp(assessment);

    function add_row(groupName,stats,scale,mu,gain)
        row = row+1;
        U10(row)=windSpeed; Seed(row)=seed; Group(row)=groupName;
        MssAlong(row)=stats.mssAlong; MssCross(row)=stats.mssCross;
        MssTotal(row)=stats.mssTotal;
        AppliedNonlinearScale(row)=scale; AppliedMu(row)=mu;
        AppliedGain(row)=gain;
    end
end

function closure = calibrate_tail_dissipation(cfg)
winds = cfg.calibrationWindSpeeds(:);
mu = zeros(size(winds)); gain = ones(size(winds));
RawExpectedMss = zeros(size(winds));
TargetLinearMss = zeros(size(winds));
for index = 1:numel(winds)
    surfaceCfg = make_surface_config(cfg,winds(index),991,[],false);
    data = generate_nonlinear_lie_elfouhaily_surface(surfaceCfg);
    dkx = 2*pi/cfg.domain.Lx; dky = 2*pi/cfg.domain.Ly;
    weight = (data.KX.^2+data.KY.^2).*data.Psi*dkx*dky;
    RawExpectedMss(index) = sum(weight,'all');
    davis = davis_2025_mss_reference(winds(index));
    TargetLinearMss(index) = davis.MssBandLimited/ ...
        (1+cfg.saturationConstraint.maximumRelativeMssIncrease);
    [mu(index),gain(index)] = solve_mu( ...
        weight,data.K,cfg,TargetLinearMss(index));
end
closure.windSpeeds = winds;
closure.mu = mu;
closure.gain = gain;
closure.wavenumberExponent = cfg.saturation.wavenumberExponent;
closure.table = table(winds,RawExpectedMss,TargetLinearMss,mu,gain, ...
    'VariableNames',{'U10','RawExpectedMss','TargetLinearMss','Mu','Gain'});
end

function [mu,gain] = solve_mu(weight,K,cfg,target)
raw=sum(weight,'all'); gain=1;
if raw <= target
    mu = 0;
    gain = target/raw;
    assert(gain <= cfg.saturation.maximumGain, ...
        'Required high-wind input gain %.3f exceeds the physical bound.',gain);
    return;
end
lower=0; upper=cfg.saturation.maximumMu;
for iteration = 1:50 %#ok<NASGU>
    mu=0.5*(lower+upper);
    attenuation=exp(-mu*(K/cfg.sea.maximumWavenumber).^ ...
        cfg.saturation.wavenumberExponent);
    value=sum(weight.*attenuation,'all');
    if value > target, lower=mu; else, upper=mu; end
end
end

function surfaceCfg = make_surface_config(cfg,wind,seed,closure,enabled)
surfaceCfg = default_nonlinear_lie_config();
surfaceCfg.randomSeed=seed; surfaceCfg.domain=cfg.domain;
surfaceCfg.sea.U10=wind;
surfaceCfg.sea.inverseWaveAge=cfg.sea.inverseWaveAge;
surfaceCfg.sea.windDirectionDeg=cfg.sea.windDirectionDeg;
surfaceCfg.sea.minimumWavenumber=cfg.sea.minimumWavenumber;
surfaceCfg.sea.maximumWavenumber=cfg.sea.maximumWavenumber;
surfaceCfg.lie.nonlinearInputCutoff=cfg.lie.nonlinearInputCutoff;
surfaceCfg.lie.nonlinearOutputCutoff=cfg.lie.nonlinearOutputCutoff;
surfaceCfg.output.figureVisible='off'; surfaceCfg.output.saveSurfaceMat=false;
surfaceCfg.sea.highWindSaturation.enabled=enabled;
if enabled
    surfaceCfg.sea.highWindSaturation.windSpeeds=closure.windSpeeds;
    surfaceCfg.sea.highWindSaturation.mu=closure.mu;
    surfaceCfg.sea.highWindSaturation.gain=closure.gain;
    surfaceCfg.sea.highWindSaturation.wavenumberExponent= ...
        closure.wavenumberExponent;
end
end

function [stats,scale] = constrained_lie_stats(data,linearMss,maxIncrease,cfg)
maximumMss=linearMss*(1+maxIncrease); scale=1;
stats=deformation_stats(data,scale,cfg);
if stats.mssTotal <= maximumMss, return; end
lower=0; upper=1;
for iteration=1:cfg.constraintBisectionIterations
    scale=0.5*(lower+upper);
    candidate=deformation_stats(data,scale,cfg);
    if candidate.mssTotal <= maximumMss
        lower=scale;
    else
        upper=scale;
    end
end
scale=lower; stats=deformation_stats(data,scale,cfg);
end

function stats = deformation_stats(data,scale,cfg)
X=data.X0+scale*(data.X-data.X0);
Y=data.Y0+scale*(data.Y-data.Y0);
Z=data.ZLinear+scale*(data.Z-data.ZLinear);
stats=calculate_parametric_surface_mss(X,Y,Z, ...
    cfg.sea.windDirectionDeg,MinimumNormalZ=cfg.minimumNormalZ);
end

function reference = make_reference(winds)
reference=davis_2025_mss_reference(winds);
reference.Davis2023Adjusted=0.109*tanh(0.057*reference.U10);
reference.IsCalibration=ismember(reference.U10,winds(1:2:end));
end

function summary = summarize_results(raw,cfg)
n=numel(cfg.windSpeeds)*numel(cfg.groups);
U10=zeros(n,1); Group=strings(n,1); Median=zeros(n,1);
Q05=zeros(n,1); Q25=zeros(n,1); Q75=zeros(n,1); Q95=zeros(n,1); row=0;
for wind=cfg.windSpeeds
    for group=cfg.groups
        row=row+1; selected=raw.U10==wind & raw.Group==group;
        values=sort(raw.MssTotal(selected));
        q=local_quantile(values,[.05 .25 .5 .75 .95]);
        U10(row)=wind; Group(row)=group; Q05(row)=q(1); Q25(row)=q(2);
        Median(row)=q(3); Q75(row)=q(4); Q95(row)=q(5);
    end
end
summary=table(U10,Group,Median,Q05,Q25,Q75,Q95);
end

function assessment = assess_results(summary,reference,cfg)
Group=cfg.groups(:); RMSE_All=zeros(numel(Group),1);
RMSE_HeldOut=zeros(numel(Group),1); MAE_HeldOut=zeros(numel(Group),1);
for index=1:numel(Group)
    selected=sortrows(summary(summary.Group==Group(index),:),'U10');
    error=selected.Median-reference.MssBandLimited;
    held=ismember(selected.U10,cfg.validationWindSpeeds);
    RMSE_All(index)=sqrt(mean(error.^2));
    RMSE_HeldOut(index)=sqrt(mean(error(held).^2));
    MAE_HeldOut(index)=mean(abs(error(held)));
end
assessment=table(Group,RMSE_All,RMSE_HeldOut,MAE_HeldOut);
end

function verify_acceptance(summary,assessment,cfg)
linear=assessment(assessment.Group==cfg.groups(1),:);
corrected=assessment(assessment.Group==cfg.groups(3),:);
assert(corrected.RMSE_HeldOut < linear.RMSE_HeldOut, ...
    'Saturation correction did not outperform Elfouhaily on held-out winds.');
curve=sortrows(summary(summary.Group==cfg.groups(3),:),'U10');
low=curve.U10>=15 & curve.U10<=25; high=curve.U10>=40;
lowSlope=polyfit(curve.U10(low),curve.Median(low),1);
highSlope=polyfit(curve.U10(high),curve.Median(high),1);
quadratic=polyfit(curve.U10,curve.Median,2);
assert(highSlope(1)>0 && highSlope(1)<0.55*lowSlope(1), ...
    'Corrected curve does not show sufficient high-wind flattening.');
assert(quadratic(1)<0,'Corrected MSS curve is not concave downward.');
end

function fig = plot_results(raw,summary,reference,cfg)
fig=figure('Visible',cfg.output.figureVisible,'Color','w', ...
    'Position',[80 80 1280 560]); ax=axes(fig); hold(ax,'on');
colors=[0.10 0.35 0.78;0.45 0.45 0.45;0.85 0.25 0.08];
for index=1:numel(cfg.groups)
    group=cfg.groups(index); selected=raw.Group==group;
    jitter=(mod(double(raw.Seed(selected))*0.61803398875,1)-0.5)*0.7;
    scatter(ax,raw.U10(selected)+jitter,raw.MssTotal(selected),12, ...
        colors(index,:),'filled','MarkerFaceAlpha',0.13, ...
        'HandleVisibility','off');
    curve=sortrows(summary(summary.Group==group,:),'U10');
    fill(ax,[curve.U10;flipud(curve.U10)],[curve.Q05;flipud(curve.Q95)], ...
        colors(index,:),'FaceAlpha',0.08,'EdgeColor','none', ...
        'HandleVisibility','off');
    plot(ax,curve.U10,curve.Median,'o-','Color',colors(index,:), ...
        'LineWidth',1.8,'MarkerSize',4,'DisplayName',group);
end
plot(ax,reference.U10,reference.MssBandLimited,'k-','LineWidth',2.2, ...
    'DisplayName','Davis 2025 central fit');
plot(ax,reference.U10,reference.MssAligned,'--','Color',[0.65 0.15 0.10], ...
    'LineWidth',1.2,'DisplayName','Davis aligned');
plot(ax,reference.U10,reference.MssCrossing,'--', ...
    'Color',[0.15 0.25 0.65],'LineWidth',1.2, ...
    'DisplayName','Davis crossing');
scatter(ax,cfg.calibrationWindSpeeds,interp1(reference.U10, ...
    reference.MssBandLimited,cfg.calibrationWindSpeeds),32,'s', ...
    'MarkerEdgeColor','k', ...
    'DisplayName','Closure calibration winds');
xlabel(ax,'10-m wind speed U_{10} (m/s)');
ylabel(ax,'Band-limited MSS, k=0.01-1 rad/m');
title(ax,'High-sea-state saturation validation');
grid(ax,'on'); box(ax,'on'); xlim(ax,[14 51]);
legend(ax,'Location','southeast');
set(ax,'FontName','Times New Roman','FontSize',11);
end

function q = local_quantile(values,p)
positions=1+(numel(values)-1)*p; lower=floor(positions); upper=ceil(positions);
weight=positions-lower; q=values(lower).*(1-weight)+values(upper).*weight;
end

function validate_config(cfg)
assert(isempty(intersect(cfg.calibrationWindSpeeds, ...
    cfg.validationWindSpeeds)),'Calibration and held-out winds overlap.');
assert(all(ismember(cfg.windSpeeds,[cfg.calibrationWindSpeeds ...
    cfg.validationWindSpeeds])),'Every wind must be calibration or held-out.');
assert(cfg.sea.minimumWavenumber==0.01 && ...
    cfg.sea.maximumWavenumber==1.0, ...
    'Davis comparison requires k=0.01-1 rad/m.');
end
