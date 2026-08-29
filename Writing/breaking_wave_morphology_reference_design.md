# 卷浪形态与 RCS 参照文献检索结果

## 1. 与本文最相关的文献

| 文献 | 数据类型 | 直接测量内容 | 可作为本文什么参照 | 数据可得性 |
|---|---|---|---|---|
| Schwendeman and Thomson, JPO 2017 | 北太平洋开放海域船载双目观测 | 三维时变海面、103 个破碎波剖面、局部坡度、波速 | 开放海域尺度、前后坡、波峰局部形状、曲率和不对称性的主参照 | 原始图像需申请；三维网格数据和 MATLAB 代码公开 |
| Erinin et al., JFM 2023 | 深水波槽 plunging breaker | weak/moderate/strong 三类卷浪，各重复 10 次；jet formation 到 impact 的剖面 | 卷唇尺度、前伸/下卷尺度、卷唇面积和阶段形态参照 | 论文、剖面图和补充视频公开 |
| McAllister et al., Nature 2024 | 三维方向聚焦波实验 | 方向展宽、破碎起始局部坡度、整体谱陡度 | 破碎起始和方向展宽参照，不是破碎后卷浪形态参照 | Zenodo 数据公开 |
| Bonmarin, JFM 1989 | 深水破碎波实验 | 前坡、后坡、水平/垂直不对称及 plunging crest 演化 | 形态参数定义和破碎阶段变化参照 | 论文可得，未发现结构化开放数据 |
| Nepf, Wu and Chan, JPO 1998 | 二维/三维聚焦破碎波实验 | crest-front steepness、水平/垂直不对称、方向展宽影响 | 前坡和不对称随三维性的变化参照 | 论文可得 |
| Tang et al., JTECH 1999 | spilling breaker 激光坡度实验 | 波峰前后局部坡度的高分辨率空间变化 | 前坡、后坡及波峰尖锐程度参照 | 论文可得 |
| Stringari et al., Scientific Reports 2021 | 黑海现场主动破碎图像 | 破碎面积、长短轴、持续时间、长宽比 | 三维卷浪作用区域的平面尺度参照 | 论文和部分数据/方法公开 |
| Aggarwal et al., Ocean Engineering 2020 | 经实验验证的近岸 CFD | irregular breakers 的前坡、后坡、水平/垂直不对称分布 | 近岸斜坡工况辅助参照 | 不是开放海域实测真值 |

## 2. 按形态指标检索到的参照

### 2.1 卷浪尺度

**首选：Erinin et al. 2023。**

该文对 weak、moderate、strong 三种 plunging breaker 给出了：

| 指标 | weak | moderate | strong |
|---|---:|---:|---:|
| jet formation 时 `H/L` | 0.166 | 0.185 | 0.193 |
| jet impact 时 `H/L` | 0.148 | 0.163 | 0.171 |
| 卷唇水平尺度 `r_x` | 57.4 mm | 73.5 mm | 81.5 mm |
| 卷唇垂直尺度 `r_y` | 53.0 mm | 65.0 mm | 69.4 mm |
| 卷唇下方面积 `Q` | 2222 mm2 | 3457 mm2 | 4134 mm2 |
| formation 到 impact 时间 | 148.9 ms | 166.8 ms | 169.7 ms |

这些数值属于实验波槽尺度。用于本文时应比较 `r_x/lambda`、`r_y/lambda`、`Q/lambda^2` 和 `Delta t/T`，不能直接比较毫米值。

**开放海域补充：Stringari et al. 2021。**

黑海主动破碎斑块的长短轴比均值约 2.4-2.5、众数约 1.8-1.9，`T_br/T_p` 均值约 0.13。该数据测量的是主动白沫斑块，不是卷唇自由面，只能参照平面长度、宽度、面积和持续时间。

### 2.2 前坡

