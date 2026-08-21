# 近年海面与卷浪文献能否替代 Standard Lie/CWM 作为 Baseline

## 1. 结论先行

这五篇论文都可以进入本文的验证体系，但**不能全部称为海面生成 baseline**。它们分别解决波谱、雷达杂波统计和破碎判据问题，输出层级不同。

建议采用以下命名，避免审稿人质疑比较对象不等价：

```text
B_surface：输入相同环境条件，能够输出可比较海面几何的已有方法
B_echo：能够输出可比较复雷达回波或 RTI 的已有方法
R_spectrum：波谱、MSS 和 RCS 的外部参考
R_break：破碎发生与否、破碎概率或白冠统计的实验参考
R_meas：最终实测海面或雷达数据
```

对当前五篇附件的最终裁决如下。

| 文献 | 可否作海面几何 baseline | 可否作雷达回波 baseline | 最合适角色 | 结论 |
|---|---:|---:|---|---|
| Ding et al., Sensors 2020, STCPM | 否 | 是 | `B_echo-stat` | 可作为使用实测参数拟合的统计回波上界，但不能验证三维海面或卷浪几何 |
| Angelliaume et al., Remote Sensing 2019 | 否 | 有限 | `R_distribution` | 适合规定分布候选和拟合指标；论文主要做模型拟合评价，并非完整 RTI 生成器 |
| Ryabkova et al., JGR Oceans 2019 | 仅波谱层 | 否 | `B_spectrum/R_spectrum` | 五篇中唯一可直接成为“波谱模型 baseline”的文献，但不能代替非线性几何或卷浪模型 |
| Varing et al., Coastal Engineering 2021 | 否 | 否 | `R_break-kinematic` | 可提供浅水破碎运动学判据；本论文主要是 FNPF 数值试验，不是独立实测基准 |
| Vargas-Magana et al., JGR Oceans 2026 | 否 | 否 | `R_break-dynamic` | 是强实测破碎诊断参考，但属于近岸浅水、粒子加速度判据，不能直接当开放海域几何 baseline |

因此，若认为 Standard Lie 和 CWM 年代过早，最合理的更新方式不是把上述五篇统称为 baseline，而是：

```text
现代主 baseline：2022 Random-Stokes 物理海面与岸基雷达全链路模型
高保真小场景参照：2023 HOSM with breaking model / HOS-Ocean v2.1
波谱参考：Ryabkova2019 modified spectrum
三维破碎实验参考：McAllister2024
开放海域破碎统计参考：Derakhti2024
实测回波：NAV 或 IPIX
```

如果 GRSL 正文只能容纳一个外部新方法，建议选 **2022 Random-Stokes 全链路模型**；如果还能放一个小规模数值参照，再加入 **2023 HOSM with breaking model**。Standard Lie/CWM 可移入 Related Work 或补充材料，不必继续占据正文主 baseline 位置。

## 2. 五篇附件的逐篇判断

### 2.1 Ding et al. 2020：可作统计回波 baseline，不能作海面 baseline

论文题目为 *A Novel Reconstruction Method of K-Distributed Sea Clutter with Spatial-Temporal Correlation*，提出 STCPM。它把海杂波表示为纹理与散斑的复合 K 分布过程：纹理同时具有空间和时间相关性，散斑具有时间相关及实、虚部互相关。

论文使用 2013 年辽宁葫芦岛实测毫米波相干雷达数据：

- 垂直极化，擦地角 8 度；
- PRF 500 Hz，带宽 100 MHz；
- 原始记录含 4000 个距离单元，每单元 40000 脉冲、80 s；
- 选取中间 400 个距离单元建模；
- 仿真生成 400 距离单元乘 5000 脉冲的数据，并对 1000 次试验取平均。

对照组为：

```text
TCM：只重建时间相关性
SCM：只重建空间相关性
Filter method：二维相关纹理滤波法
STCPM：同时重建空间和时间相关性
Real：葫芦岛实测杂波
```

指标包括幅度 PDF/CDF、RMSE、KS 统计量、时间/空间相关系数和演化 Doppler 谱。其表 3 报告 STCPM 的 RMSE 为 `3.9908e-6`、KS 为 `0.0081`，均优于 TCM 和 SCM。

