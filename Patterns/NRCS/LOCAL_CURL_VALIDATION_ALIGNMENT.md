# 局部卷曲区域雷达回波验证执行口径

## 1. 本次校准结论

后续 NRCS/RCS 验证以用户提供的《局部卷曲区域雷达回波验证任务 Prompt》为准。此前以白沫覆盖率或大面积破碎统计定义 effective breaker NRCS 的方案不作为本文主验证路线，因为这些文献中的 breaking region 与本文显式构造的 pre-impact plunging curl 几何并不等价。

本文验证对象固定为从随机海面中提取的局部卷曲窗口：

```text
same random sea realization
+ same physical crest
+ same local window
+ same radar condition
```

唯一变化为是否施加 curl transformation：

```text
pre-breaking / non-curl  vs.  curl / plunging breaker
```

## 2. 主验证量

最优先指标为同一原始量内部的相对增强：

```text
G_b = S_curl,dB - S_pre,dB
```

其中 `S` 保持各参考文献和本文计算的原始定义，可以是 RCS、局部 NRCS、二维单位长度散射量或三维 MLFMA 输出。不同定义之间不直接比较绝对值；只有在同一归一化方式、同一单位和匹配雷达条件下才比较绝对散射量。

本文自己的局部归一化量定义为：

```text
sigma0_local = Sigma(Omega_b) / A_Omega_b
```

优先采用水平投影面积作为 `A_Omega_b`，因为它与常规 NRCS 的单位水平面积定义一致。若后续采用实际曲面面积，必须对所有组保持一致并单独声明。

## 3. 局部窗口

局部窗口使用以波峰为中心的传播向/峰线向坐标：

```text
u: propagation direction
v: crestwise direction
```

窗口覆盖 crest、forward face、overturning lip 及其直接影响区域，不包含过多普通背景海面。窗口大小按主波长无量纲化：

```text
L_u / lambda_p
L_v / lambda_p
```

所有 weak、moderate、strong 卷浪使用同一窗口定义规则，不按结果逐个调窗。

## 4. 三层参考基线

### 4.1 West 2002

- 对象：二维 plunging breaker crest；
- 性质：高可信数值电磁散射基线；
- 用途：提取 pre-breaking、crest steepening、lip formation 和 mature plunging 阶段的原文散射量与相对增强；
- 注意：若原文是二维单位长度散射系数，不转换为三维 NRCS。

### 4.2 Li and West 2006

- 对象：三维有限峰线 plunging breaker；
- 性质：MLFMA 全波数值基线；
- 用途：提取三维成熟卷浪增强、三维/二维差异及不同方位响应；
- 这是与本文有限长度三维 crest 最接近的数值 reference。

### 4.3 Sletten et al. 2003

- 对象：高速光学图像和标定雷达同步观测的真实 breaking wave；
- 性质：实验基线；
- 用途：提取 pre-breaking 到 lip/jet/impact 前的局部回波增强和形态-回波对应关系；
- 本文只使用 impact 前阶段，不把 splash-up、foam 或 post-breaking scar 作为几何模型验证对象；
- 若原文给 absolute RCS，则保留 dBsm 并优先比较 breaker/pre-breaking 差值，不强制转换成 NRCS。

## 5. 本文实验组

每个随机海面和候选波峰形成一组严格配对样本：

| 组别 | 几何 | 作用 |
|---|---|---|
| G0 Pre-breaking | 非线性背景波峰，未施加 curl | 配对基线 |
| G1 Weak curl | 同一波峰，弱卷曲参数 | 对应 early/weak stage |
| G2 Moderate curl | 同一波峰，中等卷曲参数 | 对应 forming lip/moderate stage |
| G3 Strong curl | 同一波峰，强卷曲参数 | 对应 pre-impact mature plunging stage |

四组使用相同局部窗口、雷达频率、擦地角、方位、极化、网格和散射算法。weak/moderate/strong 只建立静态形态阶段对应，不声称模拟真实时间动力学。

如果 Letter 版面过紧，正文图中可只保留 G0、Moderate 和 Strong，完整四组数据保留在代码输出或补充材料中。

## 6. 指标优先级

正文主指标：

1. 局部增强 `G_b`；
2. weak/moderate/strong 的阶段趋势。

辅助诊断量：

3. 局部峰值增强 `G_peak`；
4. 强回波面积占比 `R_A`。

`G_peak` 和 `R_A` 用于检查强回波是否集中在 crest/front-face 附近，不应为了版面完整而全部放入正文。

## 7. 与此前方案的明确区别

- 不计算整个海面的平均 NRCS 作为卷浪主验证；
- 不以 Cox-Munk 式整体坡度统计替代局部卷浪散射；
- 不使用白沫覆盖率 `Q` 反演作为主定义；
- 不把 surf-zone bore、whitecap、foam 或 post-impact turbulent scar 与本文 pre-impact curl 混为同一类 breaker；
- 不把 Ka/Ku 波段统计破碎贡献直接当作本文 X 波段局部绝对值范围；
- 不强行统一 West、Li and West、Sletten 三篇论文的原始散射量单位；
- 跨文献统一比较 `breaking - pre-breaking` 的相对增强和阶段趋势。

## 8. 编码前的文献提取任务

必须先逐篇核对并形成 extraction sheet：

- 完整引用和准确题名；
- breaker profile 来源和二维/三维定义；
- stage；
- frequency/wavelength；
- grazing/incidence angle 及其定义；
- azimuth/look direction；
- polarization；
- window/surface size；
- 原始散射量名称、公式、归一化和单位；
- pre-breaking、mature-breaking 和 peak 数值；
- 相对增强；
- 图号、表号和可数字化性；
- experimental、full-wave numerical 或 simplified theory 属性；
- 可作为 absolute、relative-enhancement 还是 trend baseline。

任何未从原文确认的参数一律标记为待核实，不根据二手文献或摘要补猜。

## 9. 后续代码位置

后续 MATLAB 代码和结果统一放在：

```text
E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication\NRCS
```

在完成三篇论文的参数与纵轴定义提取之前，不开始调参生成目标增强曲线。
