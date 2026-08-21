# 如何证明完整卷浪模型 G1 比已有方法更接近经验规律

## 1. 直接回答

已有文献中确实有海面或破碎浪仿真，但没有一对可以直接替代本文 `G0/G1` 的现成数据组。原因是：

- `G0/G1` 是本文模型内部的消融实验，必须由本文代码在完全相同的输入条件下生成；
- 其他论文的仿真使用不同海谱、网格、随机相位、波陡、水深和雷达参数，直接拿其图或数据与本文 G1 比较不公平；
- 已有模型应作为外部方法基线 `B`，实验数据或经验规律应作为参考 `R`。

因此，能够支撑“G1 不仅优于自己的消融组，而且比已有方法更接近经验规律”的完整设计是：

```text
R：经验规律或实测真值
B：复现的已有方法
G0：本文方法关闭卷浪模块
G1：本文完整卷浪模型
```

文章现有的 `standard Lie transform` 不应删除，它适合作为 `B`。真正缺失的是 `G0`。推荐最终组别为：

| 编号 | 组别 | 回答的问题 |
|---|---|---|
| `R` | Cox-Munk、实测海杂波或破碎浪实验 | 哪个结果更接近真实/经验规律？ |
| `B` | Standard Lie/Creamer 类已有模型 | G1 是否优于已有方法？ |
| `G0` | 本文模型关闭卷浪模块 | 改善是否来自卷浪模块？ |
| `G1` | 本文完整模型 | 完整方法最终达到什么水平？ |

## 2. 检索到的文献里哪些确实有仿真

### 2.1 Rizaev et al.：有海面和 SAR 仿真，但没有显式卷浪

Rizaev et al. 2022 建立了海面与 SAR 成像仿真框架，使用线性海面理论，对五种波浪频谱和多种 SAR 参数进行仿真，并将坡度 PDF 与 Cox-Munk 比较。

- **有无仿真：** 有；
- **是否生成随机海面：** 是；
- **是否显式模拟卷浪/翻卷：** 否；
- **可用于本文的角色：** 线性谱面基线 `B_linear` 或 Cox-Munk 验证流程参考；
- **能否直接作为 G0：** 不能直接使用其结果，但可按照其线性谱面方法在本文代码中复现。

它证明了一种重要的实验范式：使用相同输入条件生成不同海谱模型的表面，然后统一计算 slope PDF/MSS，并对同一个 Cox-Munk 参考计算误差。

### 2.2 Nouguier et al. 的 Choppy Wave Model：有高效非线性海面仿真，但不解析破碎翻卷

Choppy Wave Model（CWM）从线性高斯参考面出发，通过水平坐标位移生成非高斯海面。论文给出二维、三维表达和统计分析，样本海面可通过 FFT 高效生成，并把坡度统计与机载激光观测比较。

- **有无仿真：** 有；
- **是否可以生成二维/三维随机海面：** 是；
- **是否有非线性尖峰和非高斯坡度：** 是；
- **是否解析 overturning/plunging geometry：** 否；
- **可用于本文的角色：** 强于线性谱面的非线性外部基线 `B_CWM`；
- **代码是否可直接取得：** 原论文给出了可复现公式，但本次检索未确认作者提供了官方成套代码。

CWM 与 Creamer 类方法在低频下具有联系，且计算成本较低。如果标准 Lie 已经在本文代码中实现，GRSL 没必要再同时加入 CWM；二者选择一个强基线即可。

### 2.3 Barthelemy et al.：有非破碎/边缘破碎数值算例，但不是雷达海面生成器

Barthelemy et al. 2018 使用完全非线性三维边界元模型，比较 maximally recurrent non-breaking waves 与 marginally breaking waves，并结合观测结果提出破碎起始参数。

- **有无仿真：** 有；
- **是否包含非破碎与破碎两类数值工况：** 是；
- **是否是大范围随机海面生成模型：** 否，主要是聚焦波群和破碎起始研究；
- **是否输出雷达回波：** 否；
- **可用于本文的角色：** 破碎判据、临界工况和局部波峰指标参考 `R_break`；
- **能否直接作为本文 G0/G1：** 不能。

这里的 non-breaking/breaking 是论文研究对象的两类物理工况，不是关闭/开启本文卷浪代码的消融开关。两者名称相似，但实验含义不同。

### 2.4 McAllister et al.：有破碎/非破碎数值组，可提供判据阈值参考

McAllister et al. 2023 对不同谱带宽和谱形的深水波群进行数值研究，区分 breaking 与 non-breaking cases，并比较最大局部坡度与 `B_x` 等破碎起始量。

