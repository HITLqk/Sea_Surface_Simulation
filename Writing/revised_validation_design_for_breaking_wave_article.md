# 面向卷浪海面建模论文的验证方案重构

## 1. 当前验证问题的根源

当前稿件的验证思路存在一个核心问题：验证对象没有被拆开。

文章真正想证明的是：

1. 提出的海面模型整体上符合真实海面统计规律；
2. 提出的卷浪模块确实比普通海面模型更能描述高海况破碎/卷曲现象；
3. 由卷浪海面驱动生成的雷达海杂波更接近实测高海况海杂波。

但目前验证更像是在证明“整体模型可以生成一些合理图像”，没有形成严格的模块级证据链。尤其是：

- Cox-Munk 只验证了整体海面坡度统计，没有验证卷浪；
- 分布验证只验证了最终海杂波幅度统计，没有说明改善来自卷浪模块；
- RTI 对比只是仿真图和实测图并列展示，缺少合理对照组，因此说服力不足；
- Sea State 2 和 Sea State 5 的对比只能说明海况不同导致图像不同，不能说明本文方法优于已有方法；
- 没有设置 `without breaking wave` 和 `with breaking wave` 的消融组，所以无法证明卷浪建模是必要的。

因此，新的验证方案必须从“展示结果”转为“可归因的对照实验”。

## 2. 新验证总逻辑

建议把验证组织为三层：

1. 海面统计合理性验证：证明生成海面总体物理统计不离谱。
2. 卷浪模块有效性验证：证明卷浪模块确实改变了高海况下的局部几何与雷达散射特征。
3. 雷达海杂波真实性验证：证明加入卷浪后的仿真回波更接近实测高海况数据。

对应你指定的三类验证方法：

- Cox-Munk：用于海面坡度统计验证；
- 分布验证：用于海杂波幅度统计验证；
- RTI 可视化对比：用于海杂波时距图形态验证。

但每一类验证都必须设置清楚组别：

- 基线组：传统线性海面或标准 Lie 变换海面；
- 消融组：本文方法去掉卷浪模块；
- 完整组：本文方法加入卷浪模块；
- 实测组：NAU 或其他实测海杂波数据。

## 3. 验证方法一：Cox-Munk 均方斜率验证

### 3.1 验证目的

Cox-Munk 不适合直接验证“卷浪形状是否正确”，它适合验证生成海面的整体坡度统计是否符合真实风驱海面的经验规律。

因此，这部分的结论应该写成：

本文模型在引入卷浪修正后，仍能保持合理的海面坡度统计，并且在中高风速下比标准 Lie 变换更接近 Cox-Munk 经验范围。

不要把 Cox-Munk 写成卷浪的直接验证，因为 Cox-Munk 来自太阳耀斑图案反演的海面 slope distribution，本质上是全局坡度统计基准，不是破碎浪标签数据。

### 3.2 数据集/基准

使用 Cox-Munk 经验模型作为外部物理基准，不需要真实雷达数据。

基准公式：

`MSS = sigma_a^2 + sigma_c^2 = 0.003 + 5.12e-3 U +/- 0.004`

其中 `U` 为风速。

### 3.3 推荐组别

建议设置三组：

| 组别 | 含义 | 用途 |
| --- | --- | --- |
| Linear spectrum surface | Elfouhaily/PM/JONSWAP + 线性叠加海面 | 最弱基线 |
| Standard Lie transform | 标准二阶非线性海面 | 非线性基线 |
| Proposed with breaking correction | 本文完整模型 | 证明整体坡度统计合理 |

如果篇幅有限，可以保留两组：

- Standard Lie transform；
- Proposed method。

但如果要说明“卷浪修正没有破坏整体物理统计”，建议三组更清楚。

### 3.4 风速/海况设置

建议覆盖低、中、高风速：

- 低风速：4 m/s 或 Sea State 2；
- 中风速：8-10 m/s 或 Sea State 3-4；
- 高风速：14-18 m/s 或 Sea State 5-6。

如果画连续曲线，可以使用：

- 风速范围：1-20 m/s；
- 每个风速重复生成多组随机海面；
- 每个风速取 ensemble mean 和标准差。

### 3.5 指标

核心指标：

- `MSS_x`：沿风向均方斜率；
- `MSS_y`：侧风向均方斜率；
- `MSS_total = MSS_x + MSS_y`；
- 与 Cox-Munk 中心值或上下界的相对误差。