**可用方式：** 把 STCPM 作为 `B_echo-stat`，与 G0/G1 的回波比较 PDF/CDF、相关性和 Doppler。

**必须声明的公平性限制：** STCPM 的目标相关函数和分布参数直接从同一实测数据提取，它天然拥有更多实测先验。因此它应被称为“数据拟合上界”，不能因其误差更小就认为其物理海面更真实。

### 2.2 Angelliaume et al. 2019：适合定义分布验证协议

论文题目为 *Modeling the Amplitude Distribution of Radar Sea Clutter*。它比较四类幅度模型：

```text
KN：K distribution + noise
PN：Pareto distribution + noise
KR：K + Rayleigh
3MD：trimodal discrete distribution
```

数据覆盖三套雷达：

| 数据集 | 频段与平台 | 关键范围 |
|---|---|---|
| NetRAD | S 波段地基单/双基地 | 0.6-1.5 度擦地角，风速约 10-12 m/s，每组超过 1e6 样本 |
| INGARA | X 波段机载圆周聚束 | 15-45 度擦地角、360 度方位、HH/VV，波高约 0.25-4.9 m |
| SETHI | L/X 波段机载 SAR | 10-45 度擦地角，0.5-1 m 分辨率，多海况和多极化 |

它设置了两个互补指标：

- Bhattacharyya distance：衡量整个分布主体的误差；
- threshold error：在 `CCDF = 1e-4` 处衡量分布尾部误差。

结果显示 KR 和 3MD 对整体分布均较好；3MD 的尾部拟合最稳定，但参数更多，而且论文明确指出其纹理离散化不能描述空间和长时间相关性，因此不适合直接充当完整杂波仿真器。

**可用方式：** 将这篇论文作为 `R_distribution`，直接采用“主体距离 + 尾部误差”的验证逻辑。对卷浪雷达回波而言，尾部指标尤其重要，因为海尖峰差异可能在普通 PDF 主体中被淹没。

**不建议：** 把 3MD 单独叫作海面 baseline，或只画 PDF/CDF 后凭目视宣称更接近实测。

### 2.3 Ryabkova et al. 2019：可以成为波谱 baseline

论文题目为 *A Review of Wave Spectrum Models as Applied to the Problem of Radar Probing of the Sea Surface*。它不仅是综述，还提出了修正的 Karaev/Ryabkova 波谱，并与 Elfouhaily1997、Kudryavtsev2013、Hwang2015 和 Karaev2000 比较。

其验证链条值得直接采用：

```text
波谱模型
  -> 积分得到顺风/横风 MSS
  -> 与 Cox-Munk 及 Breon-Henriot 观测关系比较
  -> 计算 C/Ku/L/X 波段 RCS
  -> 与对应 GMF 比较风速和方位趋势
```

作者指出所有既有波谱都不能同时满足全部条件；修正波谱在短波重力-毛细波段、MSS 和 RCS 趋势方面改善，并避免部分旧模型随风速变化出现不连续“kink”。模型还支持混合风浪与涌浪。

它可以定义为：

```text
B_spectrum = Ryabkova2019 modified spectrum
```

但实验必须拆成两层：

1. 波谱实验比较不同谱模型的 MSS/RCS；
2. 几何与卷浪实验固定同一个目标波谱，只更换表面生成方法。

若在同一张表里同时改变波谱和非线性变换，就无法判断改进来自更好的输入谱，还是来自 G1 的卷浪拓扑。

### 2.4 Varing et al. 2021：浅水运动学判据参考，不是实测 baseline

论文题目为 *A New Definition of the Kinematic Breaking Onset Criterion Validated with Solitary and Quasi-Regular Waves in Shallow Water*。它使用二维全非线性势流数值波槽，模拟孤立波和准规则波在斜坡、潜堤上的传播，包含 breaking 与 nearly-breaking 两类数值工况。

比较的是：

```text
传统判据：u_c / c
新判据：||u||_m / c
```

其中 `u_c` 是波峰处水平粒子速度，`||u||_m` 是波峰前表面最大流速，`c` 是波峰传播速度。论文发现 `||u||_m/c` 在破碎起始时更接近常数约 1；汇总算例中，以经验中心值 0.95 和 1.05 计算的 RMS 误差分别约为 6.3% 和 3.2%。