- **有无仿真：** 有；
- **是否有 breaking/non-breaking 标签：** 有；
- **可用于本文的角色：** 判据阈值、谱带宽敏感性和破碎起始趋势参考；
- **局限：** 仍不是面向大场景雷达回波的三维卷浪生成基线。

### 2.5 HOS-Ocean：有公开代码，可作为高阶非线性参照，但不能直接解析翻卷后的多值自由面

HOS-Ocean 是开源的高阶谱非线性波浪求解器，可生成大尺度非线性开放海域波场，官方提供代码、示例和文档。

- **有无仿真：** 有；
- **是否开源：** 是，GPL；
- **是否适合高阶非线性波场：** 是；
- **是否适合直接生成翻卷后多值自由面、气泡和飞沫：** 通常不适合；
- **可用于本文的角色：** 高保真 pre-breaking/nonlinear baseline 或小规模参考案例；
- **代价：** 接入、参数匹配和计算成本明显高于标准 Lie/CWM。

如果文章篇幅和开发周期有限，不建议把 HOS-Ocean 作为必需基线。标准 Lie 已足以回答“相对已有低成本非线性海面模型是否改善”。HOS-Ocean 更适合后续长文或补充材料。

### 2.6 WAVEWATCH III 与白冠统计模型：有破碎参数化，但不生成局部卷浪网格

WAVEWATCH III 求解谱作用量平衡，并包含 whitecapping dissipation 等源项。相关研究会把模型产生的破碎统计或白冠覆盖率与卫星/现场观测比较。

- **有无仿真：** 有；
- **是否有白冠/破碎耗散参数化：** 有；
- **是否输出逐个卷浪的三维翻卷几何：** 否；
- **可用于本文的角色：** 提供海况、波谱、破碎概率或 whitecap coverage 的统计参考；
- **不适合的角色：** 不能直接替代本文面元级 G1。

## 3. 本文最合理的外部基线 B

### 3.1 GRSL 推荐：只保留一个强外部基线

推荐使用：

```text
B = Standard Lie transform / 原始 Creamer 类实现
```

理由是：

1. 它与本文的理论起点一致，比较最公平；
2. 本文现有代码和文章已经使用 standard Lie，复现成本最低；
3. 它能生成非线性陡峭波面，但没有本文的显式卷浪触发、三维仿射卷曲和遮挡耦合；
4. 与 G0 的差异可以体现本文除卷浪之外的其他修改，与 G1 的差异体现完整方法增益。

推荐四方结构：

| 组别 | 标准 Lie | 本文非卷浪修正 | 卷浪触发/卷曲 | 用途 |
|---|---:|---:|---:|---|
| `B` | 是 | 否 | 否 | 已有方法基线 |
| `G0` | 作为基础 | 是 | 否 | 本文消融组 |
| `G1` | 作为基础 | 是 | 是 | 本文完整组 |

如果 G0 在关闭卷浪后与标准 Lie 完全相同，那么 `B` 与 `G0` 不应重复绘制；此时应直接定义 `G0=B=Standard Lie`，并把实验简化为 `R+B/G0+G1`。只有当 G0 仍保留本文的风向、波矢、平滑或其他修正时，B 和 G0 才是两个不同组。

### 3.2 可选增强：CWM 或线性谱面

若审稿人要求更多方法比较，可按优先级添加：

1. `B_CWM`：低成本非线性海面强基线；
2. `B_linear`：Elfouhaily 谱 + FFT 线性高斯海面弱基线；
3. `B_HOS`：高阶非线性高成本基线，仅用于少量小场景。

不建议同时塞入大量基线。对于 Letter，一条可复现的强基线、一个严格消融组和一个完整组，比多条条件不一致的曲线更有说服力。

## 4. 如何定量证明“G1 比别人更像经验规律”

### 4.1 必须让所有方法面对同一个 R

对于每个风速、风向和随机种子，B、G0、G1 必须使用：

- 同一海浪谱和方向谱；
- 同一波数截断范围；
- 同一空间网格和仿真区域；
- 同一随机相位；
- 同一时间长度和采样方法；
- 同一坡度计算和边界处理；
- 雷达验证中使用同一散射模型和雷达参数。

然后分别计算它们到参考 R 的距离，而不是只观察曲线视觉上是否接近。

### 4.2 Cox-Munk 的误差定义

对方法 `m in {B,G0,G1}` 和风速集合 `U={U1,...,UK}`，分别计算顺风、横风和总 MSS：

```text
e_m,d(Uk) = |MSS_m,d(Uk) - MSS_CM,d(Uk)| / MSS_CM,d(Uk)
```

其中 `d` 为 upwind、crosswind 或 total。再汇总为：

```text
MAPE_m,d = (1/K) * sum_k e_m,d(Uk)

NRMSE_m,d = sqrt[(1/K) * sum_k (MSS_m,d(Uk)-MSS_CM,d(Uk))^2]
             / mean_k MSS_CM,d(Uk)
```

