# Cox-Munk、分布拟合与卷浪验证相关文献检索总结

检索日期：2026-08-20

检索目标：

1. 查找雷达海面建模、雷达海杂波仿真和海面物理建模文章中如何使用 Cox-Munk 验证；
2. 查找近年 IEEE Transactions / TGRS / TAES 及相关雷达文章中如何使用幅度分布拟合验证；
3. 查找流体力学、物理海洋和破碎浪研究中如何验证卷浪、破碎浪或 plunging breaker；
4. 反推本文应如何设置验证数据集、对照组和指标。

## 1. Cox-Munk 验证相关文献

### 1.1 Ryabkova et al., JGR Oceans, 2019

题目：A Review of Wave Spectrum Models as Applied to the Problem of Radar Probing of the Sea Surface

链接：https://agupubs.onlinelibrary.wiley.com/doi/abs/10.1029/2018JC014804

检索结论：

- 这篇是海面波谱模型面向雷达探测应用的综述和模型比较文章。
- 文章明确把“由波谱积分得到的 mean square slope 是否符合实验数据”作为评价海谱模型的重要准则。
- 文中比较了 Elfouhaily、Hwang、Kudryavtsev、Karaev 等海谱模型，并用 Cox-Munk 和 Bréon-Henriot 的 MSS 实验关系作为参考。
- 结论不是“某个仿真图像看起来像海面”，而是不同谱模型积分得到的 upwind/crosswind MSS 随风速变化是否落在经验观测范围附近。

可借鉴实验设置：

- 数据/基准：Cox-Munk MSS、Bréon-Henriot MSS；
- 对照组：多个海谱模型；
- 指标：upwind MSS、crosswind MSS、total MSS；
- 横轴：风速；
- 结论方式：哪个谱模型更符合实测 MSS，哪个模型在短波尾部或高风速下偏离。

对本文启发：

- Cox-Munk 应作为“整体坡度统计基准”，不是卷浪验证工具；
- 图中应至少放 Cox-Munk bound / reference line 和不同模型曲线；
- 最好加入标准方法与本文方法的相对误差，而不是只画一条 proposed 曲线。

### 1.2 Romero & Melville, Journal of Physical Oceanography, 2019

题目：Airborne Measurements of Surface Wind and Slope Statistics over the Ocean

链接：https://doi.org/10.1175/JPO-D-19-0098.1

检索结论：

- 文章使用机载 lidar 估计海面 mean-square slope，并与 Cox-Munk、Bréon-Henriot 等经典结果比较。
- 实验不是单个场景，而是多个实验航次/区域的观测点，按风速和航向相对风向分组。
- 除 total MSS 外，还分析 upwind 与 crosswind slope variance，并讨论方向性比值。
- 文章还提醒高阶统计和白冠污染会影响 slope 估计，尤其高风速/白冠情况下更难处理。

可借鉴实验设置：

- 数据：不同实验中的机载测量；
- 组别：不同观测实验、不同相对风向、不同风速；
- 指标：upwind MSS、crosswind MSS、crosswind/upwind ratio；
- 基准：Cox-Munk、Bréon-Henriot；
- 表达方式：散点 + 拟合曲线 + 经验参考线。

对本文启发：

- 如果本文模型含风向，最好不要只给 total MSS，也应给沿风向与侧风向 MSS；
- Cox-Munk 可证明坡度统计合理，但白冠/卷浪会改变局部高阶统计，因此不能把 Cox-Munk 当作卷浪形态真值。

### 1.3 Reichl et al., JGR Oceans, 2014

题目：Sea state dependence of the wind stress over the ocean under hurricane winds

链接：https://agupubs.onlinelibrary.wiley.com/doi/10.1002/2013JC009289

检索结论：

- 文章在风应力/波谱参数化中计算 mean square slope，并用 Cox-Munk 作为风速范围内的合理性参考。
- 它讨论了不同谱尾水平对 MSS 的影响，说明 MSS 对短波/谱尾非常敏感。
- 高风速时 Cox-Munk 线性外推可能不再可靠，作者对此明确保留。

