# 卷浪形态与 RCS 验证的文献参照设计

## 1. 核心结论

卷浪的尺度、前坡、后坡、波峰曲率和不对称程度并不存在一组适用于所有海况的固定真值。它们会随波陡、谱带宽、方向展宽、波龄、破碎类型和破碎阶段变化。因此，本文不应把某一张实验剖面作为唯一模板，也不应因为模型参数可以手动指定，就逐参数把仿真调到与一条参考曲线重合。

正确的验证对象是：

```text
匹配海况和破碎阶段下的无量纲形态分布
+ 形态参数之间的联合关系
+ 从弱破碎到强破碎的变化趋势
+ 形态变化对应的 RCS/Doppler 变化
```

推荐采用三层参照：

1. `R_onset`：McAllister et al. 2024，验证破碎开始前的局部坡度和方向展宽关系；
2. `R_profile`：Erinin et al. 2023，验证弱、中、强 plunging breaker 从 jet formation 到 jet impact 的二维卷浪剖面；
3. `R_planform`：Stringari et al. 2021 的黑海现场统计，验证三维破碎斑块的尺度、面积、长宽比和持续时间。

RCS 阶段再增加：

4. `R_radar`：Sletten et al. 2003 的同步高速光学与 X 波段低擦地角雷达实验，验证不同破碎阶段对应的 RCS 与 Doppler 特征。

## 2. 为什么不能使用一组固定形态参数

McAllister et al. 2024 的三维波浪实验表明，破碎起始陡度随方向展宽显著变化，方向展宽最大的工况，其破碎起始陡度可达到单向波的约两倍。该文进一步用方向展宽参数 `Omega_0` 和 `Omega_1` 关联破碎起始时的最大局部坡度和整体谱陡度。这意味着，即使波高相似，不同方向谱也可能产生不同的极限坡度和卷浪形式。

She et al. 1994 也发现，破碎波高、波峰高程、前坡陡度和垂直不对称因子会随方向展宽明显变化，而后坡陡度和水平不对称受影响相对较小。Bonmarin 1989 的深水破碎波实验则表明，卷浪形成过程中的主要变形来自前坡持续增陡，后坡陡度变化相对有限。

所以本文要证明的不是“所有卷浪都具有相同曲率或坡度”，而是：

```text
给定波陡、方向展宽和破碎强度后，
模型生成的形态落在实验分布内，
并复现实验中参数之间的变化关系。
```

## 3. 最推荐的形态主参照：Erinin et al. 2023

### 3.1 为什么它最适合当前 Curl 模块

Erinin et al. 在 JFM 2023 中使用 cinematic laser-induced fluorescence 测量了三种机械生成的深水 plunging breaker，每种强度重复 10 次，并给出了从 jet formation 到 jet impact 的时变自由面剖面、均值和标准差。

这与当前 Curl 模块的局部前伸、翻卷和 jet 形态最接近。该文不是只给一张效果图，而是明确区分：

- weak、moderate、strong 三个破碎强度；
- jet formation 时刻；
- jet impact 时刻；
- 破碎后的随机波动区域。

论文表 2 提供了可直接作为参照的量，包括：

| 参数 | weak | moderate | strong | 适合验证什么 |
|---|---:|---:|---:|---|
| jet formation 时 `H/L` | 0.166 | 0.185 | 0.193 | 总体波陡随强度增加 |
| jet impact 时 `H/L` | 0.148 | 0.163 | 0.171 | 撞击阶段总体波形 |
| 撞击处前表面角度 | 65.3 deg | 67.6 deg | 66.3 deg | 卷唇前坡 |
| jet 空腔水平尺度 `r_x` | 57.4 mm | 73.5 mm | 81.5 mm | 前伸尺度 |
| jet 空腔垂直尺度 `r_y` | 53.0 mm | 65.0 mm | 69.4 mm | 下卷尺度 |
| jet 下方面积 `Q` | 2222 mm2 | 3457 mm2 | 4134 mm2 | 卷浪强度/空腔尺度 |
| formation 到 impact 时间 | 148.9 ms | 166.8 ms | 169.7 ms | 动态持续时间 |

这些绝对数值对应实验水槽尺度，不能直接套到海面仿真中。比较时应使用其名义波长 `lambda_0`、波高 `H` 或周期 `T_0` 无量纲化，例如：

```text
r_x/lambda_0, r_y/lambda_0, Q/lambda_0^2,
k_p H, k_p r_x, k_p r_y, (t_i-t_f)/T_0
```

### 3.2 当前 Curl 模块应从中提取的指标

建议把 current Curl 的参数输出转换为以下观测量，而不是直接验证 `forwardGain`、`pivotDepth` 或 `curlMultiplier`：