如果 Cox-Munk 以置信区间或上下界给出，还应计算：

```text
Coverage_m = 落入经验区间的风速点数 / K
```

“G1 更像”的最低定量条件是：

```text
NRMSE_G1 < NRMSE_G0
NRMSE_G1 < NRMSE_B
Coverage_G1 >= Coverage_G0 and Coverage_G1 >= Coverage_B
```

相对已有方法的改善百分比可以写为：

```text
Improvement_vs_B = 100% * (NRMSE_B - NRMSE_G1) / NRMSE_B

Improvement_vs_G0 = 100% * (NRMSE_G0 - NRMSE_G1) / NRMSE_G0
```

例如，不能只写“G1 曲线更接近 Cox-Munk”，而应写成：

```text
Across the tested wind-speed range, G1 reduced the total-MSS NRMSE by X% relative
to the standard Lie baseline and by Y% relative to the no-breaking ablation.
```

### 4.3 不要只比较总 MSS

卷浪是局部、间歇性和重尾现象，总 MSS 可能对它不敏感。建议 Cox-Munk 图至少包含：

- upwind MSS；
- crosswind MSS；
- total MSS；
- slope PDF 或互补累积分布 CCDF；
- 可选：skewness 和 kurtosis。

对坡度 PDF 可计算：

- Wasserstein distance；
- Jensen-Shannon divergence；
- 尾部概率误差，例如 `P(|s| > s0)`；
- 高分位坡度误差，例如 P99。

CWM 论文的价值正在于它不只比较 MSS，而是检查非高斯坡度和过量峰度是否更接近激光观测。本文若想体现卷浪作用，坡度 PDF 尾部通常比单个 MSS 数值更有辨识力。

### 4.4 统计显著性

每个风速使用相同的 `N` 组成对随机种子生成 B、G0、G1。对每个种子计算误差后，报告：

- 平均误差与 95% bootstrap 置信区间；
- `E_G1-E_B` 和 `E_G1-E_G0` 的配对置信区间；
- 可选：配对 Wilcoxon 检验；
- 至少报告效应量，不要只报告 p 值。

如果 `E_G1-E_B` 的置信区间整体小于零，才能更有把握地写 G1 显著更接近参考。

## 5. 对卷浪经验规律，应该比较什么

### 5.1 不能用 Cox-Munk 直接证明卷浪正确

Cox-Munk 可用于全局坡度统计，但不能证明破碎触发、翻卷时刻和卷浪几何正确。对于卷浪，应另外选择参考规律。

可选参考包括：

| 参考规律/数据 | G1 输出量 | 可比较指标 |
|---|---|---|
| `B_x` 破碎起始阈值 | 波峰处能量/粒子速度与波峰速度之比 | 阈值命中率、起始时刻误差 |
| breaking occurrence 随风速/波陡变化 | 满足破碎条件的波峰比例 | 曲线 NRMSE、单调趋势、置信区间 |
| whitecap coverage `W(U10)` | breaking area ratio 或泡沫覆盖率 | MAPE/NRMSE、区间覆盖率 |
| 实验自由面剖面 | 卷浪波峰轮廓 | 轮廓 RMSE、曲率、前缘坡度、翻卷长度 |
| 实测雷达重尾/海尖峰 | G1 仿真回波 | KS/Wasserstein、P99、sea-spike rate |

### 5.2 Whitecap coverage 不能直接等同于卷浪面积

如果本文不模拟泡沫寿命、气泡和白冠衰减，就不能把卷浪几何区域面积直接称为 whitecap coverage。可以将其称为 `breaking-area proxy`，并说明需要一个从几何触发区到可见泡沫区的映射。

更稳妥的做法是：

- 用观测 `W(U10)` 验证变化趋势和数量级；
- 不强求每个时刻逐像素一致；
- 将 whitecap 结果作为辅助验证；
- 把自由面剖面或雷达 sea-spike 作为与本文模型更直接的主指标。

### 5.3 判据若被直接写入 G1，不能再用同一阈值作独立验证

如果 G1 按 `B_x > 0.85` 触发，再展示所有触发点都满足 `B_x > 0.85`，只能证明代码实现正确，这是循环验证。

独立验证至少需要以下之一：

- 用观测标签检验判据的误报和漏报；
- 用未参与阈值设定的波槽案例检验 onset time；
- 用另一种独立规律，如波峰轮廓、whitecap coverage 或回波尾部检验结果；
- 与一个竞争判据比较，例如简单坡度阈值 vs `B_x` 判据。

如果本文没有提出新破碎判据，就不必证明判据优于所有已有判据。只需说明采用了已验证判据，并重点证明本文的低成本三维卷曲构造比 standard Lie 更能复现实测几何或雷达统计。