可借鉴实验设置：

- 对照组：不同谱尾参数；
- 指标：MSS vs wind speed；
- 重点：MSS 可以用于约束短波尾部，但高风速不能盲目外推。

对本文启发：

- 高海况/卷浪下，如果风速很高，不能简单声称“完全符合 Cox-Munk”；
- 更稳的说法是“在 Cox-Munk 适用或常用外推范围内保持合理坡度统计，同时通过卷浪专门指标验证破碎结构”。

### 1.4 Hauser et al., JGR Oceans, 2008

题目：A study of the slope probability density function of the ocean waves from radar observations

链接：https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2007JC004264

检索结论：

- 文章从 STORM radar observations 反演 slope PDF 和 MSS，并与 Cox-Munk、Wu 经验关系及不同谱模型比较。
- 每个样本对应 2-10 分钟、约 12-60 km 航迹观测。
- 验证方式包括 MSS 随风速、upwind/crosswind 分量、非高斯 slope PDF 参数。

可借鉴实验设置：

- 数据：雷达观测反演 slope；
- 指标：MSS、slope PDF、非高斯参数；
- 基准：Cox-Munk clean sea / slick sea；
- 对照：不同谱模型过滤或不过滤后计算 MSS。

对本文启发：

- 如果篇幅允许，可从“只验证 MSS”升级到“slope PDF 对比”；
- 对卷浪而言，高阶 slope PDF、skewness、kurtosis 可能比 MSS 更敏感。

### 1.5 Cox-Munk 使用方式小结

现有文献使用 Cox-Munk 的常见方式是：

1. 作为海面 slope statistics 的经验基准；
2. 计算模型生成海面或海谱积分得到的 MSS；
3. 画 MSS 随风速变化；
4. 区分 upwind / crosswind / total MSS；
5. 与 Cox-Munk、Bréon-Henriot、Wu 等经验关系比较；
6. 用相对误差或是否落入经验范围评价模型。

不常见也不合理的用法：

- 用 Cox-Munk 直接证明卷浪几何正确；
- 只给一个海况下的一张坡度图；
- 只验证完整模型，不放标准模型或无卷浪模型。

## 2. 幅度分布拟合验证相关文献

### 2.1 Liao et al., IEEE TGRS, 2023

题目：A Data-Driven Optimization Method for Simulating Arbitrarily Distributed and Spatial-Temporal Correlated Radar Sea Clutter

链接：https://dblp.org/rec/journals/tgrs/LiaoXZ23

检索结论：

- 这是近年的 IEEE Transactions on Geoscience and Remote Sensing 文章。
- 目标是生成具有任意分布和空间-时间相关性的雷达海杂波。
- 文章核心验证不是只看一张图，而是同时比较幅度分布、相位/相关性和空间-时间统计特征。
- 文章的思想对本文很重要：仿真海杂波的验证要回到 measured clutter 的统计特性，而不是只展示模拟纹理。

可借鉴实验设置：

- 数据：实测海杂波；
- 对照组：已有统计仿真方法 vs proposed data-driven method；
- 指标：幅度分布一致性、空间相关性、时间相关性；
- 结论方式：说明 proposed 方法在多统计维度上更接近实测数据。

对本文启发：

- 本文分布验证必须加入消融组：no-breaking vs with-breaking；
- 不能只证明 K 分布能拟合仿真数据，而要证明 with-breaking 的分布更接近实测高海况数据。

### 2.2 Ding et al., Sensors, 2020

题目：A Novel Reconstruction Method of K-Distributed Sea Clutter with Spatial-Temporal Correlation

链接：https://www.mdpi.com/1424-8220/20/8/2377

检索结论：

