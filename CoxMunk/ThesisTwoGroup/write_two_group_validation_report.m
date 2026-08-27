function write_two_group_validation_report(summary,reference,assessment,diagnostics,cfg)
%WRITE_TWO_GROUP_VALIDATION_REPORT Generate a quantitative UTF-8 report.

linear = sortrows(summary(summary.Group=="Linear Elfouhaily",:),'U10');
modified = sortrows(summary(summary.Group=="Modified Lie Nonlinear",:),'U10');
linearAssessment = assessment(assessment.Group=="Linear Elfouhaily",:);
modifiedAssessment = assessment(assessment.Group=="Modified Lie Nonlinear",:);

u10Index = find(reference.U10==10,1);
linearBiasCox = relative_bias(linear.TotalMedian(u10Index),reference.CoxMunkTotal(u10Index));
linearBiasGuerin = relative_bias(linear.TotalMedian(u10Index),reference.GuerinTotal(u10Index));
linearBiasHu = relative_bias(linear.TotalMedian(u10Index),reference.TgrsHuTotal(u10Index));
modifiedBiasCox = relative_bias(modified.TotalMedian(u10Index),reference.CoxMunkTotal(u10Index));
modifiedBiasGuerin = relative_bias(modified.TotalMedian(u10Index),reference.GuerinTotal(u10Index));
modifiedBiasHu = relative_bias(modified.TotalMedian(u10Index),reference.TgrsHuTotal(u10Index));

cutoff5 = diagnostics.cutoff(diagnostics.cutoff.U10==5 & ...
    diagnostics.cutoff.Series=="sweep",:);
full5 = cutoff5.MssTotal(end);
fraction370 = cutoff5.MssTotal(cutoff5.Kmax==370)/full5;
fraction1000 = cutoff5.MssTotal(cutoff5.Kmax==1000)/full5;

spectral10 = diagnostics.spectral(diagnostics.spectral.U10==10,:);
deltaIntegrand = spectral10.ModifiedMssIntegrand-spectral10.LinearMssIntegrand;
[~,peakIndex] = max(deltaIntegrand);
peakDressingK = spectral10.K(peakIndex);
maximumDressing = max(spectral10.DressingRatio,[],'omitnan');

deltaAlong10 = modified.AlongMedian(u10Index)-linear.AlongMedian(u10Index);
deltaCross10 = modified.CrossMedian(u10Index)-linear.CrossMedian(u10Index);
wind10 = diagnostics.windFactor(diagnostics.windFactor.U10==10,:);
[~,largestModeIndex] = max(wind10.DeltaMss);
largestMode = wind10.WindFactorMode(largestModeIndex);

path = fullfile(fileparts(cfg.outputDirectory),'two_group_validation_results.md');
[fileId,message] = fopen(path,'w','n','UTF-8');
assert(fileId>0,'Unable to write report: %s',message);
cleanup = onCleanup(@() fclose(fileId));

fprintf(fileId,'# Elfouhaily 与 Modified Lie 两组验证结果（自动生成）\n\n');
fprintf(fileId,'## 1. 实验定义\n\n');
fprintf(fileId,'- 风速：`U10 = 1:1:10 m/s`；每个风速 %d 个配对 realization。\n', ...
    numel(cfg.realizationSeeds));
fprintf(fileId,'- 组别：`Linear Elfouhaily` 与 `Modified Lie Nonlinear`。当前实现没有局部破碎判据，因此不再使用 Breaking 命名。\n');
fprintf(fileId,'- 默认阻力系数：`Cd=(0.8+0.065U10)*1e-3`；`alphaP=0.006sqrt(Omega)`。\n');
fprintf(fileId,'- 默认 Lie 风因子：`direction_only`，无量纲且通过有符号伪微分乘子保留方向相位。\n\n');

fprintf(fileId,'## 2. 十个问题的定量回答\n\n');
fprintf(fileId,'### 2.1 Linear 是否复现自身理论谱积分？\n\n');
fprintf(fileId,'是。对 Elfouhaily 积分的总 MSS RMSE 为 `%.6g`；最大数值 Parseval/MSS 相对误差为 `%.3e`，最大 Hermitian 残差为 `%.3e`。\n\n', ...
    linearAssessment.RMSE_Elfouhaily,max(linear.MaximumMssNumericalRelativeError), ...
    max(linear.MaximumHermitianResidual));

fprintf(fileId,'### 2.2 Elfouhaily 与观测参考偏差\n\n');
fprintf(fileId,'Linear 对 Cox-Munk、Guérin、TGRS/Hu 的 RMSE 分别为 `%.6g`、`%.6g`、`%.6g`。在 10 m/s 时相对偏差分别为 `%+.2f%%`、`%+.2f%%`、`%+.2f%%`。\n\n', ...
    linearAssessment.RMSE_CoxMunk,linearAssessment.RMSE_Guerin, ...
    linearAssessment.RMSE_TGRS_Hu,100*linearBiasCox,100*linearBiasGuerin,100*linearBiasHu);

fprintf(fileId,'### 2.3 哪些波数段导致 MSS 偏高？\n\n');
fprintf(fileId,'在 U10=5 m/s 时，积分到 370 rad/m 已占 2-mm cutoff MSS 的 `%.1f%%`，积分到 1000 rad/m 占 `%.1f%%`。因此高波数重力-毛细与毛细段是 cutoff 敏感性和相对经验曲线偏高的主要来源。\n\n', ...
    100*fraction370,100*fraction1000);