**Tang et al. 1999：** spilling breaker 波峰前方测得最大局部坡度约 74 deg；坡度先由 0 增至约 44 deg，再在约 4.2 cm 的水平距离内快速增至 74 deg。该文适合验证波峰前方是否出现局部急剧增陡。

**Nepf et al. 1998：** 二维破碎波的 crest-front steepness 约为 0.56；文中同时指出现场观测的极限 crest-front steepness 分布很宽，约 0.32-0.78，说明不能采用单一固定阈值。

**Erinin et al. 2023：** jet impact 附近卷唇前表面角度在 weak/moderate/strong 三组中约为 65.3、67.6、66.3 deg。

**Schwendeman and Thomson 2017：** 103 个开放海域破碎波显示，真正显著的是波峰附近高度局部化的陡坡，而不是整条 crest-to-trough 的总体陡度。

### 2.3 后坡

**Tang et al. 1999：** 在同一 spilling breaker 实验中，后坡最小坡度在演化过程中稳定在约 -30 deg，而前坡变化明显更大。

**Bonmarin 1989：** 深水破碎波接近破碎时的主要形态变化来自前坡增陡；后坡陡度变化较小，文中报告后坡参数主要位于约 0.20-0.35。

**Nepf et al. 1998：** 二维和三维波在破碎前都形成前后不对称，方向展宽对前坡影响明显，对后坡和水平不对称的影响相对较弱。

因此，后坡不应与前坡使用同一个可调增益，也不应假设强卷浪时前后坡同步等比例增大。

### 2.4 波峰曲率

检索到的实验文献很少给出可直接套用的“真实波峰曲率常数”。主要原因是曲率对空间分辨率、平滑尺度和波峰定位非常敏感，翻卷后自由面又不再是单值函数。

可用文献如下：

- Schwendeman and Thomson 2017 公开了开放海域三维网格海面及 MATLAB 分析代码，可在统一分辨率和平滑尺度下重新计算波峰主曲率/剖面曲率；
- Erinin et al. 2023 提供 jet formation 到 impact 的高分辨率剖面，可从归一化剖面计算局部曲率；
- Tang et al. 1999 给出波峰附近坡度的空间急变，可作为曲率变化的间接观测；
- McAllister et al. 2024 的高密度测波阵列适合局部坡度和破碎起始，不适合作为破碎后卷唇曲率真值。

结论：曲率应以 Schwendeman 公开三维海面为主数据重新统计，不能引用一个固定文献数值作为所有卷浪的曲率真值。

### 2.5 不对称程度

**Bonmarin 1989：** 直接研究 near-breaking profile 的水平和垂直不对称，并发现不对称增长率与 breaker type 有关，plunging breaker 最大、spilling breaker 最小。

**Nepf et al. 1998：** 二维和三维波均在破碎前产生 front-to-back asymmetry；二维波的不对称和前坡更强，说明方向展宽必须进入不对称参照。

**Aggarwal et al. 2020：** 对近岸 irregular breakers 统计了 crest-front steepness、crest-rear steepness、horizontal asymmetry 和 vertical asymmetry，并发现这些量适合用 lognormal 分布描述。但该研究是近岸斜坡 CFD，只能作辅助对照，不能作为本文开放海域主真值。

**Schwendeman and Thomson 2017：** 数据包含三维时变海面，可按同一参数定义重新计算开放海域破碎波的前后不对称分布，是与本文工况最一致的数据源。

## 3. RCS 参照文献

| 文献 | 雷达与实验 | 可比较的 RCS 信息 |
|---|---|---|
| Sletten et al., Radio Science 2003 | 6-12 GHz 双极化 X 波段，约 12 deg 擦地角，约 4 cm 距离分辨率；同步高速光学剖面 | spilling/plunging 各阶段的 HH/VV 回波、能量占比、距离-时间图和 Doppler |
| Ericson et al., JGR 1999 | X 波段，45 deg 入射，HH/VV，上视/下视 stationary breakers | 破碎波峰附近 `sigma0` 增强和 HH/VV 极化比趋近 1 |
| Stresser et al., IEEE TGRS 2022 | 岸基相干 X 波段现场 surf-zone 数据 | active/post-breaking 阶段回波约增强 10 dB、Doppler 接近浅水波相速 |