- 文章以 K 分布海杂波重构为目标，使用真实雷达数据提取幅度和相关性。
- 实测数据来自 2013 年辽宁葫芦岛毫米波雷达实验，雷达架设在约 230 m 高崖上，spotlight mode。
- 雷达参数包括 bandwidth 100 MHz、PRF 500 Hz、sample frequency 200 MHz、vertical polarization、beam width 3 deg、grazing angle 8 deg。
- 数据处理选择中间 400 个 range bins，80 s 数据，每个 range bin 40000 pulse samples。
- 对照组包括 STCPM、TCM、SCM 等方法。
- 验证指标包括 PDF、CDF、RMSE、KS、时间相关、空间相关、Doppler spectrum。
- 文章表格给出 STCPM、TCM、SCM 的 RMSE 和 KS，例如 STCPM 的 KS 为 0.0081，明显优于对照方法。

可借鉴实验设置：

- 数据集应说明雷达参数、range bins、pulse 数、选取区域；
- 对照组必须是不同仿真/重构方法；
- PDF/CDF 图后面必须跟 RMSE 和 KS 表；
- 还应比较 temporal/spatial correlation，而不是只比较幅度分布；
- 实测数据作为 reference，不是只拿理论分布作为 reference。

对本文启发：

- 本文 Sea State 5 应设置：measured、standard/no-breaking、with-breaking；
- 表格列出每组相对 measured 的 KS、RMSE、tail error、sea-spike rate；
- 如果只拟合 lognormal/Weibull/K，但不比较不同模型生成结果与 measured 的距离，说服力不够。

### 2.3 Rosenberg et al., Remote Sensing, 2019

题目：Modeling the Amplitude Distribution of Radar Sea Clutter

链接：https://www.mdpi.com/2072-4292/11/3/319

检索结论：

- 文章系统比较了多种海杂波幅度分布模型，包括 K、Pareto、K+Rayleigh、trimodal discrete 等。
- 数据来自 ground-based bistatic radar 和两个 airborne radar，覆盖 L/S/X 频段、不同几何和海况。
- 文章使用两个 goodness-of-fit 指标：Bhattacharyya distance 和 threshold error。
- 其中 threshold error 专门评价分布尾部，因为海上目标检测通常发生在分布尾部，sea spikes 和目标都影响高幅度尾部。

可借鉴实验设置：

- 数据：多频段、多平台、多几何实测数据；
- 对照组：多个分布模型；
- 指标：overall distribution error + tail-specific error；
- 目标：为 ship detection 场景选择能准确刻画尾部的 clutter model。

对本文启发：

- 本文不能只用整体 RMSE，因为卷浪主要影响强散射尾部；
- 必须加入 tail error 或 exceedance probability error；
- GRSL 中可以简化为 `top 1% / top 5% amplitude tail error`。

### 2.4 Conte et al., IEEE TAES, 2004

题目：Statistical analysis of real clutter at different range resolutions

链接：https://hdl.handle.net/11588/462207

检索结论：

- 这是 IEEE Transactions on Aerospace and Electronic Systems 文章。
- 使用 McMaster IPIX radar 的 Grimsby 数据库，分析不同 range resolution 下真实海杂波统计。
- 文章先证明 Rayleigh 偏离，再比较 K 与 Weibull 对一阶幅度统计的适用性。
- 进一步分析 I/Q 分量与 compound Gaussian / SIRP 模型兼容性，还做谱分析。

可借鉴实验设置：

- 数据：公开 IPIX/Grimsby 实测海杂波；
- 指标：幅度分布、I/Q 统计、compound Gaussian 检验、谱密度；
- 思路：分布拟合只是第一步，相关性和谱特性同样重要。

对本文启发：

- 如果本文定位为“雷达回波仿真”，除了分布拟合，最好补 ACF 或 Doppler/temporal spectrum；
- 如果篇幅不足，至少在 RTI 后加 sea-spike density 和 correlation length。

### 2.5 Yang et al., Radio Science, 2017

题目：Statistical distribution of polarization ratio for radar sea clutter

链接：https://agupubs.onlinelibrary.wiley.com/doi/10.1002/2017RS006371

检索结论：

- 文章使用真实海杂波数据，比较 Rayleigh、lognormal、Weibull、K 等典型分布。
- 使用 Kolmogorov-Smirnov 方法测试拟合效果。
- 表格报告 fitting probability 和 maximum fitting error。
- 结果表明某些数据和极化通道下 lognormal 比 K 更优，说明不能预设 K 一定最好。

