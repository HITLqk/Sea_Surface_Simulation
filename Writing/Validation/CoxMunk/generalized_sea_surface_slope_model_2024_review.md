# Gao et al. (TGRS 2024) 广义海面斜率模型阅读与引用建议

## 1. 文献信息

Hong Gao, Ninghui Li, Tinglu Zhang, Djordje Romanic, Jonathon S. Wright,
and Lei Guan, "A Generalized Model of Sea Surface Slopes and Its
Application to Sun Glint Correction on HY-1C/COCTS Imagery," IEEE
Transactions on Geoscience and Remote Sensing, vol. 62, 2024,
Art. no. 5651816, DOI: 10.1109/TGRS.2024.3510455.

## 2. 与本研究的相似性

这篇文章适合作为本研究的重要参考文献，原因不是它同样引用了
Cox-Munk，而是其研究链条与当前海面建模工作高度相似：

1. 采用二维 FFT 和波谱模型生成离散随机海面；
2. 使用 Elfouhaily 波谱及方向扩展函数；
3. 从实际生成的空间海面计算顺风、横风和总 MSS；
4. 在多个风速、波龄和传播方向条件下生成多次随机实现；
5. 将仿真统计量与多种经验 MSS 模型和观测规律比较；
6. 不仅验证 MSS，还验证方向各向异性和完整斜率概率分布；
7. 最终将海面统计模型用于遥感前向问题，即太阳耀斑计算与校正。

本研究后续将仿真海面用于雷达回波和目标检测数据生成，与其“海面建模
到遥感应用”的总体技术路线相近。区别是该文面向光学太阳耀斑，没有
显式建模卷浪、破碎几何或雷达散射。

## 3. 文章提出的广义斜率模型

### 3.1 各向异性指数

文章定义：

\[
\gamma=\sqrt{\frac{\sigma_c^2}{\sigma_a^2}}
=\frac{\sigma_c}{\sigma_a},
\]

其中 \(\sigma_a^2\) 和 \(\sigma_c^2\) 分别为顺风和横风 MSS。

文章汇总的现场观测、16 种 MSS 模型及仿真结果表明：

- 在约 1--14.3 m/s 范围内，\(\gamma\) 大致分布于 0.64--1.2；
- 多种模型和观测的平均值约为 0.864；
- 典型充分发展风浪仿真约为 0.84；
- Cox-Munk 在排除低风速非局地风残余影响后约为 0.78；
- \(\gamma\) 与风速的相关性较弱，比总 MSS 更稳定；
- 长波涌浪增强顺风 MSS、减小横风 MSS，因此会降低 \(\gamma\)。

### 3.2 由总 MSS 和 gamma 表示的二维 PDF

文章用总 MSS \(\sigma^2=\sigma_a^2+\sigma_c^2\) 和 \(\gamma\) 重写二维
高斯斜率 PDF：

\[
p(z_x,z_y)=\frac{\gamma+\gamma^{-1}}{2\pi\sigma^2}
\exp\left[-\frac{z_x^2(1+\gamma^2)+z_y^2(1+\gamma^{-2})}
{2\sigma^2}\right].
\]

这个表达把分方向 MSS 转换为两个更容易跨海况比较的参数：

- 总 MSS 控制斜率/倾角分布宽度；
- \(\gamma\) 控制方位方向性。

文章还将其转换成倾角 \(\theta\) 和方位角 \(\phi\) 的联合分布，用于太阳
耀斑 BRDF 计算。该思路同样可用于本研究的面元法向量和雷达入射角分布。

## 4. 可新增的 MSS baseline

文章比较了 16 种 MSS 模型。对当前研究最有价值的是 Hu et al. 的
CALIPSO LiDAR 分段关系，因为它包含更宽的波数范围，并在低风速和
13.3 m/s 以上表现为非线性：

\[
10^3\sigma^2=\begin{cases}
14.6\sqrt{U_{10}}, & U_{10}<7\ \mathrm{m/s},\\
3+5.12U_{10}, & 7\le U_{10}<13.3\ \mathrm{m/s},\\
138\log_{10}U_{10}-84, & U_{10}\ge13.3\ \mathrm{m/s}.
\end{cases}
\]

它具有三个适合当前验证的特征：

1. 低风速不强制线性；
2. 中等风速与 Cox-Munk 总 MSS 一致；
3. 13.3 m/s 以后转入对数增长，比 Cox-Munk 线性外推更平缓。

因此，Hu baseline 可以补充当前的 Guérin 低中风速实测点和 Davis 高风
带限参数化。但应注明它是 LiDAR 宽频总 MSS，仍需检查与仿真波数带宽
是否一致。

## 5. 文章的实验设置

### 5.1 海面仿真