## 6. 推荐的三套实验

### 6.1 实验 A：整体海面统计

```text
R = Cox-Munk slope statistics
B = Standard Lie
G0 = Proposed without breaking
G1 = Proposed full
```

报告：upwind/crosswind/total MSS、slope PDF、NRMSE、区间覆盖率和改善百分比。

该实验可以支持：

> G1 在加入局部卷浪几何后仍保持合理的全局坡度统计，并在所测风速范围内比 standard Lie 和 G0 更接近 Cox-Munk。

前提是数值结果确实满足上述误差排序。如果 G1 只与 G0 相当，应写“preserves”而不是“improves”。

### 6.2 实验 B：卷浪物理规律

推荐至少选择一项独立参考：

```text
R_break = 实验 breaking/non-breaking 标签、波面剖面或 W(U10)
B_criterion = 简单几何坡度阈值或已有运动学判据
G1_criterion = 本文实际采用的判据/完整模型
```

如果本文判据并非创新点，可以不设置竞争判据，只比较 G1 与 `R_break`，并把 G0 用于展示无卷浪时局部几何指标为零或显著不足。

### 6.3 实验 C：雷达回波真实性

```text
R_radar = NAV X-band 实测数据
B = Standard Lie surface + 相同雷达散射模型
G0 = Proposed no-breaking surface + 相同散射模型
G1 = Proposed full surface + 相同散射模型
```

报告：KS/Wasserstein、P99/P99.9、tail error、sea-spike rate、ACF 和 RTI。该实验最能证明卷浪模块对雷达仿真的实际价值。

## 7. 如何防止“为了贴近经验曲线而调参”的质疑

如果卷曲强度、触发阈值或坡度修正系数根据 Cox-Munk/实测数据选择，再用同一批工况验证，会被认为是拟合而非泛化。

建议：

1. 用一部分风速或海况调参，例如低/中风速；
2. 将另一部分风速或独立观测时段作为 hold-out 验证；
3. 所有 B/G0/G1 使用同一验证工况；
4. 在验证集上一次性报告全部指标；
5. 做卷曲系数和阈值的敏感性分析，证明结论不依赖单一手工参数。

若参数全部来自独立文献，可以直接固定参数并声明无数据驱动调参。

## 8. 最终建议

对于当前 GRSL 文章，最平衡的设计不是寻找别人现成的 G0/G1，而是：

```text
外部已有方法：B = Standard Lie
本文消融方法：G0 = Proposed w/o breaking
本文完整方法：G1 = Proposed full
经验/实测参照：R = Cox-Munk / breaking observations / NAV radar data
```

其中：

- Cox-Munk 图证明 G1 的整体坡度统计不劣于并可能优于已有方法；
- 卷浪独立指标证明 G1 的局部破碎行为不是视觉修饰；
- NAV 分布和 RTI 证明 G1 对雷达回波真实性的提升；
- `G1 vs G0` 负责归因，`G1 vs B` 负责比较已有方法，`G1 vs R` 负责证明真实性。

这三种比较不能互相替代。

## 9. 关键文献与可用资源

1. Rizaev, I., et al., “Modeling and SAR imaging of the sea surface: A review of the state-of-the-art with simulations,” *ISPRS Journal of Photogrammetry and Remote Sensing*, 2022. https://doi.org/10.1016/j.isprsjprs.2022.02.017
2. Nouguier, F., Guérin, C.-A., and Chapron, B., “Choppy wave model for nonlinear gravity waves,” *Journal of Geophysical Research: Oceans*, 2009. https://doi.org/10.1029/2008JC004984
3. Barthelemy, X., et al., “On a unified breaking onset threshold for gravity waves in deep and intermediate depth water,” *Journal of Fluid Mechanics*, 2018. https://doi.org/10.1017/jfm.2018.93
4. McAllister, M. L., et al., “Influence of spectral bandwidth and shape on deep-water wave breaking onset,” *Journal of Fluid Mechanics*, 2023. https://doi.org/10.1017/jfm.2023.766
5. HOS-Ocean official documentation and source repository: https://lheea.gitlab.io/HOS-Ocean/index.html
6. NOAA WAVEWATCH III official repository: https://github.com/NOAA-EMC/WW3
7. Leckler, F., et al., “Dissipation source terms and whitecap statistics,” *Ocean Modelling*, 2013. https://doi.org/10.1016/j.ocemod.2013.03.007
8. Callaghan, A. H., et al., “Comparing Estimates of Whitecap Coverage From a Spectral Wave Model With Oceanic Observations,” *Geophysical Research Letters*, 2025. https://doi.org/10.1029/2024GL112996