可借鉴实验设置：

- 数据按极化通道 HH/VH 和不同数据组分别评价；
- 每个分布给出拟合概率和最大误差；
- 分布结论应与具体数据、极化和海况绑定。

对本文启发：

- 不要写“海杂波一定服从 K 分布”；
- 应写“在本文高海况 X-band HH 数据中，K 分布或 with-breaking 组更好刻画高幅度尾部”；
- 分布验证表格要按 Sea State 2 / Sea State 5 分开。

### 2.6 Sayama & Sekine, IEICE Transactions, 2002/2000

题目：Log-Normal, Log-Weibull and K-Distributed Sea Clutter；Weibull Distribution and K-Distribution of Sea Clutter Observed by X-Band Radar and Analyzed by AIC

链接：https://globals.ieice.org/en_transactions/communications/10.1587/e85-b_7_1375/_p

检索结论：

- 使用 X-band radar 观测高海况 Sea State 7 海杂波；
- grazing angle 覆盖 3.1-17.5 deg；
- 比较 log-normal、log-Weibull、K 等分布；
- 使用 Akaike Information Criterion, AIC，比最小二乘拟合更严格。

可借鉴实验设置：

- 数据按 grazing angle 分组；
- 分布模型按 AIC 排名；
- 观察到 grazing angle 改变时，分布参数和 Rayleigh 接近程度也改变。

对本文启发：

- 若数据允许，应按擦地角/海况分组；
- 可以考虑 AIC/BIC 作为 KS/RMSE 之外的模型选择指标。

### 2.7 分布拟合验证使用方式小结

现有文章常见设置是：

1. 明确实测数据来源、雷达参数、极化、擦地角、range bins、pulse 数；
2. 对实测数据先做 amplitude PDF/CDF；
3. 选择候选分布：Rayleigh、lognormal、Weibull、K、Pareto、compound Gaussian 等；
4. 用 MoM、MLE、zlogz、AIC 等估计参数；
5. 用 KS、RMSE、AIC、Bhattacharyya distance、tail error 等评价；
6. 如果是仿真方法，还要将不同仿真方法和 measured data 对比；
7. 经常额外验证 temporal/spatial correlation、Doppler spectrum 或 ACF。

对本文最关键的修正：

- 分布拟合不应只问“仿真数据像不像某个理论分布”；
- 应问“加入卷浪后的仿真数据是否比无卷浪仿真更接近实测高海况数据”；
- 因此分布验证表应以 measured data 为 reference，比较 no-breaking 与 with-breaking 的距离。

## 3. 卷浪 / 破碎浪验证相关文献

### 3.1 Callaghan & Deane et al., JGR Oceans, 2024

题目：A Comparison of Laboratory and Field Measurements of Whitecap Foam Evolution From Breaking Waves

链接：https://agupubs.onlinelibrary.wiley.com/doi/10.1029/2023JC020193

检索结论：

- 文章比较实验室破碎浪和海上 whitecap 的泡沫面积演化。
- 实验室数据来自 Scripps 波槽，使用 dispersive focusing 生成可控破碎浪；
- 野外数据来自 Martha's Vineyard Coastal Observatory，使用海面上方相机记录 whitecaps；
- 验证指标包括 foam area time series、growth time、decay time、maximum foam area、概率密度分布。
- 文章强调合适尺度归一化后，实验室与野外 whitecap area evolution 具有相似趋势。

可借鉴实验设置：

- 数据：实验室可控破碎浪 + 野外白冠图像；
- 指标：泡沫面积增长/衰减时间、最大泡沫面积、面积演化曲线；
- 对照：laboratory vs field；
- 用途：验证破碎浪可见白冠/泡沫统计。

对本文启发：

- 如果本文卷浪模型只改变几何而不模拟泡沫，可使用 whitecap coverage proxy 或 breaking coverage proxy；
- 对雷达回波而言，可把 whitecap/breaking coverage 与 sea-spike rate 建立联系。

