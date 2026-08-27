# Cox-Munk / Elfouhaily / Modified Lie 验证代码重构报告

## 1. 本次结论

本次工作没有继续拟合旧曲线，而是重新建立了两个可审计的待验证组：`Linear Elfouhaily` 与 `Modified Lie Nonlinear`。正式实验覆盖 `U10=1:1:10 m/s`，每个风速 20 个配对 realization，共 400 行组数据。

Linear 组已经通过 Elfouhaily 自身谱积分、频域/空域 MSS 一致性和 Hermitian 对称检查；但相对 Cox-Munk、Guérin 和 TGRS/Hu 仍存在系统偏差。Modified Lie 组产生了可测的谱 dressing 和非高斯统计变化，但当前没有局部破碎判据，因此不能称为卷浪或 breaking-wave 模型。

## 2. 文件与改动

### 主流程

- `default_thesis_two_group_config.m`：统一风速、随机种子、波数网格、cutoff、Lie 模式和诊断开关。
- `run_thesis_two_group_validation.m`：执行 400 组数据、汇总统计、7 份 CSV、MAT 文件、10 张图和自动报告。
- `synthesize_two_group_realization.m`：用相同随机相位生成 Linear/Modified Lie；显式分解 primary MSS、short-wave MSS 和 Lie 增量。
- `plot_two_group_validation_outputs.m`：生成规定的 `01_total_mss.png` 至 `10_high_order_statistics.png`。
- `write_two_group_validation_report.m`：自动回答 10 个验证问题并写入 `two_group_validation_results.md`。

### 物理与频谱模块

- `thesis_elfouhaily_spectrum.m`：修正 `alpha_p`、阻力系数模式、PSD 非负性和低风速 `alpha_m` 诊断。
- `apply_modified_lie_transform.m`：独立实现 Riesz/Lie 变换、三种风因子模式、量纲状态和频谱 dressing。
- `undress_spectrum_for_lie.m`：默认关闭的迭代 spectral undressing 诊断框架。
- `integrated_elfouhaily_mss.m`：计算方向 Elfouhaily 谱的连续波数积分和累计 cutoff MSS。
- `two_group_mss_references.m`：统一 Cox-Munk、Guérin、TGRS/Hu 与 Elfouhaily 积分参考。

### 数值与统计模块

- `sample_hermitian_spectrum.m`、`hermitian_from_half_plane.m`、`hermitian_residual.m`：保证实海面的 Fourier 共轭关系。
- `spectral_surface_metrics.m`：独立计算频域/空域 MSS 与数值残差。
- `radial_spectrum_diagnostics.m`：输出 `S(k)`、`k^2S(k)` 和 MSS 有效谱箱中的 dressing ratio。
- `field_standardized_moments.m`：计算 skewness 和 excess kurtosis。

## 3. 核心公式修正

### Elfouhaily

长波平衡区系数改为

```text
alpha_p = 0.006 sqrt(Omega)
```

默认中性阻力系数显式设为

```text
C_d = (0.8 + 0.065 U10) x 10^-3,
u_* = sqrt(C_d) U10.
```

方向二维谱保持非负；当原始短波系数 `alpha_m<0` 时钳位为零并记录警告。正式实验在 `U10=1,2 m/s` 触发该警告，说明该参数化在极低风速下需要额外文献依据。

### Riesz 与 Modified Lie

`h_tx`、`h_ty` 按二维 Riesz 分量处理：

```text
F[h_tx] = -i (k_along/k) H,
F[h_ty] = -i (k_cross/k) H.
```

乘子无量纲，因此不会额外引入一次 `k` 放大。默认 `direction_only` 模式只使用有符号方向投影 `i k_direction/k`。旧 `current` 模式中的 `U10 abs(k_direction)/k` 量纲不闭合，仅保留为失败对照。

### MSS 分解

```text
MSS_total = MSS_primary + MSS_short,
Delta MSS = MSS_ModifiedLie - MSS_Linear.
```

两组共享短波 tiles，所以 `Delta MSS_total = Delta MSS_primary`；这使 Lie 增量的来源可以被明确追踪。

## 4. 修复前后指标

| 指标 | 修复前 | 修复后 |
|---|---:|---:|
| Linear 对 Elfouhaily 积分 RMSE | 0.00077468 | 0.000753451 |
| Modified Lie 对 Elfouhaily 积分 RMSE | 0.0039167 | 0.000823162 |
| Modified Lie 在 10 m/s 的总 MSS | 0.0676796 | 0.0616390 |
| Modified Lie 在 10 m/s 的 gamma | 0.792910 | 0.837549 |
| 最大频域/空域 MSS 相对误差 | 未系统报告 | 6.33e-15 |
| 最大 Hermitian 残差 | 未系统报告 | 4.84e-16 |

10 m/s 时，Linear 相对 Cox-Munk、Guérin、TGRS/Hu 的总 MSS 偏差分别为 `+12.25%`、`+13.36%`、`+13.57%`。因此当前结果不能宣称通过全部观测验证。

## 5. 正式输出与测试

- 10 张 PNG：MSS、方向 MSS、各向异性、坡度 PDF、cutoff、谱 dressing、Lie 增量、风因子诊断、海面示例、高阶统计。
- 7 份 CSV：原始、汇总、参考、评估、频谱、cutoff、风因子数据。
- `two_group_validation.mat`：正式运行的可复用结果。
- MATLAB `checkcode`：16 个 `.m` 文件无静态警告。
- 正式运行：400 行数据，U5/U10 各 81920 个坡度样本。
- spectral undressing：开启 1 次迭代的单例测试可执行，Hermitian 残差 `2.82e-16`；该框架仍不是经过文献验证的严格反演。

## 6. 尚未解决的物理问题

1. `direction_only` 是为满足量纲、符号方向和 Hermitian 条件而采用的诊断实现，仍需逐项核对论文第二章原始定义。
2. 当前 Modified Lie 只构造非线性统计与谱 dressing，没有局部 steepness/曲率/加速度破碎判据，也没有翻卷几何。
3. 两组短波 tiles 共享且按独立频带相加，适合 MSS 对照，但没有模拟跨尺度相位耦合。
4. 2-mm optical cutoff 下 Elfouhaily MSS 在高风速时高于三个观测参考；不能通过缩放结果来掩盖，应进一步核对 cutoff、阻力系数和短波参数化。
5. 坡度 PDF、skewness、kurtosis 尚缺对应实测数据，当前只能证明两组统计不同，不能证明 Modified Lie 更真实。

## 7. 必须回查的论文公式

1. Elfouhaily et al. (1997) 中 `alpha_p`、`alpha_m`、方向扩展函数和摩擦速度闭合关系。
2. `thuthesis-example.pdf` 第二章式 (2.30)-(2.33)：`h_tx/h_ty` 的定义、Fourier 正负号、风因子量纲及 Lie 二阶系数。
3. Creamer/Soriano 方法中 target spectrum、dressed spectrum 与 spectral undressing 的严格关系。
4. TGRS generalized slope model 中 total MSS、along/cross MSS、anisotropy 与使用 cutoff 的定义是否和本代码完全一致。

原始 Elfouhaily 论文可从 [IFREMER PDF](https://archimer.ifremer.fr/doc/00091/20226/17877.pdf) 与 [AGU DOI 页面](https://agupubs.onlinelibrary.wiley.com/doi/10.1029/97JC00467) 核对。