1. 波高与特征长度之比 `H/L`；
2. 前坡和后坡的局部最大斜率；
3. 波峰或卷唇的曲率；
4. 水平和垂直空腔尺度 `r_x/r_y`；
5. 卷唇下方封闭或半封闭面积 `Q`；
6. 从首次垂直切线到最大前伸/撞击状态的无量纲持续时间；
7. 整条归一化剖面与实验均值剖面的距离。

波面一旦翻卷，就不再能写成单值函数 `z=eta(x)`。因此曲率应在参数曲线上计算：

```text
kappa = abs(x' z'' - z' x'') / (x'^2 + z'^2)^(3/2)
```

并比较无量纲曲率 `kappa/k_p` 或 `kappa*lambda_0`。前坡、后坡和曲率的计算区间也必须以 crest point、jet tip、相邻 trough/zero crossing 等几何特征定义，不能使用随图像范围变化的任意窗口。

## 4. 三维尺度参照：Stringari/Guimarães 黑海数据

Stringari et al. 2021 使用 Guimarães 已分类的黑海主动破碎事件，统计了破碎持续时间、破碎面积、拟合椭圆的长轴和短轴以及 `Lambda(c)`。主要可用关系包括：

- `T_br/T_p` 的均值约 0.13、众数约 0.12；
- 破碎面积呈重尾/Pareto 型分布，大事件少见；
- 斑块长短轴比均值约 2.4-2.5、众数约 1.8-1.9；
- 面积缩放关系与 Duncan 经验量级一致；
- 破碎斑块面积随事件时间近似二次增长。

这组数据适合验证当前三维卷浪在波峰方向上的长度、宽度、投影面积和持续时间，但它识别的是主动白沫/破碎斑块，不是完整自由面翻卷拓扑。因此：

- 可以用它验证 `crestLength`、卷浪作用宽度、投影面积和长宽比的分布；
- 不能用它直接验证前坡、后坡、波峰曲率或卷唇空腔。

这一区分很重要。把白沫斑块面积当成自由面卷唇面积会造成物理含义错位。

## 5. 破碎起始参照：McAllister et al. 2024

McAllister et al. 2024 适合验证“哪些波峰应进入 Curl”，而不是验证卷浪后的完整形态。其开放数据位于 Zenodo，可直接获得实验矩阵和拟合参数。

推荐比较：

- 方向展宽指标 `Omega_0` 或 `Omega_1`；
- 破碎起始时最大局部坡度 `|grad eta|*`；
- 破碎起始时整体谱陡度 `S_M*`；
- breaking/non-breaking 分类。

该文指出二维行进波的局部坡度参考约为 `tan(30 deg)`，随着三维方向展宽增加，起始坡度可向 standing-wave 极限提高。当前 Curl 仅按高度阈值选峰，因此现阶段可以先做形态验证，但不能把选峰结果写成“破碎起始预测准确”。

## 6. 参数可指定时，怎样避免验证变成调参自证

当前 `forwardGain`、`verticalAngleRatio`、`pivotDepth`、`curlMultiplier` 和 `crestLength` 都可指定。如果每个参考样本都单独调整这些参数，直到仿真曲线与它吻合，那么只能证明模型有拟合能力，不能证明它有预测或生成能力。

建议采用下面的规则：

### 6.1 参数与观测量分离

```text
模型输入参数：forwardGain, pivotDepth, curlMultiplier, crestLength ...
验证输出参数：H/L, front slope, rear slope, curvature, r_x, r_y, Q ...
```

论文只比较输出观测量，不把内部控制参数与实验测量量一一等同。

### 6.2 三个强度组，不需要无限工况

设置：

```text
C1：weak plunging
C2：moderate plunging
C3：strong plunging
```

每组给出一套固定的参数生成规则和多个随机背景海面。参数规则可由波陡或破碎强度变量连续驱动，而不是为每个样本手工指定。

### 6.3 校准与验证分离

可选做法：

- 用 weak 和 strong 两组确定参数映射；
- 不再调参，预测 moderate 组；
- 或做 leave-one-strength-out，轮流留出一组验证。

至少应有一个未参与调参的强度组。否则表格中的误差只是拟合误差。

### 6.4 比较联合关系，不只比较单项范围

最有说服力的关系是：

```text
破碎增强时：H/L 上升，r_x 和 r_y 增大，Q 增大；
前坡显著增陡，而后坡变化较小；
卷浪作用面积呈重尾分布，极端大卷浪较少；
三维长宽比保持在现场观测的主要概率区间。
```

即使单个参数都落在文献范围内，如果这些变量之间没有正确关联，仍不能说明形态真实。

## 7. 推荐的最小卷浪形态实验

正文只需要一个形态实验，包含三种强度：