### 3.2 Vargas-Magana et al., JGR Oceans, 2026

题目：Lagrangian Acceleration as a Diagnostic for Wave Breaking in the Nearshore Zone

链接：https://agupubs.onlinelibrary.wiley.com/doi/10.1029/2024JC022193

检索结论：

- 文章讨论 wave breaking criteria。
- 常见破碎起始判据是 kinematic breaking criterion：波峰附近水质点沿传播方向速度与波速之比 `U/c` 接近或超过 1。
- 这种判据在可控实验室环境中常用于破碎事件识别。
- 文章进一步使用 Lagrangian acceleration 作为破碎诊断量。

可借鉴实验设置：

- 数据：近岸波浪观测/粒子运动；
- 指标：`U/c`、Lagrangian acceleration；
- 目的：识别 breaking onset。

对本文启发：

- 本文卷浪触发条件若基于 `U/c > 1`，应把它作为物理判据验证；
- 可以统计 breaking occurrence rate 随风速增加是否合理；
- 若没有 PIV 速度场，至少应计算模型内部的 crest speed、surface particle velocity proxy 或 steepness threshold。

### 3.3 Varing et al., Coastal Engineering, 2021

题目：A new definition of the kinematic breaking onset criterion validated with solitary and quasi-regular waves in shallow water

链接：https://digitalcommons.uri.edu/oce_facpubs/103/

检索结论：

- 文章针对浅水 solitary 和 quasi-regular waves 验证新的 kinematic breaking onset criterion。
- 传统指标是 crest horizontal particle velocity `u_c` 与 phase velocity `c` 的比值。
- 文章强调 breaking onset criterion 需要用可识别的实验破碎事件进行验证。

可借鉴实验设置：

- 数据：孤立波和准规则波实验；
- 指标：`u_c/c`；
- 对照：不同破碎判据对 breaking onset 的识别准确性。

对本文启发：

- 如果本文提出了卷浪触发机制，应明确它与经典 `u_c/c` 判据的关系；
- 可以用“触发前/触发后”的波峰剖面变化证明模型确实响应破碎条件。

### 3.4 Wu & Nepf, JGR Oceans, 2002

题目：Breaking criteria and energy losses for three-dimensional wave breaking

链接：https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2001JC001077

检索结论：

- 文章研究三维破碎浪的破碎判据和能量损失。
- 使用 kinematic criterion，即 particle velocity 与 phase speed 之比；
- 通过 Hilbert transform 从测量的 surface displacement 中估计水平位移/速度；
- 分析破碎发生与能量损失。

可借鉴实验设置：

- 数据：三维方向波场测量；
- 指标：`u/c`、energy loss、方向波场的 Hilbert transform 分析；
- 用途：把自由面几何/速度与破碎发生联系起来。

对本文启发：

- 若本文模型想强调“三维卷浪”，可以使用三维面元上的破碎触发比例、局部能量损失 proxy 或遮挡面积比例；
- 破碎验证要从局部波峰出发，不应只看全局海面 MSS。

### 3.5 Skyner, Journal of Fluid Mechanics, 1996/2006 online

题目：A comparison of numerical predictions and experimental measurements of the internal kinematics of a deep-water plunging wave

链接：https://www.cambridge.org/core/journals/journal-of-fluid-mechanics/article/comparison-of-numerical-predictions-and-experimental-measurements-of-the-internal-kinematics-of-a-deepwater-plunging-wave/F4466FB9C2E65C894AD6458A07E61190

检索结论：

- 文章用 boundary integral numerical model 生成深水长峰破碎浪，并在波槽中复现实验。
- 使用 PIV 测量破碎过程中波峰、plunging spout 等区域的内部速度场。
- 数值预测和实验测量在 surface profile 对齐后进行比较，速度场吻合较好。

可借鉴实验设置：

- 数据：数值模型 + 波槽实验 + PIV；
- 指标：自由液面剖面、内部速度场、plunging jet/spout 形态；
- 对照：数值预测 vs 实验测量。

