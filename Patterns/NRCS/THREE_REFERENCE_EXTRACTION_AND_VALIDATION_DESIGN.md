# 三篇局部卷浪雷达文献提取与验证设计

## 1. 结论先行

这三篇论文可以共同构成本文局部卷浪雷达响应的参考链，但不能被当成三套可直接叠加的绝对 NRCS 数据：

- Sletten et al. (2003) 是实验锚点，提供同步光学-雷达条件、卷浪形成时序、极化响应和能量占比；
- West (2002) 是二维数值机制基线，证明孤立卷浪波峰在去除大尺度前坡多径后仍可产生显著 HH/VV 差异；
- Li and West (2006) 是三维数值机制基线，证明有限峰线和方位变化不会消除形成中 jet-cavity 的极化干涉，并揭示遮蔽导致的阶段非单调性。

因此，本文不应把目标写成“卷浪后 NRCS 必须增加 X dB”。更稳健的验证命题是：

> 在同一随机海面、同一物理波峰、同一局部窗口和同一雷达条件下，显式卷曲几何应产生与实测和全波计算一致的局部强回波集中、阶段依赖、极化差异和方位敏感性。

主指标使用同一散射定义内部的配对差值：

```text
G_b = 10 log10(S_curl / S_pre)
```

其中 `S` 可以是局部积分 RCS、局部 NRCS 或文献原有散射量。跨文献只比较 `G_b`、排序和响应形态，不比较未经统一标定的绝对纵轴。

## 2. 文献与证据等级

### 2.1 West (2002)

