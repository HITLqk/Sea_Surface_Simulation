# GRSL 海面建模精简实验清单

## 1. 实验规模原则

本文按 5-6 页 IEEE GRSL Letter 设计验证，不做完整系统验收。正文只回答三个问题：

1. 生成的整体海面是否符合经典实测规律；
2. 新增卷浪是否比已有参数化方法更接近真实破碎浪；
3. 卷浪是否使仿真雷达回波在分布和 RTI 外观上更接近实测。

不做功率谱、二维功率谱、Doppler、时空相关性、效率和 AI 目标检测实验。全文验证部分控制为 `4` 张图和 `1` 张汇总表。

## 2. 统一组别

| 组别 | 内容 | 用途 |
|---|---|---|
| `R` | Cox-Munk、破碎浪观测或 NAV 实测数据 | 真实/经验参照 |
| `B` | Random-Stokes 2022 方法 | 唯一的近年文献 baseline |
| `G0` | 本文方法关闭卷浪 | 消融组 |
| `G1` | 本文完整方法，启用卷浪 | 完整组 |

`B` 对应文献 *The Dynamic Sea Clutter Simulation of Shore-Based Radar Based on Stokes Waves*, Remote Sensing, 2022, 14, 3915。选择它是因为它同样包含随机 Stokes 海面、参数化破碎浪和雷达回波生成，比 Standard Lie 和 CWM 更接近本文任务。

所有组使用相同风速、风向、海况、场景尺寸、雷达参数和随机相位。`B/G0/G1` 的差别只保留在海面与卷浪生成方法上。

## 3. 实验一：Cox-Munk 整体海面验证

### 目的

验证本文生成的背景海面坡度随风速变化是否合理。Cox-Munk 只验证整体海面，不用于证明卷浪形状正确。

### 组别

```text
Cox-Munk 经验曲线 / B / G0 / G1
```

### 设置

- 风速取 `5、10、15、20 m/s`；
- 每个风速生成 `20` 个随机海面并取平均；
- 计算沿风向、横风向和总均方斜率 MSS；
- `G1` 同时给出包含卷浪和屏蔽卷浪后的结果，避免整体卷浪尾部掩盖背景质量。

### 输出

**图 1：MSS-风速曲线。** 横轴为风速，纵轴为 MSS，叠加 Cox-Munk、`B`、`G0`、`G1`，使用误差棒表示随机样本波动。

只需附一个简单指标：相对 Cox-Munk 曲线的平均相对误差。这里不再增加坡度 PDF、频谱恢复或高阶矩实验。

## 4. 实验二：卷浪可视化与几何对比

### 目的

验证 `G1` 的卷浪不是人为加出的任意弯曲，而是在轮廓、尺度和方向上接近公开破碎浪观测，并优于 Random-Stokes 2022 的参数化破碎结构。

### 文献参照

- Guimarães 破碎浪数据：用于破碎斑块长度、宽度、面积和长宽比；
- McAllister et al., *Nature*, 2024：用于三维方向海况下的破碎外形和起始规律；
- Random-Stokes 2022：作为可运行的文献方法 `B`。

### 组别

```text
破碎浪观测 R / Random-Stokes B / 本文 G1
```

`G0` 没有卷浪，不需要硬放进卷浪外形比较，只在后面的雷达回波消融中出现。

### 设置

- 选择低、中、高三个典型破碎尺度；
- 每种尺度从 Guimarães 数据中确定一个代表区间；
- `B` 和 `G1` 在相同主波长、波高和传播方向下生成卷浪；
- 现有 120 个样本可以保留，但正文只展示三个代表尺度，统计曲线使用全部样本。

### 输出

**图 2：卷浪形态与尺度对比图。**

- 上排：文献/实测参考、`B`、`G1` 的三维外形或主传播方向剖面；
- 下排：卷浪面积和长宽比的实测 CDF，叠加 `B` 与 `G1`；
- 所有三维图使用同一坐标比例和观察角度。