对本文启发：

- 卷浪几何验证可以使用 wave profile alignment 后的剖面对比；
- 如果没有速度场数据，也应至少比较波峰形状、翻卷位置、plunging lip 长度。

### 3.6 Brown et al., Journal of Waterway, Port, Coastal, and Ocean Engineering, 2018

题目：Simulating Breaking Focused Waves in CFD: Methodology for Controlled Generation of First and Second Order

链接：https://ascelibrary.org/doi/10.1061/%28ASCE%29WW.1943-5460.0000420

检索结论：

- 文章用 CFD 模拟 focused breaking waves，并与实验测量验证。
- 验证方式是在多个波高计位置比较数值和实验自由液面时序；
- 在 focus 附近比较破碎波峰是否发生 plunging；
- 比较 first-order 与 second-order wave generation 的影响。

可借鉴实验设置：

- 数据：实验波高计测量；
- 对照组：一阶生成、二阶生成、实验测量；
- 指标：surface elevation time series、focus point crest height、plunging occurrence。

对本文启发：

- 如果用数值/实验波槽数据验证卷浪，应比较多位置波面时序，而不是只放三维渲染；
- 可设置标准 Lie、本文无卷浪、本文有卷浪与实验 profile 的误差对比。

### 3.7 Schwendeman & Thomson, JGR Oceans, 2015

题目：Observations of whitecap coverage and the relation to wind stress, wave slope, and turbulent dissipation

链接：https://agupubs.onlinelibrary.wiley.com/doi/full/10.1002/2015JC011196

检索结论：

- 文章把 whitecap coverage `W` 作为破碎浪的可见观测量；
- `W` 是海面被白冠覆盖的面积比例；
- 文中讨论 W 与 10 m 风速、风应力、波陡、湍流耗散之间关系；
- 文章指出不同观测方法导致 W 参数化差异很大，但 whitecap coverage 仍是破碎浪研究中的常用统计指标。

可借鉴实验设置：

- 数据：海面图像 + 风速/波浪/湍流耗散观测；
- 指标：whitecap coverage、wind speed、wave slope、dissipation；
- 目标：验证破碎浪出现频率和覆盖比例。

对本文启发：

- 对雷达仿真而言，可定义 breaking area ratio 或 whitecap proxy；
- 与雷达侧指标 sea-spike rate 一起使用，可把卷浪区域和强散射尖峰联系起来。

### 3.8 卷浪验证使用方式小结

现有破碎浪/卷浪文章通常不使用 Cox-Munk 直接验证卷浪，而使用：

1. 破碎起始判据：
   - `u_c/c`；
   - crest speed；
   - Lagrangian acceleration；
   - steepness threshold。

2. 自由液面剖面对比：
   - numerical vs laboratory profile；
   - 多个波高计位置的 elevation time series；
   - wave crest alignment 后比较 plunging lip 和 crest shape。

3. 局部几何指标：
   - crest-front steepness；
   - crest-back steepness；
   - crest asymmetry；
   - local curvature；
   - overturning ratio；
   - plunging jet length；
   - breaking occurrence rate。

4. 白冠/泡沫指标：
   - whitecap coverage；
   - foam area time series；
   - maximum foam area；
   - growth/decay time；
   - breaking crest length density。

5. 能量/速度场指标：
   - PIV velocity field；
   - energy dissipation；
   - turbulent dissipation；
   - bubble plume depth。

对本文来说，最现实、最符合雷达目标的是：

- breaking occurrence rate；
- crest asymmetry；
- local curvature；
- overturning ratio；
- shadowed facet ratio；
- high-RCS crest ratio；
- sea-spike rate。

## 4. 推荐本文重新设置实验

### 4.1 Cox-Munk 实验

目的：

验证整体海面坡度统计是否合理。

数据/基准：

- Cox-Munk MSS；
- 可选 Bréon-Henriot 或 Wu MSS；
- 仿真海面。

对照组：

- Linear spectrum surface；
- Standard Lie transform；
- Proposed without breaking；
- Proposed with breaking。

