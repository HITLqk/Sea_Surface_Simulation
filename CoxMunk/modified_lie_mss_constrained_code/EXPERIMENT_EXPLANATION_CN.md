# `modified_lie_mss_constrained_code` 实验与曲线说明

## 一句话结论

这套实验包含两个仿真组：未约束的线性 Elfouhaily 基准组，以及经过 Modified Lie 变换并被经验 MSS 规律约束的非线性组。右侧非线性曲线之所以贴近 Cox-Munk、Hu/TGRS 和 Guerin，是因为这些规律已经参与了非线性组的校准。因此，这张图能说明“经验约束生效”，不能作为同一批经验规律上的独立验证。

## 1. 实验设置

- 风速：`U10 = 1, 2, ..., 10 m/s`，共 10 个风速点。
- 随机实现：每个风速使用 20 个随机种子。
- 组别：每个种子生成两个配对组，共 `10 x 20 x 2 = 400` 条原始记录。
- 配对原则：同一风速、同一种子下，两组共享相同的随机频谱系数，减少随机海面差异对组间比较的干扰。
- 主波网格：`256 x 256`，波数步长 `dk = kp/12`，满足论文提出的谱峰采样要求。
- 短波：使用多个独立倍频程小网格，一直合成到 `pi x 1000 rad/m`，用于补足光学尺度 MSS。

每条原始记录包含：顺风 MSS、侧风 MSS、总 MSS、方向性指数 `gamma`、主波 MSS 和短波 MSS。

## 2. 两个组分别是什么

### 组 A：`Linear Elfouhaily`

这是基准组。

1. 根据风速生成二维方向性 Elfouhaily 谱。
2. 用复高斯随机数对频谱采样。
3. 保证 Fourier 系数满足 Hermitian 对称，得到实数海面。
4. 直接由频谱系数计算顺风和侧风 MSS。

该组没有使用 Cox-Munk、Hu/TGRS 或 Guerin 对结果进行缩放。因此，它与黑色点线 `Elfouhaily integral` 的比较属于生成器自一致性检查；它与其他实测规律的比较才具有外部对照意义。

### 组 B：`MSS-Constrained Modified Lie`

这是“Modified Lie + MSS 经验约束”组，不是单纯的 Modified Lie 原始输出。

处理顺序为：

1. 从与 Linear 组相同的主波频谱开始。
2. 使用二维 Riesz/Hilbert 分量计算二阶 Lie/Creamer 非线性项，改变波峰、波谷及频率间相位耦合。
3. 计算未经约束的非线性顺风和侧风 MSS。
4. 构造经验融合目标：
   - `1-2 m/s`：Cox-Munk 与 Hu/TGRS 分量的平均；
   - `3-10 m/s`：Cox-Munk、Hu/TGRS 与 Guerin 分量的平均。
5. 将非线性 MSS 向该融合目标收缩。
6. 使用正值方向谱修饰函数
   `|G(phi)|^2 = exp(lambda0 + lambda2*cos(2phi))`
   分别匹配顺风和侧风目标，同时保持 Fourier 相位不变。

默认参数 `mssResidualFraction = 0.15` 的含义是：只保留原始非线性结果相对经验目标的 15% 对数偏差，约 85% 的偏差被校准掉。概念上可写成：

```text
约束后 MSS = 经验目标 x (原始 MSS / 经验目标)^0.15
```

所以该组曲线靠近绿色融合线是代码设计的直接结果。

## 3. 第一张图：总 MSS 曲线

横轴是 10 m 高度风速 `U10`，纵轴是总均方斜率：

```text
Total MSS = MSS_along + MSS_cross
```

### 两个面板

- 左图 `Linear Elfouhaily`：20 次线性仿真的统计结果。
- 右图 `MSS-Constrained Modified Lie`：20 次受约束非线性仿真的统计结果。

两个面板使用相同坐标范围，便于横向比较。

### 图例逐项解释

- 蓝色或橙色圆点实线 `Simulation median`：20 个随机实现的中位数，不是单次仿真。
- 深色阴影 `IQR`：第 25% 到第 75% 分位区间，表示中间一半随机实现。
- 浅色阴影 `5%-95%`：第 5% 到第 95% 分位区间，表示大部分随机波动范围。它不是置信区间，也不是测量误差条。
- 黑色点线 `Elfouhaily integral`：代码所用 Elfouhaily 谱的连续积分理论值，用于检查随机频谱合成是否正确。
- 黑色虚线 `Cox-Munk`：航空太阳闪光实测得到的经验总 MSS。
- 红色点划线 `TGRS/Hu`：TGRS 文章汇总并采用的 Hu 分段总 MSS 规律。
- 蓝色空心方块 `Guerin IASI`：Guerin 红外遥感结果；本图只在 `3-10 m/s` 有数据。
- 绿色虚线 `Empirical fusion target`：上述 Cox-Munk、Hu/TGRS 和可用 Guerin 分量的平均值。它是组 B 的校准目标，不是第四套独立观测。

### 这张图表达了什么

Linear 组基本贴近 Elfouhaily 积分，说明多尺度频谱生成和 MSS 计算是自洽的；但它在高风速端高于 Cox-Munk、Hu/TGRS 和 Guerin。

受约束 Modified Lie 组贴近绿色经验融合目标，因而相对三套经验规律的 RMSE 更小。具体结果为：