需要注意：本文的主要证据是 FNPF 数值模拟。虽然数值波槽及部分地形配置有既往实验验证基础，但这篇论文自身不能替代独立实测破碎数据。

**可用方式：** 若 G1 能输出表面粒子速度和波峰速度，可把 `||u||_m/c` 作为浅水辅助判据。

**不适用处：** 当前研究若是深水开放海域、三维方向谱和风生卷浪，该阈值不能未经验证直接作为唯一触发规则。

### 2.5 Vargas-Magana et al. 2026：强实测诊断，但存在场景与可观测量错位

论文题目为 *Lagrangian Acceleration as a Diagnostic for Wave Breaking in the Nearshore Zone*。它使用德国 Sylt 岛 2019 年近岸现场试验：两台同步相机立体成像，跟踪海面橙色示踪物，并由分段高阶多项式拟合轨迹后求垂向二阶导数。

数据与结果为：

- 51 条示踪轨迹；
- 99 个波峰事件；
- 人工视频标签中 14 个 breaking、85 个 non-breaking；
- 判据为波峰附近向下拉格朗日加速度达到或越过 `-0.5g`；
- TP=14、FN=0、FP=4、TN=81；
- 准确率约 96%，F1=0.875。

这篇论文非常适合定义 `R_break-dynamic`，因为它同时提供实测轨迹、人工可视标签和混淆矩阵。但它不能直接成为 G1 的生成 baseline：

- 数据属于近岸浅水 spilling/plunging 破碎；
- collapsing、surging 和 micro-breaking 被排除；
- 判据需要粒子轨迹与加速度，而单纯的高度场或仿射网格未必能提供相同物理量；
- 它验证“是否破碎”，并不验证翻卷面几何、泡沫或雷达回波强度。

## 3. 更适合替代旧方法的近年文献

### 3.1 现代主 baseline：Random-Stokes 全链路模型，Remote Sensing 2022

*The Dynamic Sea Clutter Simulation of Shore-Based Radar Based on Stokes Waves* 是与本文目标最接近的近年可比方法。该方法包含：

- 随机 Stokes 非线性动态海面；
- 风速与非线性参数关联；
- 破碎浪数量和位置部署；
- 面元散射、传播损耗、Doppler 和阴影调制；
- 与公开 McMaster IPIX X 波段实测数据比较。

其验证覆盖回波强度、幅度分布、Doppler 谱及时空相关；IPIX 数据覆盖 339 组记录、9.39 GHz、PRF 1000 Hz、14 个距离单元、每组 `2^17` 复采样，环境范围约为波高 0.8-3.8 m、风速 0-60 km/h。

推荐角色：

```text
B_new = Random-Stokes surface + breaking deployment + shadow + radar echo
```

它比 Standard Lie/CWM 更适合出现在 GRSL 正文，因为发表较新、任务链条相同且使用公开实测回波。但它对破碎的处理仍偏参数化，并没有提供翻卷后多值自由面的高保真流体拓扑。因此它是**现代全链路工程 baseline**，不是卷浪几何真值。

### 3.2 高保真数值参照：HOSM with breaking model，Marine Structures 2023

Gramstad、Johannessen 和 Lian 2023 将高阶谱方法用于非线性、短峰随机海况，并加入破碎耗散模型；论文通过波峰统计的模型试验和 CFD 结果进行验证。

推荐角色：

```text
R_num = HOSM/HOS-Ocean pre-breaking and breaking-onset reference
```

HOS-Ocean v2.1 软件版本进一步把 hyperviscous filter 和 Chalikov breaking model 扩展到多方向海况。它适合选 1-3 个相同谱、相同随机种子或相同确定性聚焦波的小场景，对比波峰高度、前后不对称、局部坡度、波峰速度和破碎发生时间。

限制是 HOS 的势流单值自由面通常不能解析撞击后的真实翻卷、气泡和飞沫；因此它是破碎前与起始阶段的高保真参照，而不是 G1 完整卷曲拓扑的逐点真值。

### 3.3 最贴近三维卷浪的实验参考：McAllister et al., Nature 2024