- 二维 FFT 随机海面；
- Elfouhaily 波谱；
- 风速范围为 1--15 m/s；
- 每个风速生成十余个不同海面状态；
- 使用有限差分从生成海面计算顺风和横风 MSS；
- 考察风浪发展程度、波龄和传播参数；
- 典型风浪、充分发展重力波和长波涌浪作为不同条件组。

这支持当前采用“每个风速多个随机实现 + 散点/误差条/箱线统计”的实验
设计，而不是每个风速只生成一个海面后连接均值曲线。

### 5.2 验证层次

文章的验证逻辑分为四层：

1. 比较 16 种 MSS-风速经验模型；
2. 检查仿真 MSS 是否位于已有模型的合理范围；
3. 检查各向异性指数是否与现场观测及模型统计一致；
4. 比较仿真斜率/角度直方图与广义 PDF，并通过 HY-1C 图像太阳耀斑
   校正展示下游应用效果。

该逻辑比只验证总 MSS 更完整，适合借鉴到本研究。

## 6. 对当前验证代码的直接增量

当前代码已经输出 `MssAlong`、`MssCross` 和 `MssTotal`，因此可以直接
新增：

\[
\gamma=\sqrt{\frac{\mathrm{MssCross}}{\mathrm{MssAlong}}}.
\]

建议增加以下输出和图表：

1. 每次随机实现的 \(\gamma\)；
2. 每个风速的 \(\gamma\) 中位数、IQR 和 5%--95% 区间；
3. `gamma=0.864` 的广义模型参考线；
4. `gamma=0.84` 的典型风浪仿真参考线；
5. `gamma=0.78` 的 Cox-Munk 参考线；
6. Hu 分段总 MSS 参考曲线；
7. 面元面积加权的二维 \((z_a,z_c)\) 斜率直方图；
8. 广义 PDF 与 Cox-Munk/Gram-Charlier PDF 的分布误差。

二维分布可采用以下指标：

- Jensen-Shannon divergence；
- Hellinger distance；
- 顺风和横风边缘分布的 KS 距离；
- 斜率模长和方位角分布误差；
- 极端坡度分位数误差。

这会将现有验证从“MSS 幅值是否正确”扩展为“MSS、方向性和分布形状
是否同时正确”。

## 7. 对四组实验的使用方式

### Linear、G0 Nonlinear、G1 Background

三组均可与 Hu MSS、\(\gamma\) 参考区间和广义 PDF 比较。重点判断
非线性变换及卷浪插入是否破坏背景海面的方向统计。

### G1 Upward

G1 Upward 是局部陡峭面元条件子集，不应要求其 \(\gamma\) 或 PDF 服从
全海面广义模型。应单独报告它相对于背景 PDF 的偏移、尾部增强和方位
集中程度。

## 8. 作为 reference 还是 baseline

### 可以作为 baseline 的内容

- Hu et al. 分段总 MSS；
- \(\gamma=0.864\) 广义方向性基准；
- 文章式 (8) 的二维广义斜率 PDF；
- 1--15 m/s、每风速十余个仿真实现的实验组织方式。

### 只能作为 reference 的内容

- HY-1C/COCTS 太阳耀斑校正结果；
- 文章自身的 FFT 仿真海面；
- 16 种模型的视觉汇总图。

原因是该文的海面统计验证主要依赖模型互比和仿真，不是完全独立的
实测海面真值。它适合证明方法设计与验证框架有近期 TGRS 先例，但不能
单独替代 Guérin、Cox-Munk 或 Davis 的观测数据。

## 9. 建议在论文中的位置

1. **Introduction**：作为近期 TGRS 中“广义海面斜率 PDF + 遥感应用”
   的代表工作，说明海面统计建模仍是活跃问题。
2. **Model**：引用其总 MSS + 各向异性指数的参数化方式，解释为什么
   不能只验证总 MSS。
3. **Validation**：引用其多风速、多随机实现、16 baseline 和 PDF 对比
   设计；增加 Hu baseline 与 \(\gamma\) 指标。
4. **Discussion**：指出该文聚焦光学、低中风速和单值随机海面，本研究
   进一步处理卷浪破碎几何及雷达回波。

## 10. 最终判断

这篇文章应纳入核心参考文献，而不是普通背景引用。它为本研究提供了
三个此前验证方案中缺少的要素：

1. 近期 TGRS 中与 Elfouhaily-FFT 海面建模高度相似的方法先例；
2. 可直接计算的方向各向异性指标 \(\gamma\)；
3. 从 MSS 曲线验证扩展到二维斜率 PDF 验证的明确路径。

最值得立即加入当前代码的是 Hu 分段 MSS baseline 和 \(\gamma\) 统计；
二维 PDF 对比可作为随后“分布验证”部分的主实验。