建议补充：

`Relative MSS Error = |MSS_sim - MSS_CM| / MSS_CM`

### 3.6 验证结论应该怎么写

合理结论应该是：

- proposed method 的 MSS 随风速增长趋势与 Cox-Munk 一致；
- proposed method 在高风速下仍落入 Cox-Munk 上下界；
- standard Lie transform 在高风速下偏离更明显；
- 因此，本文方法的全局坡度统计更符合真实风驱海面。

但注意：

这只能证明整体海面 slope statistics 合理，不能单独证明卷浪几何正确。

## 4. 验证方法二：卷浪模块专门验证

虽然你列出的三类验证是 Cox-Munk、分布验证、RTI 对比，但由于你指出“没有验证卷浪”，这里必须加一个卷浪专门验证环节。否则文章主创新点没有被正面验证。

### 4.1 验证目的

证明加入卷浪模块后，高海况海面出现了更符合破碎浪物理特征的局部几何结构，并且这些结构会影响后续雷达散射。

### 4.2 推荐数据集

卷浪验证最好使用非雷达的破碎浪几何数据或公开波浪实验数据。可选数据来源：

1. 数值波槽/实验波槽 breaking wave 数据集；
2. 公开 plunging breaker 视频/点云/剖面数据；
3. 文献中的 breaking wave 几何统计结果；
4. 如果没有真实卷浪标签数据，至少使用物理破碎判据和几何指标进行弱监督验证。

结合当前已有材料，建议优先考虑：

- Boettger / numerical wave tank breaking wave data；
- Guimaraes breaking wave profile / laboratory wave data；
- 文献中的破碎波几何指标，例如 crest front steepness、crest asymmetry、overturning ratio。

如果真实数据处理成本太高，GRSL 可以先采用“物理判据 + 消融对照”的形式。

### 4.3 推荐组别

卷浪验证必须有消融组：

| 组别 | 模型 | 目的 |
| --- | --- | --- |
| G1 | Linear sea surface | 无非线性、无卷浪 |
| G2 | Standard Lie transform | 有二阶非线性，但无显式卷浪 |
| G3 | Proposed without affine curling | 有风速/方向修正，但不触发卷曲 |
| G4 | Proposed full breaking model | 完整卷浪模型 |
| G5 | Breaking wave reference data | 实验/数值/文献参考 |

如果篇幅不够，最低限度也要有：

- Standard Lie transform；
- Proposed without breaking；
- Proposed with breaking。

### 4.4 推荐指标

卷浪几何指标可以设置为：

- Crest-front steepness：波峰前坡陡度；
- Crest-back steepness：波峰后坡陡度；
- Crest asymmetry ratio：前后坡不对称比；
- Breaking occurrence rate：满足破碎触发条件的波峰比例；
- Overturning ratio：翻卷区域水平位移与波高/波长的比值；
- Local curvature near crest：波峰附近曲率；
- Whitecap/breaking coverage proxy：卷浪区域占海面面积比例；
- Shadowed facet ratio：由卷浪导致的被遮挡面元比例。

其中，最适合本文雷达导向目标的是：

`shadowed facet ratio` 和 `high-RCS crest ratio`。

因为这两个指标能把卷浪几何和雷达散射联系起来。

### 4.5 验证结论应该怎么写

这部分应证明：

- 标准 Lie 变换只能产生波峰陡化，不能产生明显翻卷结构；
- proposed full breaking model 能产生更大的 crest asymmetry、local curvature 和 overturning ratio；
- 高风速下 breaking occurrence rate 随风速增加；
- 卷浪区域带来更高的局部 RCS 和更多 shadowed facets；
- 因此，卷浪模块不是视觉装饰，而是改变了海面几何和雷达散射机制。

## 5. 验证方法三：海杂波幅度分布验证

### 5.1 验证目的

分布验证的目标不是证明海面几何正确，而是证明生成的雷达海杂波幅度统计接近实测海杂波，尤其是高海况下的非高斯重尾特征。

这里必须通过组别设置回答：

加入卷浪以后，仿真海杂波是否比不加卷浪更接近实测高海况分布？

### 5.2 数据集

推荐使用：

- NAU X-band solid-state staring radar sea clutter dataset；
- HH polarization；
- 至少包含 Sea State 2 和 Sea State 5；
- 如果可用，记录擦地角、距离分辨率、脉冲数、采样率、风速、海况标签。