*Three-dimensional Wave Breaking* 使用方向扩展的深水波浪实验，提出适用于不同方向扩展程度的三维破碎起始表征：局部坡度用于诊断单个波是否破碎，全局谱陡度用于预测给定海况中的破碎。

它比 Varing 2021 和 Vargas 2026 更贴近本文的“三维、方向谱、开放海域卷浪”问题。推荐作为：

```text
R_break-3D = local slope and global steepness envelope from McAllister2024
```

需要比较的是 G0/G1 的 breaking/non-breaking 分类、破碎前局部坡度分布和方向扩展依赖，而不是只挑一张翻卷效果图做目视比较。

### 3.4 开放海域破碎统计参考：Derakhti et al., JGR Oceans 2024

*Statistics of Bubble Plumes Generated by Breaking Surface Waves* 使用北太平洋 PAPA 现场数据，包含漂流 SWIFT 浮标、船载风浪与光学系统：

- `U10N` 约 0.8-22 m/s；
- `Hs` 约 2.2-10.0 m；
- 超过 2000 个 512 s 原始 burst；
- 得到 599 个 12 min 统计点；
- 同步给出风、波谱、白冠覆盖率和气泡羽流统计。

它很适合作为 G1 的开放海域聚合参考：比较给定风速、波龄和谱陡度下的破碎覆盖率/发生率趋势。它不能提供每个卷浪的三维表面真值，但能防止 G1 通过任意增加卷浪数量来获得更重的雷达尾部。

### 3.5 数据驱动上界：Zeng et al., Remote Sensing 2024

*Research on Sea Clutter Simulation Method Based on Deep Cognition of Characteristic Parameters* 使用 2262 组黄海灵山岛 Ku 波段实测数据，训练多任务网络从环境与雷达条件预测 K 分布、Doppler、后向散射与空间相关参数，再通过时空相关 K 分布生成杂波。

它可以作为 `B_echo-data-upper`，并用 PDF、CDF、Doppler 和空间相关函数以及 Pearson、cosine、Bray-Curtis 和 MMD 评价。但该方法依赖大规模配对实测训练数据，与本文“缺乏训练数据时用物理仿真生成数据”的动机相反。

因此它适合放在讨论或补充实验中说明：数据充分时，数据驱动模型能得到很高的统计拟合；本文的优势则是物理可控、可解释和可外推，而不是在同一训练海况下赢过一个直接拟合数据的模型。

## 4. 推荐的最终实验组别

### 4.1 GRSL 正文最小组合

```text
R_meas = NAV 或 IPIX 实测回波
B_new  = 2022 Random-Stokes 全链路模型
G0     = 本文关闭 breaking/curling 的消融组
G1     = 本文完整 breaking + 3-D curling 组
```

附加外部参考不作为同一列“算法组”参与排名：

```text
R_spectrum = Ryabkova2019 modified spectrum + Cox-Munk/Breon-Henriot
R_break3D  = McAllister2024
R_breakStat = Derakhti2024
```

这样可以回答三个不同问题：

| 问题 | 比较对象 | 核心指标 |
|---|---|---|
| 整体海面是否正确 | `R_spectrum/B_new/G0/G1` | 谱误差、顺横风 MSS、坡度 PDF、偏度/峰度 |
| 卷浪是否合理 | `R_break3D/R_breakStat/G0/G1` | breaking precision/recall/F1、局部坡度、破碎率或覆盖率随风速/波龄趋势 |
| 回波是否更真实 | `R_meas/B_new/G0/G1` | BD、CCDF=1e-4 尾部误差、KS/Wasserstein、Doppler 距离、时空相关和 RTI 海尖峰统计 |

### 4.2 可增强组合

在补充材料增加：

```text
R_num = 2023 HOSM/HOS-Ocean v2.1，仅做少量确定性或小域场景
B_echo-stat = STCPM，仅做回波统计拟合上界
R_break-dynamic = Vargas2026，仅在 G1 能输出拉格朗日加速度时使用
```

### 4.3 公平比较要求

所有表面生成方法尽量固定：

- 相同目标方向谱、风速、风向、有效波高和峰值周期；
- 相同空间范围、网格、采样时长和随机 realization 数；
- 相同雷达频率、极化、擦地角、距离分辨率和噪声水平；
- 相同散射、遮挡、传播和信号处理链；
- 给出置信区间和跨 realization 统计，不以单张 RTI 图代替结论。