Sletten et al. 2003 与本文最匹配，因为它把卷浪光学形态和 X 波段回波同步记录下来。该文报告：

- spilling breaker 初始 crest bulge 贡献超过 90% 的 HH 能量、约 60% 的 VV 能量；
- plunging breaker 的 jet、impact 和 splash-up 产生更复杂、更宽的 Doppler；
- 强散射中心的迁移速度与波峰及破碎结构速度有关。

## 4. 检索结论

按本文开放海域卷浪模型，推荐参照优先级为：

```text
尺度、前后坡、曲率、不对称主数据：Schwendeman and Thomson 2017
plunging 卷唇局部尺度与阶段剖面：Erinin et al. 2023
三维方向展宽与破碎起始：McAllister et al. 2024
局部前/后坡实验数值：Tang et al. 1999、Nepf et al. 1998、Bonmarin 1989
RCS：Sletten et al. 2003，辅以 Ericson 1999 和 Stresser et al. 2022
```

## 5. 文献和数据链接

1. Schwendeman, M. S., and Thomson, J. Sharp-Crested Breaking Surface Waves Observed from a Ship-Based Stereo Video System. Journal of Physical Oceanography 47, 775-792 (2017). https://doi.org/10.1175/JPO-D-16-0187.1
2. Schwendeman and Thomson 2017 data and MATLAB analysis code. https://digital.lib.washington.edu/researchworks/items/970ce35d-41c7-4e7d-b5eb-6bc6a5cf053a
3. Erinin, M. A., et al. Plunging breakers. Part 1. Analysis of an ensemble of wave profiles. Journal of Fluid Mechanics 967, A35 (2023). https://doi.org/10.1017/jfm.2023.379
4. McAllister, M. L., et al. Three-dimensional wave breaking. Nature 633, 601-607 (2024). https://doi.org/10.1038/s41586-024-07886-z
5. McAllister 2024 data. https://doi.org/10.5281/zenodo.10818626
6. Bonmarin, P. Geometric properties of deep-water breaking waves. Journal of Fluid Mechanics 209, 405-433 (1989). https://doi.org/10.1017/S0022112089003162
7. Nepf, H. M., Wu, C. H., and Chan, E. S. A Comparison of Two- and Three-Dimensional Wave Breaking. Journal of Physical Oceanography 28, 1496-1510 (1998). https://doi.org/10.1175/1520-0485(1998)028%3C1496:ACOTAT%3E2.0.CO;2
8. Tang, S., et al. On Extreme Spatial Variations of Surface Slope for a Spilling Breaking Water Wave. Journal of Atmospheric and Oceanic Technology 16, 92-95 (1999). https://doi.org/10.1175/1520-0426(1999)016%3C0092:OESVOS%3E2.0.CO;2
9. Stringari, C. E., et al. Deep neural networks for active wave breaking classification. Scientific Reports 11, 3604 (2021). https://doi.org/10.1038/s41598-021-83188-y
10. Aggarwal, A., et al. Properties of breaking irregular waves over slopes. Ocean Engineering 216, 108098 (2020). https://doi.org/10.1016/j.oceaneng.2020.108098
11. Sletten, M. A., et al. Radar investigations of breaking water waves at low grazing angles with simultaneous high-speed optical imagery. Radio Science 38 (2003). https://doi.org/10.1029/2002RS002716
12. Ericson, E. A., et al. Radar backscatter from stationary breaking waves. Journal of Geophysical Research: Oceans 104 (1999). https://doi.org/10.1029/1999JC900223
13. Stresser, M., et al. On the Interpretation of Coherent Marine Radar Backscatter From Surf Zone Waves. IEEE Transactions on Geoscience and Remote Sensing 60 (2022). https://doi.org/10.1109/TGRS.2021.3103417