### 5.3 推荐组别

对每个海况分别做组别对比：

| 组别 | Sea State 2 | Sea State 5 |
| --- | --- | --- |
| Real measured data | NAU SS2 | NAU SS5 |
| Baseline simulation | standard Lie / no breaking | standard Lie / no breaking |
| Proposed without breaking | no breaking module | no breaking module |
| Proposed with breaking | full model | full model |

核心重点是 Sea State 5，因为卷浪主要发生在高海况。

Sea State 2 的作用：

- 证明低海况下不应该过度生成重尾和海尖峰；
- proposed with breaking 在低海况下应退化或弱触发，不应制造虚假卷浪。

Sea State 5 的作用：

- 证明高海况下加入卷浪后，分布尾部更接近实测；
- 无卷浪组通常会低估高幅度尾部和 sea spikes。

### 5.4 分布模型

保留三类经典分布：

- Log-normal；
- Weibull；
- K-distribution。

也可以补充 Rayleigh 作为传统基线，但如果篇幅紧张，可以不放。

### 5.5 参数估计

可以继续使用 Method of Moments, MoM。

但建议补一句：

所有分布参数均在相同幅度归一化条件下估计，以保证仿真与实测的比较公平。

### 5.6 指标

建议使用：

- PDF fitting；
- CDF fitting；
- K-S distance；
- RMSE；
- Tail error；
- Sea-spike rate。

其中新增两个更关键：

`Tail Error = error over top 5% or top 1% amplitude region`

`Sea-spike rate = proportion of samples exceeding mu + n sigma or a percentile threshold`

原因：

- 卷浪主要影响尾部强散射；
- 只用整体 RMSE 可能掩盖尾部差异；
- K-S 关注 CDF 最大差异，但不一定专门反映高幅度尾部；
- tail error 和 sea-spike rate 更能体现卷浪对高海况海杂波的贡献。

### 5.7 验证结论应该怎么写

理想结论应该是：

- 在 Sea State 2 下，proposed with breaking 与 no-breaking 组差异较小，说明模型不会在低海况下过度触发卷浪；
- 在 Sea State 5 下，no-breaking 组明显低估高幅度尾部；
- proposed with breaking 的 K-S、tail error 和 sea-spike rate 更接近 NAU 实测数据；
- K-distribution 对实测和 proposed with breaking 仿真数据均取得较好拟合；
- 因此，卷浪模块改善了高海况雷达海杂波的重尾统计真实性。

## 6. 验证方法四：RTI 可视化对比

### 6.1 当前问题

当前 RTI 图的问题不是不能画，而是对照组不够。

如果只放：

- Sea State 2 simulated；
- Sea State 2 measured；
- Sea State 5 simulated；
- Sea State 5 measured；

读者只能看到“仿真和实测看起来有点像”。但看不出：

- 本文方法比标准方法好在哪里；
- 卷浪模块贡献在哪里；
- 高海况改善是否来自卷浪，而不是颜色范围或随机种子。

### 6.2 推荐 RTI 图组别

建议 RTI 对比图按海况分两行，每行四列：

| 列 | 内容 |
| --- | --- |
| 1 | NAU measured |
| 2 | Standard Lie / no breaking simulation |
| 3 | Proposed without breaking |
| 4 | Proposed with breaking |

行设置：

- 第一行：Sea State 2；
- 第二行：Sea State 5。

这样能直接看出：

- 低海况下各方法都不应产生过强海尖峰；
- 高海况下只有 proposed with breaking 能产生接近实测的密集强散射条纹和重尾纹理。

如果版面紧张，可以只保留 Sea State 5 的四列对比，因为它最能说明卷浪。

### 6.3 RTI 可视化要求

必须统一：

- 相同 range bins；
- 相同 pulse/time length；
- 相同 dB 色标范围；
- 相同幅度归一化方式；
- 相同海况标签；
- 相同雷达参数或尽可能匹配的参数。

否则 RTI 图容易被认为只是视觉展示。

### 6.4 RTI 定量辅助指标

建议至少加一到两个简单指标，不然可视化仍然偏主观。

可选：

- ACF / spatial correlation；
- temporal correlation length；
- range correlation length；
- sea-spike density；
- RTI contrast；
- structural similarity index, SSIM；
- Wasserstein distance of RTI amplitude histograms。

最推荐：

1. Sea-spike density；
2. ACF / correlation length。