Random-Stokes 原文若使用 P-M 谱，而本文使用 Ryabkova 或其他广谱模型，应优先让两种方法使用同一目标谱。若无法替换其输入谱，则必须单列“原论文配置结果”，不能把差异全部归因于表面拓扑。

## 5. 对“旧方法太老”的最终建议

方法年代本身不是删除 baseline 的充分理由。经典方法的价值是可复现且建立了学术坐标；但考虑 GRSL 篇幅和本文重点，可以作如下调整：

```text
正文主 baseline：Random-Stokes 2022
正文消融：G0 vs G1
正文外部实测：NAV/IPIX
正文物理参考：Ryabkova2019 + McAllister2024/Derakhti2024
补充材料：HOSM 2023；必要时再放 Standard Lie 或 CWM
```

这套组合比直接用 Varing/Vargas 替代 Standard Lie/CWM 更有说服力，因为它同时包含一个可运行的同任务现代方法、一个独立实测回波、一个三维破碎实验参考和一个开放海域破碎统计参考。

## 6. 参考文献与链接

1. Ding, M., et al. *A Novel Reconstruction Method of K-Distributed Sea Clutter with Spatial-Temporal Correlation*. Sensors, 2020, 20, 2377. https://doi.org/10.3390/s20082377
2. Angelliaume, S., Rosenberg, L., and Ritchie, M. *Modeling the Amplitude Distribution of Radar Sea Clutter*. Remote Sensing, 2019, 11, 319. https://doi.org/10.3390/rs11030319
3. Ryabkova, M., et al. *A Review of Wave Spectrum Models as Applied to the Problem of Radar Probing of the Sea Surface*. JGR: Oceans, 2019, 124, 7104-7134. https://doi.org/10.1029/2018JC014804
4. Varing, A., et al. *A New Definition of the Kinematic Breaking Onset Criterion Validated with Solitary and Quasi-Regular Waves in Shallow Water*. Coastal Engineering, 2021, 164, 103755. https://doi.org/10.1016/j.coastaleng.2020.103755
5. Vargas-Magana, R. M., et al. *Lagrangian Acceleration as a Diagnostic for Wave Breaking in the Nearshore Zone*. JGR: Oceans, 2026, 131, e2024JC022193. https://doi.org/10.1029/2024JC022193
6. *The Dynamic Sea Clutter Simulation of Shore-Based Radar Based on Stokes Waves*. Remote Sensing, 2022, 14, 3915. https://doi.org/10.3390/rs14163915
7. Gramstad, O., Johannessen, T. B., and Lian, G. *Long-Term Analysis of Wave-Induced Loads Using High Order Spectral Method and Direct Sampling of Extreme Wave Events*. Marine Structures, 2023, 91, 103473. https://doi.org/10.1016/j.marstruc.2023.103473
8. HOS-Ocean releases and source code. https://gitlab.com/lheea/HOS-Ocean/-/releases
9. McAllister, M. L., et al. *Three-Dimensional Wave Breaking*. Nature, 2024, 633, 601-607. https://doi.org/10.1038/s41586-024-07886-z
10. Derakhti, M., et al. *Statistics of Bubble Plumes Generated by Breaking Surface Waves*. JGR: Oceans, 2024, 129, e2023JC019753. https://doi.org/10.1029/2023JC019753
11. Stringari, C. E., et al. *A New Probabilistic Wave Breaking Model for Dominant Wind-Sea Waves Based on the Gaussian Field Theory*. JGR: Oceans, 2021, 126, e2020JC016943. https://doi.org/10.1029/2020JC016943
12. Zeng, P., et al. *Research on Sea Clutter Simulation Method Based on Deep Cognition of Characteristic Parameters*. Remote Sensing, 2024, 16, 4741. https://doi.org/10.3390/rs16244741

## 7. 一句话决策

**五篇附件可以作为分层 reference，但不能整体替代海面生成 baseline；正文用 Random-Stokes 2022 作为现代同任务 baseline，HOSM 2023 作高保真小场景参照，Ryabkova2019、McAllister2024、Derakhti2024 和实测 NAV/IPIX 分别约束波谱、三维破碎、破碎统计和最终回波。**