| 组别 | Cox-Munk RMSE | Guerin RMSE | TGRS/Hu RMSE | 融合目标 RMSE |
|---|---:|---:|---:|---:|
| Linear Elfouhaily | 0.00560 | 0.00523 | 0.00383 | 0.00456 |
| MSS-Constrained Modified Lie | 0.00223 | 0.00188 | 0.00227 | 0.000628 |

这里的 RMSE 改善说明“约束算法工作正常”。因为融合目标本身由这些参考规律构造，不能据此宣称 Modified Lie 被这些数据独立验证。

## 4. 第二张图：方向性指数 `gamma`

方向性指数定义为：

```text
gamma = sqrt(MSS_cross / MSS_along)
```

- `gamma = 1`：顺风、侧风斜率方差相同，接近各向同性。
- `gamma < 1`：顺风 MSS 大于侧风 MSS；数值越小，风向性越强。

### 图中各元素

- 蓝/橙圆点线：每个风速下 20 次仿真的 `gamma` 中位数。
- 黑色点线：Elfouhaily 谱积分得到的方向性。
- 蓝色空心方块：Guerin 方向性。
- 红色水平线 `0.864`：TGRS 汇总的跨模型平均值。
- 紫色水平线 `0.84`：TGRS 文中典型模拟海面值。

Linear 组从约 `0.77` 增长到 `0.84`，反映原始 Elfouhaily 方向扩展函数的行为。

受约束 Modified Lie 组从低风速约 `0.95` 下降到 `10 m/s` 时约 `0.84`。这条曲线主要由“顺风、侧风分量分别向经验融合目标收缩”产生，特别是低风速 Cox-Munk 侧风分量中存在常数项，导致融合目标相对更接近各向同性。因此，低风速的高 `gamma` 不能直接解释为卷浪物理规律。

## 5. 第三张图：海面和中心剖面

每一行对应一个风速：上行为 `5 m/s`，下行为 `10 m/s`。

- 左列：Linear Elfouhaily 主波海面高度。
- 中列：受约束 Modified Lie 主波海面高度。
- 右列：同一行中心位置的一维高程剖面，蓝线是 Linear，橙线是 Modified Lie。

这张图只显示主波网格的高程，不包含所有短波倍频程网格的空间拼接；短波只以方向斜率方差的形式进入总 MSS。

正值方向谱修饰保持 Fourier 相位，仅调整不同方向的幅度，所以两幅海面会比较相似。Modified Lie 引起的波峰/波谷变化可以在中心剖面的局部差异中看到，但当前图不能证明发生了真实几何翻卷或破碎，因为海面仍是单值高度函数 `z = h(x,y)`，没有显示悬垂面、自交面、白沫或破碎区域。

## 6. 应当如何给这些组命名

论文中建议使用以下名称，避免误解：

- **B0: Linear Elfouhaily baseline**
- **M0: Raw Modified Lie**，当前代码计算了它，但没有作为独立曲线输出
- **M1: MSS-constrained Modified Lie**，当前右图实际展示的组

目前图中只有 B0 和 M1。若把 M1 简称为“所提非线性方法”，读者容易误以为其 MSS 是模型自然预测出来的，实际上其中包含经验校准。

## 7. 这套实验能证明什么，不能证明什么

### 可以证明

1. 线性多尺度 Elfouhaily 生成器能够恢复自身理论 MSS。
2. Modified Lie 后的频谱可以在保留相位的同时，被稳定约束到指定的顺风和侧风 MSS。
3. 约束后的模型不会再出现非线性 MSS 随风速爆炸的问题。
4. Monte Carlo 离散性被保留，但由于 `0.15` 收缩系数，M1 的带宽会明显窄于 Linear。

### 不能证明

1. 不能用 Cox-Munk、Hu/TGRS 和 Guerin 同时校准 M1，再用同一批规律声称 M1 得到了独立验证。
2. 不能根据 MSS 贴合说明 Modified Lie 的卷浪几何正确。
3. 不能根据第三张高度图证明海浪已发生真实破碎。
4. 不能说明 M1 优于其他卷浪模型，因为当前没有独立 baseline 或留出数据。

## 8. 更合理的验证定位

建议把当前实验写成“物理统计约束/校准实验”，而不是最终独立验证：

1. **校准指标**：Cox-Munk、Hu/TGRS、Guerin 的总 MSS 和方向 MSS，用于限制模型二阶斜率能量。
2. **内部检查**：Elfouhaily 谱积分与 Linear 组的一致性。
3. **独立验证指标**：不参与校准的坡度 PDF、偏度、峰度、波峰-波谷不对称性、破碎面积率/白帽覆盖率、局部破碎判据和雷达 RTI 特征。
4. **必要消融组**：增加 Raw Modified Lie，形成 `Linear -> Raw Lie -> MSS-constrained Lie` 三组，才能分别说明 Lie 变换带来了什么、经验约束修正了什么。

## 9. 输出表的读取方法

- `two_group_raw.csv`：400 条单次结果，适合检查随机散布和配对差异。
- `two_group_summary.csv`：每个组、每个风速的中位数和分位区间，共 20 行，是画图数据。
- `two_group_reference.csv`：所有参考规律和融合目标。
- `two_group_assessment.csv`：两组对不同参考曲线的 RMSE。
- `two_group_validation.mat`：MATLAB 完整工作区结果和示例海面。

最简单的读图顺序是：先看 Linear 是否贴近 Elfouhaily 积分，再看 M1 是否贴近绿色融合目标，最后看 `gamma` 是否处于可接受范围。不要把 M1 与绿色线的贴合作为独立验证结论。
