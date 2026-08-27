# Elfouhaily / Modified Lie 两组海面验证

这是从零重构的两组验证实现，不调用此前四组 Cox-Munk 脚本，也不使用预置曲线代替随机海面仿真。代码面向 MATLAB R2022b+，不依赖额外工具箱。

## 验证组

1. `Linear Elfouhaily`：从方向 Elfouhaily 二维波数谱采样，强制 Hermitian 共轭后反变换得到线性海面。
2. `Modified Lie Nonlinear`：使用相同随机相位，在主波频带对线性海面施加论文第二章式 (2.31)-(2.33) 对应的二阶 Modified Lie 变换。

当前代码没有局部破碎判据、翻卷几何或白沫模型，因此第二组不能命名为 `Breaking`。它验证的是 Modified Lie 非线性对二阶谱、坡度 PDF 和高阶统计的影响。

## 关键实现

- Elfouhaily 长波系数：`alpha_p = 0.006*sqrt(Omega)`。
- 默认阻力系数：`Cd=(0.8+0.065*U10)*1e-3`，并保留固定阻力系数作为兼容诊断。
- `h_tx`、`h_ty` 按二维 Riesz 分量实现，其 Fourier 乘子为 `-i*k_x/k`、`-i*k_y/k`，不包含额外 `k` 放大。
- 默认风因子模式为 `direction_only`：使用有符号、无量纲的方向乘子，并保持 Fourier 相位与 Hermitian 对称。
- 旧 `current` 模式把物理量 `U10` 直接乘入 Lie 项，量纲不闭合，仅作为失败对照。
- 主波网格使用 `dk=kp/12`。未解析短波采用独立 octave tiles 积分至 `pi*1000 rad/m`，总坡度方差按独立频带相加。
- Linear 与 Modified Lie 使用配对随机 realization；短波 tiles 完全共享，因此两组差异只来自主波频带 Lie 变换。
- 提供默认关闭的迭代 spectral undressing 诊断框架；当前不能把它当作已验证的严格反演算法。

## 验证内容

默认风速为 `U10=1:1:10 m/s`，每个风速 20 个配对 realization。对照包括：

- Cox-Munk 顺风、横风和总 MSS；
- Guérin IASI 在 3-10 m/s 的方向 MSS；
- TGRS/Hu 总 MSS 和各向异性经验规律；
- 当前实现使用的 Elfouhaily 谱数值积分。

代码另外检查频域/空域 MSS 一致性、Hermitian 残差、Riesz 能量恒等式、谱 dressing、cutoff 敏感性、方向 MSS、坡度 PDF，以及 elevation/slope 的 skewness 和 excess kurtosis。

## 运行

```matlab
cd('E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\CoxMunk\ThesisTwoGroup')
run_thesis_two_group_validation
```

结果写入 `output`：

- `01_total_mss.png` 至 `10_high_order_statistics.png`；
- `two_group_raw.csv`、`two_group_summary.csv`、`two_group_reference.csv`；
- `two_group_assessment.csv`、`spectral_diagnostics.csv`；
- `cutoff_sensitivity.csv`、`wind_factor_diagnostics.csv`；
- `two_group_validation.mat`。

父目录下自动生成 `two_group_validation_results.md`，定量回答验证是否通过、误差来自哪些波数段、Lie 增量与方向性、高阶统计变化及剩余物理问题。