指标：

- upwind MSS；
- crosswind MSS；
- total MSS；
- relative MSS error。

组别逻辑：

- Cox-Munk 不是卷浪真值，只是整体粗糙度约束；
- with-breaking 不能偏离 Cox-Munk 太多，否则说明卷浪几何破坏了整体海面统计；
- proposed without breaking 和 proposed with breaking 的差异不应只靠 MSS 说明，应在卷浪指标中体现。

### 4.2 卷浪专门实验

目的：

验证卷浪模块本身。

数据集选择：

- 优先：公开实验/数值波槽 breaking wave profile；
- 次选：文献中的 plunging breaker geometry；
- 最低限度：物理判据 + 消融对照。

推荐数据：

- Boettger numerical wave tank breaking-wave 数据；
- Guimaraes laboratory / breaking profile 数据；
- JFM / ASCE focused breaking wave 实验数据或图中剖面；
- 如果数据难获取，可用文献指标范围作弱监督。

对照组：

- Standard Lie；
- Proposed without affine curling；
- Proposed with breaking；
- Reference breaking profile / criterion。

指标：

- breaking occurrence rate；
- crest-front steepness；
- crest asymmetry ratio；
- local curvature；
- overturning ratio；
- shadowed facet ratio；
- high-RCS crest ratio。

### 4.3 分布拟合实验

目的：

验证雷达海杂波幅度统计，重点是卷浪对高幅度尾部的贡献。

数据集：

- NAU X-band HH staring radar sea clutter；
- 至少 Sea State 2 和 Sea State 5；
- 需要补充记录：擦地角、range resolution、PRF、pulse 数、range bins、风速/海况标签。

对照组：

- NAU measured；
- Standard Lie simulation；
- Proposed without breaking；
- Proposed with breaking。

候选分布：

- Rayleigh；
- lognormal；
- Weibull；
- K-distribution；
- 可选 Pareto / K+Rayleigh。

指标：

- PDF；
- CDF；
- KS；
- RMSE；
- tail error；
- sea-spike rate；
- 可选 AIC/BIC。

关键逻辑：

- Sea State 2：with-breaking 不应过度产生重尾；
- Sea State 5：with-breaking 应比 no-breaking 更接近 measured tail；
- 表格中应报告每组相对 measured 的误差，而不是只报告理论分布对仿真数据拟合得多好。

### 4.4 RTI 可视化实验

目的：

验证仿真 RTI 纹理是否接近实测，并展示卷浪贡献。

数据集：

- NAU measured RTI；
- 仿真 RTI。

图像组别：

建议两行四列：

| 行 | 列1 | 列2 | 列3 | 列4 |
| --- | --- | --- | --- | --- |
| Sea State 2 | Measured | Standard Lie | Proposed without breaking | Proposed with breaking |
| Sea State 5 | Measured | Standard Lie | Proposed without breaking | Proposed with breaking |

必须统一：

- dB 色标；
- range bins；
- pulse/time length；
- 归一化方式；
- 雷达参数；
- 海况标签。

辅助指标：

- sea-spike density；
- ACF / correlation length；
- RTI amplitude histogram Wasserstein distance；
- 可选 texture contrast。

关键逻辑：

- Sea State 5 下 no-breaking 应缺少密集强散射轨迹；
- with-breaking 应恢复更接近实测的 streaks、sea spikes 和慢时间调制；
- 可视化必须与定量 sea-spike density / ACF 一起出现。

## 5. 本文最应该采用的最低实验组合

如果 GRSL 篇幅有限，建议最低保留三组图/表：

1. Cox-Munk MSS 曲线：

   - `standard Lie / proposed without breaking / proposed with breaking / Cox-Munk bounds`
   - 说明整体坡度统计合理。

2. Sea State 5 分布消融表：

   - `measured / no-breaking / with-breaking`
   - 指标：KS、RMSE、tail error、sea-spike rate。
   - 说明卷浪改善高幅度尾部。