原因：

- sea-spike density 直接对应高海况卷浪造成的强散射；
- ACF 可以验证涌浪/长波调制带来的空间或慢时间相关性；
- 这两个指标比 SSIM 更符合海杂波物理含义。

### 6.5 验证结论应该怎么写

RTI 对比应支持：

- Sea State 2 下，proposed model 与实测均表现为稀疏、弱散射、低 sea-spike density；
- Sea State 5 下，no-breaking 组缺少连续强散射轨迹，sea-spike density 偏低；
- proposed with breaking 组出现更接近实测的密集强散射条纹和周期性高能调制；
- 因此，卷浪模块显著改善了高海况 RTI 纹理真实性。

## 7. 推荐最终实验结构

### Experiment 1: Sea-surface slope statistics

目的：

验证整体海面 slope statistics 是否符合 Cox-Munk。

数据：

- 仿真海面；
- Cox-Munk 经验模型。

组别：

- Linear surface；
- Standard Lie transform；
- Proposed full model。

指标：

- MSS；
- relative MSS error。

### Experiment 2: Breaking-wave geometry ablation

目的：

验证卷浪模块是否真的产生高海况破碎浪几何。

数据：

- 仿真海面；
- 可选 breaking wave reference data；
- 或物理破碎判据。

组别：

- Standard Lie；
- Proposed without breaking；
- Proposed with breaking。

指标：

- crest asymmetry；
- local curvature；
- overturning ratio；
- breaking occurrence rate；
- shadowed facet ratio。

### Experiment 3: Radar amplitude distribution

目的：

验证生成海杂波是否接近实测幅度统计，尤其是高海况尾部。

数据：

- NAU X-band HH sea clutter；
- 仿真海杂波。

组别：

- NAU measured SS2 / SS5；
- standard Lie simulation；
- proposed without breaking；
- proposed with breaking。

指标：

- PDF；
- CDF；
- K-S distance；
- RMSE；
- tail error；
- sea-spike rate。

### Experiment 4: RTI morphology comparison

目的：

验证仿真 RTI 是否在形态上接近实测，并展示卷浪模块贡献。

数据：

- NAU measured RTI；
- 仿真 RTI。

组别：

- Sea State 2：measured、standard/no-breaking、proposed without breaking、proposed with breaking；
- Sea State 5：measured、standard/no-breaking、proposed without breaking、proposed with breaking。

指标/展示：

- RTI images；
- sea-spike density；
- ACF / correlation length。

## 8. 最低可发表版本

如果 GRSL 篇幅非常紧张，最低限度应保留：

1. Cox-Munk MSS 曲线：

   `standard Lie vs proposed full model vs Cox-Munk bounds`

2. Sea State 5 消融分布验证：

   `NAU measured vs no-breaking simulation vs with-breaking simulation`

   指标：

   - PDF/CDF；
   - K-S；
   - tail error；
   - sea-spike rate。

3. Sea State 5 RTI 消融图：

   `measured / no-breaking / with-breaking`

这样即使只放三组图，也能讲清楚：

- 海面整体统计合理；
- 卷浪模块改善高海况尾部统计；
- 卷浪模块改善 RTI 强散射纹理。

## 9. 推荐写法调整

当前稿件不要把验证写成：

“Fig. X shows that the simulated and measured RTI profiles are similar.”

建议改成：

“To isolate the contribution of the breaking-wave module, we compare three simulation configurations: the standard Lie-transform sea surface, the proposed model without the breaking correction, and the full proposed model. The comparison is performed against the NAU X-band HH-polarized sea clutter under Sea States 2 and 5. The Sea State 5 case is used as the primary high-sea-state test, where breaking waves are expected to dominate the high-amplitude tail and sea-spike behavior.”

中文意思：

为了证明卷浪模块的贡献，必须把标准方法、去卷浪方法、完整方法放在同一海况同一雷达参数下，与实测数据比较。

## 10. 一句话结论

新的验证方案应该从“整体仿真图展示”改为“模块消融验证”：Cox-Munk 验证整体海面坡度统计，卷浪几何指标验证卷浪模块本身，分布验证和 RTI 对比则必须设置 `实测数据 / 无卷浪基线 / 有卷浪完整模型` 的对照组，重点证明卷浪模块在 Sea State 5 等高海况下能改善重尾幅度分布、sea-spike rate 和 RTI 强散射纹理。

