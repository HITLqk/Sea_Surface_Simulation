# Elfouhaily 与 Modified Lie 两组验证结果（自动生成）

## 1. 实验定义

- 风速：`U10 = 1:1:10 m/s`；每个风速 20 个配对 realization。
- 组别：`Linear Elfouhaily` 与 `Modified Lie Nonlinear`。当前实现没有局部破碎判据，因此不再使用 Breaking 命名。
- 默认阻力系数：`Cd=(0.8+0.065U10)*1e-3`；`alphaP=0.006sqrt(Omega)`。
- 默认 Lie 风因子：`direction_only`，无量纲且通过有符号伪微分乘子保留方向相位。

## 2. 十个问题的定量回答

### 2.1 Linear 是否复现自身理论谱积分？

是。对 Elfouhaily 积分的总 MSS RMSE 为 `0.000753451`；最大数值 Parseval/MSS 相对误差为 `5.995e-15`，最大 Hermitian 残差为 `4.840e-16`。

### 2.2 Elfouhaily 与观测参考偏差

Linear 对 Cox-Munk、Guérin、TGRS/Hu 的 RMSE 分别为 `0.0056024`、`0.00522833`、`0.00382688`。在 10 m/s 时相对偏差分别为 `+12.25%`、`+13.36%`、`+13.57%`。

### 2.3 哪些波数段导致 MSS 偏高？

在 U10=5 m/s 时，积分到 370 rad/m 已占 2-mm cutoff MSS 的 `90.5%`，积分到 1000 rad/m 占 `99.0%`。因此高波数重力-毛细与毛细段是 cutoff 敏感性和相对经验曲线偏高的主要来源。

### 2.4 Modified Lie 增量来自哪个波数段？

U10=10 m/s 的 primary-band dressing 增量峰值位于约 `0.3046 rad/m`；在 MSS 有效谱箱内，Modified 与 Linear 的最大 realized 谱比为 `1.021`。短波 tile 两组共享，因此 `DeltaTotalMss=DeltaPrimaryMss`，新增 MSS 全部来自 Lie 主波频带。

### 2.5 along/cross 影响是否对称？

不对称。10 m/s 时 along MSS 改变量为 `+6.15409e-05`，cross MSS 改变量为 `+1.18829e-05`，二者比值为 `5.179`。

### 2.6 是否存在 spectrum dressing？

存在。U10=10 m/s 在 MSS 有效谱箱内的最大 `S_modified/S_linear` 为 `1.021`；因此不能把线性 Elfouhaily 输入直接称为 Modified Lie 的最终 target spectrum。代码已提供默认关闭的诊断性 iterative spectral undressing 框架。

### 2.7 哪种 wind-factor 造成最强高风速增长？

10 m/s 诊断中 `current` 模式的 DeltaMSS 最大。`current` 模式含有量纲错误的 U10 乘子，仅保留为失败对照，不作为正式模型。

### 2.8 高阶统计与 slope PDF 是否改善？

10 m/s 时 elevation skewness 从 `-0.0088` 变为 `0.0258`，elevation excess kurtosis 从 `-0.0056` 变为 `0.0113`；along-slope skewness 从 `-0.0017` 变为 `0.0132`。这些数值证明非线性统计发生改变，但“改善”仍需实测高阶统计作为判据，不能仅凭非零值宣布通过。

### 2.9 当前是否通过 Cox-Munk validation？

不能宣称整体通过。Linear 的谱自一致性通过，但 10 m/s 相对 Cox-Munk 偏差为 `+12.25%`；Modified Lie 相对 Cox-Munk、Guérin、Hu 的偏差分别为 `+12.40%`、`+13.52%`、`+13.73%`。

### 2.10 通过项、未通过项和下一步

**通过：** Elfouhaily 随机 realization 对自身积分的二阶统计；频域/空域 MSS 一致性；最终 Fourier 场 Hermitian 对称；Riesz 算子无额外 k 放大。

**未通过：** Modified Lie 对目标二阶谱的保持；缺少实测 skewness/kurtosis/PDF 对照；当前模型没有局部 breaking criterion。

**下一步：** 核对论文式 (2.31) 风因子的无量纲定义与 Fourier 相位约定；查找严格 spectral undressing 文献算法；再用实测高阶坡度统计和局部破碎判据约束模型。

## 3. 修复前后比较

| 指标 | 修复前 | 修复后 |
|---|---:|---:|
| Linear 对 Elfouhaily RMSE | 0.00077468 | 0.000753451 |
| Modified 对 Elfouhaily RMSE | 0.0039167 | 0.000823162 |
| Modified 10 m/s total MSS | 0.0676796 | 0.061639 |
| Modified 10 m/s gamma | 0.79291 | 0.837549 |

## 4. 输出

输出目录包含 `01_total_mss.png` 至 `10_high_order_statistics.png`、7 份 CSV 和 `two_group_validation.mat`。

## 5. 仍需精读的原始公式

1. Elfouhaily et al. (1997) 中 `alpha_p`、摩擦速度/阻力系数与方向扩展式。
2. 论文第二章式 (2.30)-(2.33) 中 `h_tx/h_ty` 的定义、风因子量纲及 Fourier 变换约定。
3. Creamer/Soriano 二阶 Lie 实现中的谱 dressing 与 undressing 条件。