J. C. West, “Low-Grazing-Angle (LGA) Sea-Spike Backscattering From Plunging Breaker Crests,” *IEEE Transactions on Geoscience and Remote Sensing*, vol. 40, no. 2, pp. 523–526, 2002. DOI: [10.1109/36.992830](https://doi.org/10.1109/36.992830).

原文明确内容：

- 输入是 LONGTANK 数值水槽给出的二维 plunging-breaker 时序剖面；
- 计算时隔离 crest region，刻意去除前坡参与形成的大尺度多次反射路径；
- breaking 过程中 HH 显著超过 VV，即该现象并不要求“波峰-前坡”大尺度多径存在；
- 早期随波峰变陡的散射上升，与曲率拐点处的绕射有关，可由修正 GTD 解释；
- 波峰曲率半径减小后的强响应，可由 extended geometrical optics (EGO) 描述；
- 简单假设 HH、VV 光学截面相等的模型不适用于复杂卷浪波峰。

可为本文所用：

1. `G0 pre-curl` 与 `G1-G3 curl` 必须只改变局部 crest 几何，不能同时改变背景海面和计算窗口；
2. 即使本文不实现大尺度多径，也有依据检验卷浪几何本身是否造成局部散射变化；
3. 曲率拐点、lip 和小曲率半径区域应与强回波位置对应；
4. HH/VV 不应被模型预设为相等。

不能直接采用：

- 公开可核对页面没有给出完整曲线的可靠数值表；
- 其二维散射量不能直接转换成本文有限三维窗口的 NRCS；
- 配套会议摘要曾指出加入前坡多径可再提高至多约 10 dB，但这不是 West (2002) 的孤立 crest 主结果，不能作为本文 `G_b` 的固定目标。

### 2.2 Li and West (2006)

Y. Li and J. C. West, “Low-Grazing-Angle Scattering From 3-D Breaking Water Wave Crests,” *IEEE Transactions on Geoscience and Remote Sensing*, vol. 44, no. 8, pp. 2093–2101, 2006. DOI: [10.1109/TGRS.2006.872129](https://doi.org/10.1109/TGRS.2006.872129).

原文明确内容：

- 三维测试面由同一 LONGTANK 二维 breaker 时序剖面沿峰线方向进行方位组织而成；
- 使用 multilevel fast multipole algorithm (MLFMA) 进行三维全波计算；
- breaking 中期，形成中的 jet 与其下方 cavity 的反射在 VV 上强烈相消，在 HH 上相长；
- 加入三维方位变化后，VV cancellation 仍然存在，HH/VV 仍可远大于 1；
- 偏离精确 up-wave 观察后，该效应仍可保留；
- 后期完整 jet 在 up-wave 方向遮蔽 cavity，干涉可能消失；偏离 up-wave 后 cavity 再次可见，干涉又可能出现；
- very-late stage 甚至可能出现 HH cancellation。

可为本文所用：

1. 必须保留有限长度三维 crest，不能只用二维剖面外推后宣称完成三维验证；
2. 增加一个 `2-D extrusion` 与 `finite 3-D crest` 消融，检验峰线有限性；
3. 主视向用 up-wave，并做少量方位偏移敏感性；
4. 卷曲程度与回波不应被强制为逐级单调增加：遮蔽、可见性和相位干涉都可能造成峰值、谷值或排序交换。

不能直接采用：

- 摘要没有提供可直接读取的绝对三维截面或统一 `G_b` 数值；
- MLFMA 的相干场干涉不能由只累加面元功率的经验散射核完整复现；
- 如果本文使用 TSC/面元模型，结论应表述为“几何引起的局部散射响应与文献趋势一致”，而不是“复现 MLFMA 干涉机制”。

### 2.3 Sletten et al. (2003)

M. A. Sletten, J. C. West, X. Liu, and J. H. Duncan, “Radar Investigations of Breaking Water Waves at Low Grazing Angles With Simultaneous High-Speed Optical Imagery,” *Radio Science*, vol. 38, no. 6, 1110, 2003. DOI: [10.1029/2002RS002716](https://doi.org/10.1029/2002RS002716).

这是三篇中唯一能够直接承担实验锚点的论文。

#### 实验条件

| 项目 | 原文数值/条件 | 本文用途 |
|---|---:|---|
| 主导水波波长 | 约 `0.80 m` | 几何尺度参考 |
| 波包中心频率 | `1.42 Hz` | 水动力条件记录 |
| 相速/仪器车速度 | `94.5 cm/s` | 多普勒参考 |
| 破碎前 trough-to-crest 高度 | 约 `12.5 cm` | 几何尺度参考 |
| amplitude parameter | spiller `0.062`，plunger `0.066`，均以名义波长归一化 | 说明两类破碎仅由较小控制量差异触发，不直接移植为本文参数 |
| 光学帧率 | `250 Hz` | 时序可信度 |
| 光学视场 | `18.5 cm x 18.5 cm` | 说明观测只覆盖局部 crest；不作为本文固定窗口尺寸 |
| 雷达频带 | `6-12 GHz` UWB | X 波段依据 |
| 典型分析频率 | `8 GHz`、`10 GHz` | 建议本文主条件取 `10 GHz` |
| 距离分辨率 | 约 `4 cm` | 回波集中尺度参考 |
| 极化 | HH、VV 共极化 | 主用 HH，VV 作机制诊断 |
| 每极化 PRF | `125 Hz` | 动态实验记录 |
| 距离扫描周期 | `4 ms` | 动态实验记录 |
| 距离幅宽 | `37.5 cm` | 局部观测依据 |
| 名义距离 | `1.6 m` | 近场不确定性来源 |
| 双站角 | `9 deg` | 与本文单站模型不完全同构，需声明 |
| 视向 | up-wave，照射前坡 | 主视向依据 |
| 名义擦地角 | `12 deg` | 本文主验证角 |

#### plunging breaker 的时序与经验量

| 阶段 | 时间 | 雷达/形态现象 | 是否适合本文 |
|---|---:|---|---|
| jet 开始形成 | 约 `0.15 s` | crest 出现卷曲特征 | 是 |
| jet 顶部可见 | `0.18-0.26 s` | pre-impact curl 主窗口 | 是，最直接 |
| jet 撞击前坡 | 约 `0.28 s` | pre-impact 与 post-impact 分界 | 只作截止线 |
| splash-up | `0.34-0.42 s` | 最强 HH 可能来自撞击后结构 | 否 |
| splash-up 坍塌 | 约 `0.46 s` | 进入强三维湍流表面 | 否 |

pre-impact 阶段的可用经验量：

- 最强初始 VV echo 出现在约 `0.18 s`；
- VV 在约 `0.225 s` 出现明显 null，撞击前随后还有两次较弱回波；
- HH jet echo 一次位于约 `0.22 s`，另一次更强的回波位于约 `0.25 s`，并在撞击时结束；
- 到 jet 撞击前坡时，HH 和 VV 均已产生总事件回波能量的约 `35%`；配套会议摘要将其概括为 `30%-40%`；
- 全事件的峰值 HH echo 约比峰值 VV echo 强 `11 dB`。该值包含 post-impact splash-up，不能作为本文 pre-impact HH/VV 的硬阈值；
- 10 GHz 下，初始 VV 多普勒约 `10 Hz`，对应 `105 cm/s`；初始 HH 峰约 `25 Hz`，对应 `130 cm/s`；
- jet 内部 cavity 的尺度约为 `1-2 cm`，并可能产生多散射中心或多次反射现象。

#### 标定边界

- 频域图使用球体标定，可给 absolute RCS；
- 时域 echo 仅进行了近似的 HH/VV 相对标定；
- 因回波频谱随时间和极化变化，原文明确指出不宜把时域幅值直接赋成 absolute RCS；
- 因此，从时域图提取的阶段响应只能作为相对趋势或相对能量证据。

#### 实验不确定性

- 相机只给水槽中心线二维剖面，plunger 的强三维结构无法完整量化；
- 名义擦地角可能有数度误差；
- 前坡轮廓未被完整测得，而初始散射对前坡几何敏感；
- 雷达名义距离 `1.6 m`，小于约 `3.5 m` 的 10 GHz 远场距离，但作者认为对主要结论影响有限；
- 波槽 plunger 不一定代表所有开放海面卷浪。

这些不确定性意味着：`12 deg` 是匹配主条件，不应把文献曲线当成无误差真值；本文应报告蒙特卡洛分布和角度敏感性，而不是只画一条确定曲线。

## 3. 三篇论文共同支持的可检验规律

### 3.1 可以作为判据的规律

1. **局部性**：显著回波集中在 crest、forming jet、cavity 或其邻近前坡，而非要求整个海面平均值同步抬升。
2. **阶段依赖**：从变陡到形成 lip/jet，散射结构发生显著变化；成熟 jet 的遮蔽又可能使响应下降或转移。
3. **非单调性**：VV 明确可出现 null；HH 也可能在很晚阶段相消。因此不能用“卷曲越强，NRCS 必须越大”作为单样本合格条件。
4. **极化差异**：breaking 期间 HH 可明显超过 VV，但具体差值依赖频率、角度、阶段、三维性和多径。
5. **三维性**：有限 crest 的方位变化不会简单抹平 jet-cavity 机制，二维与三维结果不应默认相同。
6. **几何敏感性**：厘米级 trough/front-face 变化即可明显改变散射；必须严格配对随机海面并固定窗口。

### 3.2 不能作为硬判据的数值

以下数字不能直接写成本文仿真的“合格范围”：

- `HH/VV > 10 dB`：可作典型 sea-spike 现象参照，不能要求每个 pre-impact 样本都满足；
- `35%` pre-impact energy：分母是包含 splash-up 和 post-breaking 的完整动态事件，而本文当前是静态 pre-impact 几何；
- 配套工作中的“多径增加至多约 10 dB”：本文若没有相干多径计算就无法复现；
- `18.5 cm` 光学窗口：这是相机视场，不是普适卷浪尺寸；
- 任何从不同论文图中读取的绝对 RCS/NRCS，除非频率、角度、极化、面积归一化和二维/三维定义全部一致。

## 4. 建议的最小验证实验

### 4.1 公共条件

主实验固定为：

```text
frequency       = 10 GHz
polarization    = HH primary, VV diagnostic
look direction  = up-wave
grazing angle   = 12 deg
window          = crest-centered fixed local window
scattering code = identical for all paired groups
```

几何尺度不能只照搬实验室的厘米值。至少报告：

```text
L_u / lambda_p, L_v / lambda_p, H_b / lambda_p
k0 R_c, k0 L_lip, k0 H_b
```

其中 `lambda_p` 是主导水波波长，`k0` 是雷达波数，`R_c` 是 crest 曲率半径。这样才能同时说明水动力相似尺度和电磁尺寸。

### 4.2 严格配对组

| 组别 | 几何 | 主要作用 |
|---|---|---|
| G0 | 同一非线性背景 crest，未 curl | pre-breaking 配对基线 |
| G1 | weak curl | steepening/early lip |
| G2 | moderate curl | forming jet/cavity |
| G3 | strong pre-impact curl | mature jet，尚未撞击 |

四组必须使用相同随机种子、同一波峰、同一窗口、同一网格、同一散射算法和同一显示动态范围。组别只表示静态形态强度，不宣称是真实时序积分。

### 4.3 主指标与辅助指标

正文主指标只保留一个：

```text
G_b = 10 log10[sum(P_curl) / sum(P_pre)]
```

其中求和在固定局部窗口内在线性域进行。

建议保留两个诊断量，但不一定都进正文：

```text
G_peak = 10 log10[max(P_curl) / max(P_pre)]
C_crest = sum(P in crest/lip mask) / sum(P in local window)
```

- `G_peak` 检验卷浪是否形成离散强散射中心；
- `C_crest` 检验能量是否集中在 crest/lip，而不是由窗口内普通海面面积变化“刷高”积分量。

`35%` 不能直接用作 `C_crest` 阈值，因为原文的 35% 是时间积分占全事件总能量。它只能支持“pre-impact jet 不是可忽略的小贡献”这一论断。

### 4.4 两个必要消融

#### A. 三维性消融

```text
A0: 2-D center profile extruded uniformly along crest
A1: finite 3-D crest with the same center profile and projected window
```

比较 `G_b`、`G_peak` 和 HH/VV。该实验对应 Li and West (2006)，用于证明本文有限峰线几何不是二维剖面的装饰性外推。

#### B. 方位敏感性

在主条件 `0 deg` up-wave 外，只取少量对称角度，例如：

```text
azimuth = -30, -15, 0, 15, 30 deg
```

这里验证的是“响应在偏离 up-wave 后仍存在，但可能因 cavity 可见性改变而重排”，不是要求曲线单调。若 Letter 版面紧，正文只画 `0 deg` 和 `30 deg`，其余用于统计。

### 4.5 蒙特卡洛方式

- 每个背景海面使用同一候选波峰生成 G0-G3；
- 不因结果不够强或不满足单调性而删样本；
- 每组建议至少 `N = 100` 对，计算允许时 `N = 200`；
- 报告配对 `G_b` 的中位数、四分位区间和 bootstrap 95% CI；
- 额外报告 `P(G_b > 0)`，但不要把它要求为 100%；
- 对 G1-G3 做配对趋势检验，同时允许个别样本出现 G2/G3 下降；
- 所有功率或截面先在线性域积分和平均，最后转 dB。

## 5. 推荐的判定逻辑

本文模型通过验证不应等价于“蓝色点进入某个固定 dB 框”。更合适的是四条联合证据：

1. **配对增量成立**：G1-G3 相对 G0 的 `G_b` 分布显著偏离 0，且不是由换窗口或换背景造成；
2. **空间位置正确**：强回波新增区域与 crest/lip/forward face 空间对应，`C_crest` 上升；
3. **响应形态合理**：不同卷曲阶段可出现峰、谷和排序交换，而不是人为线性增益；
4. **三维/方位行为合理**：有限三维 crest 与二维外推有可辨差异，偏离 up-wave 后响应保留但发生变化。

其中第 1、2 条验证本文几何模块是否真的改变局部回波；第 3、4 条用 West 和 Li-West 的机制约束防止“只把 RCS 数值调大”。

## 6. Letter 中的一幅图如何安排

建议只用一幅双子图：

- `(a)` G0 与一个代表性 moderate/strong pre-impact curl 的局部回波图，使用同一色标，并叠加 crest/lip mask；
- `(b)` G0-G3 配对 `G_b` 的散点/箱线或 violin 分布，旁边用简短标记注明实验参考：`12 deg, up-wave, 10 GHz`。

正文用一句话补充 2-D/3-D 和 azimuth 消融结果，不再增加整幅曲线。若 2-D/3-D 差异是本文卖点，再将 `(a)` 改为 2-D extrusion 与 finite 3-D 的对比。

不要在图中画一个没有原始统一数据支持的“文献 G_b 合格阴影带”。文献更适合作为实验条件和趋势约束，而不是伪造的数值真值区间。

## 7. 当前模型需要预先检查的问题

在编码前应核对现有雷达模块是否：

1. 计算复场后相干叠加，还是只对面元功率非相干求和；
2. 处理自遮蔽和 shadowing；
3. 能看见 multi-valued curl 的内侧 cavity；
4. 对 HH 和 VV 使用了不同且合理的 Fresnel/散射核；
5. 固定局部水平投影面积进行归一化；
6. 网格足以解析 `k0 R_c` 和 lip 附近法向变化；
7. 2-D extrusion 与 finite 3-D crest 使用相同中心剖面和相同投影面积。

若第 1 项答案是“仅功率累加”，则仍可完成局部几何响应验证，但不能声称复现 Li-West 的 jet-cavity 相消/相长。论文措辞应限定为 geometry-induced local backscatter enhancement and localization。

## 8. 最终建议

最稳妥且适合 5 页 Letter 的方案是：

```text
实验锚点：Sletten 2003 的 10 GHz、12 deg、up-wave、HH/VV 和 pre-impact 时序
二维机制：West 2002 的 isolated crest、curvature diffraction 与 HH>VV
三维机制：Li and West 2006 的 finite crest、azimuth persistence 与 shadowing/non-monotonicity
本文主量：固定局部窗口内的 paired G_b
本文必要消融：G0-G3 + 2-D extrusion/finite 3-D
本文辅助检查：G_peak、C_crest 和少量 azimuth sensitivity
```

这套设计不要求寻找一套与本文几何完全相同的实测三维 RCS 数据。实测论文负责约束雷达条件、阶段和现象；两篇全波论文负责约束几何机制；本文自己的严格配对蒙特卡洛负责量化卷曲模块的增量作用。

## 9. 来源可访问性说明

- Sletten et al. (2003) 的 Wiley/AGU 全文可公开读取，本文中的实验数值均从全文核对；
- West (2002) 可核对 IEEE 元数据、摘要及公开卷册中的首页，数值曲线页未能从公开渠道完整取得；
- Li and West (2006) 可核对 IEEE 元数据和摘要，完整数值曲线未能从公开渠道取得；
- 因此，本文档没有为后两篇虚构绝对散射增益或数字化曲线。若后续获得作者稿或机构订阅全文，应补充 figure extraction sheet，再决定是否加入文献数值标记。