```text
Reference 1：Erinin 2023 weak/moderate/strong 归一化剖面和表 2
Reference 2：Stringari 2021 现场斑块尺度分布
G0：相同非线性背景，不施加 Curl
G1：weak/moderate/strong Curl
```

建议输出：

1. 一张图：三个强度下的归一化中心剖面，叠加 Erinin 实验均值/误差带；
2. 一张图：`H/L`、前坡、后坡、曲率、`r_x/r_y`、`Q` 的归一化比较；
3. 一张图或小表：三维长宽比、投影面积和持续时间与黑海分布比较；
4. 一个总指标表：profile distance、Wasserstein distance 和趋势是否一致。

不建议在正文中再加入大量互相重复的几何量。核心量可压缩为：

```text
H/L + front/rear slope ratio + dimensionless crest curvature
+ r_x/r_y + Q/lambda_p^2 + 3D aspect ratio
```

## 8. 从形态验证进入 RCS 验证

Sletten et al. 2003 同步测量了 spilling/plunging breaker 的高速光学剖面和低擦地角 X 波段回波，实验波长约 0.8 m，雷达为 6-12 GHz、约 4 cm 距离分辨率、约 12 deg 擦地角。这篇文献适合作为形态到散射的桥梁。

其主要可比规律是：

- spilling breaker 初始 crest bulge 贡献超过 90% 的 HH 回波能量、约 60% 的 VV 能量；
- plunging breaker 的回波在 jet formation、jet impact、splash-up 和 post-breaking 阶段更复杂；
- plunging breaker 的 Doppler 展宽明显大于 spilling breaker；
- 强散射中心的迁移速度与波峰/破碎结构速度相关。

RCS 验证应按阶段组织：

```text
pre-breaking
-> jet formation
-> maximum overturning / jet impact
-> splash-up / post-breaking
```

对每个阶段比较：

- 归一化总 RCS 或等效散射面积；
- HH/VV 极化比；
- 峰值出现时刻；
- Doppler centroid 和 bandwidth；
- 强散射中心相对波峰的空间位置。

如果仿真雷达频率、极化、擦地角和波尺度不能与实验完全对齐，就只能比较归一化阶段规律和趋势，不能直接比较绝对 RCS 数值。绝对 RCS 需要严格复现实验几何，并补充破碎产生的厘米级粗糙度；仅有光滑卷唇几何通常不足以复现全部实测回波。

## 9. 最终建议

当前论文的卷浪形态验证应以 Erinin 2023 为主，以 Stringari/Guimarães 的现场尺度统计为辅，以 McAllister 2024 约束破碎起始。这样既允许模型参数灵活变化，又避免任意调参：模型生成的是一个条件分布，文献提供的是该条件下的实验分布和趋势。

最关键的判据不是“某一条卷浪曲线完全重合”，而是：

```text
未参与调参的破碎强度下，
G1 的归一化剖面、形态联合关系和分布
比 G0 更接近实验参照，
并使后续 RCS 的阶段变化更接近同步雷达实验。
```

## 10. 主要文献与数据

1. McAllister, M. L., et al. Three-dimensional wave breaking. Nature 633, 601-607 (2024). https://doi.org/10.1038/s41586-024-07886-z
2. McAllister 2024 experimental data. Zenodo. https://doi.org/10.5281/zenodo.10818626
3. Erinin, M. A., Liu, X., Wang, S. D., and Duncan, J. H. Plunging breakers. Part 1. Analysis of an ensemble of wave profiles. Journal of Fluid Mechanics 967, A35 (2023). https://doi.org/10.1017/jfm.2023.379
4. Stringari, C. E., et al. Deep neural networks for active wave breaking classification. Scientific Reports 11, 3604 (2021). https://doi.org/10.1038/s41598-021-83188-y
5. Bonmarin, P. Geometric properties of deep-water breaking waves. Journal of Fluid Mechanics 209, 405-433 (1989). https://doi.org/10.1017/S0022112089003162
6. She, K., Greated, C. A., and Easson, W. J. Experimental study of three-dimensional wave breaking. Journal of Waterway, Port, Coastal, and Ocean Engineering 120, 20-36 (1994). https://doi.org/10.1061/(ASCE)0733-950X(1994)120:1(20)
7. Sletten, M. A., et al. Radar investigations of breaking water waves at low grazing angles with simultaneous high-speed optical imagery. Radio Science 38 (2003). https://doi.org/10.1029/2002RS002716
8. Ericson, E. A., et al. Radar backscatter from stationary breaking waves. Journal of Geophysical Research: Oceans 104 (1999). https://doi.org/10.1029/1999JC900223
9. Stresser, M., Seemann, J., Carrasco, R., et al. On the interpretation of coherent marine radar backscatter from surf zone waves. IEEE Transactions on Geoscience and Remote Sensing 60 (2022). https://doi.org/10.1109/TGRS.2021.3103417