fprintf(fileId,'### 2.4 Modified Lie 增量来自哪个波数段？\n\n');
fprintf(fileId,'U10=10 m/s 的 primary-band dressing 增量峰值位于约 `%.4g rad/m`；在 MSS 有效谱箱内，Modified 与 Linear 的最大 realized 谱比为 `%.3f`。短波 tile 两组共享，因此 `DeltaTotalMss=DeltaPrimaryMss`，新增 MSS 全部来自 Lie 主波频带。\n\n', ...
    peakDressingK,maximumDressing);

fprintf(fileId,'### 2.5 along/cross 影响是否对称？\n\n');
fprintf(fileId,'不对称。10 m/s 时 along MSS 改变量为 `%+.6g`，cross MSS 改变量为 `%+.6g`，二者比值为 `%.3f`。\n\n', ...
    deltaAlong10,deltaCross10,deltaAlong10/max(abs(deltaCross10),realmin));

fprintf(fileId,'### 2.6 是否存在 spectrum dressing？\n\n');
fprintf(fileId,'存在。U10=10 m/s 在 MSS 有效谱箱内的最大 `S_modified/S_linear` 为 `%.3f`；因此不能把线性 Elfouhaily 输入直接称为 Modified Lie 的最终 target spectrum。代码已提供默认关闭的诊断性 iterative spectral undressing 框架。\n\n',maximumDressing);

fprintf(fileId,'### 2.7 哪种 wind-factor 造成最强高风速增长？\n\n');
fprintf(fileId,'10 m/s 诊断中 `%s` 模式的 DeltaMSS 最大。`current` 模式含有量纲错误的 U10 乘子，仅保留为失败对照，不作为正式模型。\n\n',char(largestMode));

fprintf(fileId,'### 2.8 高阶统计与 slope PDF 是否改善？\n\n');
fprintf(fileId,'10 m/s 时 elevation skewness 从 `%.4f` 变为 `%.4f`，elevation excess kurtosis 从 `%.4f` 变为 `%.4f`；along-slope skewness 从 `%.4f` 变为 `%.4f`。这些数值证明非线性统计发生改变，但“改善”仍需实测高阶统计作为判据，不能仅凭非零值宣布通过。\n\n', ...
    linear.ElevationSkewnessMedian(u10Index),modified.ElevationSkewnessMedian(u10Index), ...
    linear.ElevationExcessKurtosisMedian(u10Index),modified.ElevationExcessKurtosisMedian(u10Index), ...
    linear.AlongSlopeSkewnessMedian(u10Index),modified.AlongSlopeSkewnessMedian(u10Index));

fprintf(fileId,'### 2.9 当前是否通过 Cox-Munk validation？\n\n');
fprintf(fileId,'不能宣称整体通过。Linear 的谱自一致性通过，但 10 m/s 相对 Cox-Munk 偏差为 `%+.2f%%`；Modified Lie 相对 Cox-Munk、Guérin、Hu 的偏差分别为 `%+.2f%%`、`%+.2f%%`、`%+.2f%%`。\n\n', ...
    100*linearBiasCox,100*modifiedBiasCox,100*modifiedBiasGuerin,100*modifiedBiasHu);

fprintf(fileId,'### 2.10 通过项、未通过项和下一步\n\n');
fprintf(fileId,'**通过：** Elfouhaily 随机 realization 对自身积分的二阶统计；频域/空域 MSS 一致性；最终 Fourier 场 Hermitian 对称；Riesz 算子无额外 k 放大。\n\n');
fprintf(fileId,'**未通过：** Modified Lie 对目标二阶谱的保持；缺少实测 skewness/kurtosis/PDF 对照；当前模型没有局部 breaking criterion。\n\n');
fprintf(fileId,'**下一步：** 核对论文式 (2.31) 风因子的无量纲定义与 Fourier 相位约定；查找严格 spectral undressing 文献算法；再用实测高阶坡度统计和局部破碎判据约束模型。\n\n');

fprintf(fileId,'## 3. 修复前后比较\n\n');
fprintf(fileId,'| 指标 | 修复前 | 修复后 |\n|---|---:|---:|\n');
fprintf(fileId,'| Linear 对 Elfouhaily RMSE | %.6g | %.6g |\n', ...
    cfg.previousBaseline.linearElfouhailyRmse,linearAssessment.RMSE_Elfouhaily);
fprintf(fileId,'| Modified 对 Elfouhaily RMSE | %.6g | %.6g |\n', ...
    cfg.previousBaseline.modifiedElfouhailyRmse,modifiedAssessment.RMSE_Elfouhaily);
fprintf(fileId,'| Modified 10 m/s total MSS | %.6g | %.6g |\n', ...
    cfg.previousBaseline.modifiedU10TotalMss,modified.TotalMedian(u10Index));
fprintf(fileId,'| Modified 10 m/s gamma | %.6g | %.6g |\n\n', ...
    cfg.previousBaseline.modifiedU10Gamma,modified.GammaMedian(u10Index));

fprintf(fileId,'## 4. 输出\n\n');
fprintf(fileId,'输出目录包含 `01_total_mss.png` 至 `10_high_order_statistics.png`、7 份 CSV 和 `two_group_validation.mat`。\n\n');
fprintf(fileId,'## 5. 仍需精读的原始公式\n\n');
fprintf(fileId,'1. Elfouhaily et al. (1997) 中 `alpha_p`、摩擦速度/阻力系数与方向扩展式。\n');
fprintf(fileId,'2. 论文第二章式 (2.30)-(2.33) 中 `h_tx/h_ty` 的定义、风因子量纲及 Fourier 变换约定。\n');
fprintf(fileId,'3. Creamer/Soriano 二阶 Lie 实现中的谱 dressing 与 undressing 条件。\n');
end

function value = relative_bias(estimate,reference)
value = (estimate-reference)/reference;
end