3. Sea State 5 RTI 消融图：

   - `measured / no-breaking / with-breaking`
   - 统一色标；
   - 旁边给 sea-spike density 或 ACF。
   - 说明卷浪改善 RTI 强散射纹理。

如果还能加一项：

4. 卷浪几何消融图：

   - `standard Lie / without breaking / with breaking`
   - 指标：crest asymmetry、overturning ratio、shadowed facet ratio。

## 6. 关键写作原则

1. Cox-Munk 只能证明整体 slope statistics 合理，不能证明卷浪；
2. 分布拟合必须以 measured data 为 reference，比较不同仿真组与实测的距离；
3. RTI 图必须是消融对照图，不能只是 simulated vs measured；
4. 卷浪模块必须有专门指标，否则创新点没有被验证；
5. 高海况 Sea State 5 是主验证场景，低海况 Sea State 2 是退化/不过度触发检查；
6. 对雷达文章来说，tail error、sea-spike rate、ACF 比单纯 PDF RMSE 更能支撑卷浪贡献。

## 7. 检索到的代表性文献清单

### Cox-Munk / 海面坡度统计

1. Ryabkova et al., 2019, JGR Oceans, A Review of Wave Spectrum Models as Applied to the Problem of Radar Probing of the Sea Surface.
2. Romero & Melville, 2019, Journal of Physical Oceanography, Airborne Measurements of Surface Wind and Slope Statistics over the Ocean.
3. Reichl et al., 2014, JGR Oceans, Sea state dependence of the wind stress over the ocean under hurricane winds.
4. Hauser et al., 2008, JGR Oceans, A study of the slope probability density function of the ocean waves from radar observations.
5. Cox & Munk, 1954, Journal of Marine Research, Statistics of the sea surface derived from Sun glitter.

### 雷达海杂波分布拟合 / 仿真验证

1. Liao et al., 2023, IEEE TGRS, A Data-Driven Optimization Method for Simulating Arbitrarily Distributed and Spatial-Temporal Correlated Radar Sea Clutter.
2. Wen et al., 2021, IEEE TGRS, Modeling of Correlated Complex Sea Clutter Using Unsupervised Phase Retrieval.
3. Liao et al., 2023, IEEE TAES, Compound-Gaussian Spatial-Temporal Correlated Complex Clutter Simulation Based on a Two-Step Data-Driven Method.
4. Ding et al., 2020, Sensors, A Novel Reconstruction Method of K-Distributed Sea Clutter with Spatial-Temporal Correlation.
5. Rosenberg et al., 2019, Remote Sensing, Modeling the Amplitude Distribution of Radar Sea Clutter.
6. Conte et al., 2004, IEEE TAES, Statistical analysis of real clutter at different range resolutions.
7. Yang et al., 2017, Radio Science, Statistical distribution of polarization ratio for radar sea clutter.
8. Sayama & Sekine, 2002, IEICE Transactions on Communications, Log-Normal, Log-Weibull and K-Distributed Sea Clutter.

### 卷浪 / 破碎浪验证

1. Callaghan & Deane et al., 2024, JGR Oceans, A Comparison of Laboratory and Field Measurements of Whitecap Foam Evolution From Breaking Waves.
2. Vargas-Magana et al., 2026, JGR Oceans, Lagrangian Acceleration as a Diagnostic for Wave Breaking in the Nearshore Zone.
3. Varing et al., 2021, Coastal Engineering, A new definition of the kinematic breaking onset criterion validated with solitary and quasi-regular waves in shallow water.
4. Wu & Nepf, 2002, JGR Oceans, Breaking criteria and energy losses for three-dimensional wave breaking.
5. Skyner, Journal of Fluid Mechanics, A comparison of numerical predictions and experimental measurements of the internal kinematics of a deep-water plunging wave.
6. Brown et al., 2018, Journal of Waterway, Port, Coastal, and Ocean Engineering, Simulating Breaking Focused Waves in CFD.
7. Schwendeman & Thomson, 2015, JGR Oceans, Observations of whitecap coverage and the relation to wind stress, wave slope, and turbulent dissipation.