只报告面积与长宽比两个数值指标的 KS 距离。长度、宽度、高差、曲率等可以保留在数据文件中，不全部放进 Letter。

核心判断为：

```text
KS(G1, 实测) < KS(B, 实测)
```

如果拿不到 McAllister 的原始数据，只把它用于定性外形参照，不从论文图片反推精确分类率。

## 5. 实验三：幅度分布与 RTI 实测对比

### 目的

直接证明引入卷浪以后，回波比无卷浪组和近年文献方法更接近 NAV 实测数据。

### 组别

```text
NAV 实测 R / Random-Stokes B / 无卷浪 G0 / 完整模型 G1
```

### 设置

- 从 NAV 中选择低海况和高海况各一组；
- `B/G0/G1` 使用完全相同的环境和雷达参数；
- 每组使用相同脉冲数、距离单元和归一化方式；
- 代表性 RTI 按固定随机种子或中位误差样本选取，不能人工挑最好看的结果。

### 输出一：幅度分布

**图 3：幅度 PDF/CDF 或 CCDF。** 每个海况分别叠加实测、`B`、`G0` 和 `G1`。

指标只保留两个：

- KS 距离；
- RMSE。

K、Weibull、log-normal 可以作为虚线拟合辅助观察，但不再分别画多套拟合图，也不把“各自拟合良好”当成仿真接近实测的证据。

### 输出二：RTI

**图 4：高海况 RTI 四联图。** 按相同色标排列：

```text
(a) NAV 实测  (b) Random-Stokes B  (c) G0  (d) G1
```

RTI 以可视化对比为主，只附一个容易解释的统计量：超过实测 95% 幅度阈值的强散射点比例。它用于说明 `G1` 是否恢复了实测中的海尖峰密度，不再增加轨迹、相关性和二维功率谱指标。

## 6. 一张汇总表

| 海况 | 方法 | Cox-Munk 相对误差 | 卷浪面积 KS | 卷浪长宽比 KS | 回波分布 KS | 回波 RMSE | 强散射点比例误差 |
|---|---|---:|---:|---:|---:|---:|---:|
| 低/高 | `B` |  |  |  |  |  |  |
| 低/高 | `G0` |  | 不适用 | 不适用 |  |  |  |
| 低/高 | `G1` |  |  |  |  |  |  |

正文通过这张表回答两个最重要的比较：

```text
G1 是否优于 G0：卷浪模块是否有效
G1 是否优于 B：是否优于近年同任务文献方法
```

## 7. 实际运行清单

- [ ] 按 Random-Stokes 2022 公式实现或整理 `B`，先复现原文一个示例；
- [ ] 跑 4 个风速、每组 20 个样本，生成图 1；
- [ ] 把现有 120 个卷浪样本整理为低、中、高三档，补跑 `B`，生成图 2；
- [ ] 从 NAV 选择低、高两个海况，生成 `B/G0/G1` 回波；
- [ ] 计算 KS、RMSE 和强散射点比例，生成图 3、图 4及汇总表。

这五步就是当前 GRSL 需要跑的全部核心实验。

## 8. 核心参考文献

1. Cox, C., and Munk, W. Measurement of the Roughness of the Sea Surface from Photographs of the Sun's Glitter. *JOSA*, 1954.
2. Ryabkova, M., et al. A Review of Wave Spectrum Models as Applied to the Problem of Radar Probing of the Sea Surface. *JGR: Oceans*, 2019. https://doi.org/10.1029/2018JC014804
3. The Dynamic Sea Clutter Simulation of Shore-Based Radar Based on Stokes Waves. *Remote Sensing*, 2022, 14, 3915. https://doi.org/10.3390/rs14163915
4. McAllister, M. L., et al. Three-Dimensional Wave Breaking. *Nature*, 2024, 633, 601-607. https://doi.org/10.1038/s41586-024-07886-z
5. Angelliaume, S., Rosenberg, L., and Ritchie, M. Modeling the Amplitude Distribution of Radar Sea Clutter. *Remote Sensing*, 2019, 11, 319. https://doi.org/10.3390/rs11030319

