# 20260705ServerExport 代码读取与复用分析

## 1. 分析范围

源目录：

```text
E:\_Projects\MatlabProject\SeaClutterSimulation\20260705ServerExport
```

后续验证目录：

```text
E:\_Projects\MatlabProject\SeaClutterSimulation\20260824_Veryfication
```

本次只读取和分析源目录，没有修改源代码，也没有向后续验证目录写入文件。后续验证目录目前存在，但为空。

## 2. 总体结论

该目录已经具有完整的工程骨架：

```text
Elfouhaily 海谱
  -> 随机二维海面
  -> 三角面元与局部擦地角
  -> TSC 后向散射
  -> LFM 回波矩阵
  -> 幅度分布与 RTI 绘图
```

可以复用海谱公式、面元处理、TSC 函数、回波矩阵组织方式和绘图外壳。但是当前版本不能直接用于论文验证，主要原因是：

1. 没有真正的破碎触发和三维卷浪实现；
2. TSC 输出单位使用错误，现有 RCS 数据被计算成复数；
3. Cox-Munk 脚本中的 proposed 和 baseline 实际使用同一个谱函数；
4. 分布脚本比较的是“仿真数据与拟合分布”，不是“仿真与实测”；
5. RTI 的时间变化主要来自人工随机速度或高斯散斑，不是动态海面与卷浪运动。

因此，后续应当“复用模块并统一接口”，不能直接复制已有 `.mat` 结果作为验证数据。

## 3. 文件功能与复用判断

| 模块 | 主要文件 | 当前功能 | 复用结论 |
|---|---|---|---|
| 一维海谱 | `Elfouhaily.m`、`PiersonMoskowitz.m`、`Bretschneider.m` | 计算基础波数谱 | 可复用公式，需加输入检查 |
| 二维方向谱 | `Elfouhaily2D.m`、`Elfouhaily2D_swell2.m`、`ECKV.m`、`SwellDirection.m` | 方向扩展和涌浪调制 | 需修正复数方向谱问题后复用 |
| 随机海面 | `generateSeaSurfaceS0_Swell.m`、`ConjugateSymmetric_zyg.m`、`generateSeaSurface2DSwell_t.m` | 固定随机系数并按色散关系生成时变谱面 | 可作为 G0 背景海面骨架 |
| 普通二维海面 | `generateSeaSurface2D.m` | 直接生成 Elfouhaily 随机面，支持随机种子 | 可用于小型单元测试 |
| 卷浪 | `yonglang_3d.m` | 只调用普通谱面并绘图 | 不含卷浪，不能作为 G1 |
| 面元几何 | `seaReflecty.m`、`seaReflecty_First_Step.m` | 三角剖分、中心、法向、面积和擦地角 | 思路可复用，建议改写为函数 |
| 海面散射 | `TSC_SigmaSea.m` | 输出 TSC 海杂波反射系数，单位为 dB | 函数可复用，调用处必须修正单位 |
| 回波生成 A | `seaReflecty_Second_Step_PH.m` | 给静态面元分配随机径向速度并合成 LFM 回波 | 仅复用波形和矩阵结构 |
| 回波生成 B | `generateEcho.m` | 用固定面元和高斯相关散斑生成 RTI | 可作工程参考，不作为物理动态 G1 |
| Cox-Munk | `cox_munk.m` | 绘制 MSS-风速曲线 | 必须重写 |
| 分布验证 | `sim_analyse.m`、`K_distribution2.m`、`wbl.m`、`lognormal.m` | K/Weibull/log-normal 拟合及图形 | 拟合函数可作辅助，主比较逻辑必须重写 |
| 实测 RTI | `Data/plot_real_data_rti*.m` | 读取 NAV 数据并绘图 | 绘图外壳可复用，幅度对齐方式需修改 |

## 4. 已核实的关键问题

### 4.1 当前目录没有真正的卷浪模型

`yonglang_3d.m` 只执行：

```matlab
[S0,k,eps] = generateSeaSurfaceS0_Swell(...);
[h,x,y] = generateSeaSurface2DSwell_t(...);
surf(x,y,h);
```

代码中没有 breaking criterion、局部坐标变换、affine curl、翻卷空腔或遮挡处理。后续 G1 必须从现有的独立卷曲代码迁入，不能把此文件改名后当作卷浪模型。

### 4.2 TSC 的 dB/线性单位混用

`TSC_SigmaSea.m` 返回的是 dB 值，但 `seaReflecty.m` 和 `seaReflecty_First_Step.m` 将其当作线性反射系数：

```matlab
ref = TSC_SigmaSea(...);       % 实际为 dB
rcs = 10*log10(ref .* S);      % 错误：对负 dB 再取 log10
```

只读核验现有数据得到：

- `SeaSurfaceRCS_Data.mat` 的 130050 个 `rcs` 全部带虚部；
- `seaSurfaceRCSData.mat` 的 4802 个 `rcs` 全部带虚部；
- 4802 个面元中有 226 个 `ref` 已带虚部；
- 原因还包括把负擦地角直接送入含分数次幂的 TSC 公式。

正确接口应为：

```matlab
sigma0_dB = TSC_SigmaSea(...);
sigma0_linear = 10.^(sigma0_dB/10);
rcs_linear = sigma0_linear .* facet_area;
rcs_dBsm = 10*log10(max(rcs_linear, realmin));
```

背向面元和被遮挡面元必须先屏蔽，不能把负擦地角送入 TSC。

目录中另有 `SeaSurface_RCS_Data.mat`，其变量已经改成 `rcs_linear/rcs_dBsm/S_area`，数值为实数，但当前目录没有生成它的对应源脚本。因此该文件只能作为调试线索，不能作为可复现实验入口。

### 4.3 方向谱会产生复数

`SwellDirection.m` 使用：

```matlab
cos((phi-phiw)/2).^(2*s_e)
```

当底数为负且指数不是整数时，结果为复数。对 `N=16` 的小网格核验，`S0` 中有 128 个复数元素，最大虚部约为 `0.1148`。随后 `generateSeaSurface2DSwell_t.m` 使用 `real(ifft2(...))`，相当于直接丢弃异常虚部。

迁移时需要统一方向角范围，并确保方向扩展函数非负、实数且积分归一化，例如对有效半平面使用截断，或使用绝对值/周期化形式，但具体形式必须与论文公式一致。

### 4.4 `cox_munk.m` 的两条仿真曲线不是真正的方法对比

脚本中 `f1` 和 `f2` 都调用同一个 `Elfouhaily`：

```matlab
f1 = @(k) k.^2.*Elfouhaily(k,U(i),age);
f2 = @(k) k.^2.*Elfouhaily(k,U(i),age);
```

两条曲线的差别只来自积分上下限/采样设置，却被标注为“所提方法”和“standard Lie transform”。这张图不能继续用于论文。

新脚本应直接从 `B/G0/G1` 实际生成的表面计算坡度，再与 Cox-Munk 曲线比较，不能只积分同一个输入谱后更换图例。

### 4.5 `sim_analyse.m` 的 KS 和 RMSE 回答了错误的问题

当前脚本分别用 K、Weibull 和 log-normal 拟合仿真幅度，然后比较拟合曲线与仿真直方图。它回答的是“哪种理论分布最适合仿真数据”，不是“哪种仿真方法更接近实测”。

此外，`kstest2(cpdf,cdfk)` 把 CDF 的纵坐标数组当作原始样本，统计含义不正确。后续主验证应直接对 NAV、`B`、`G0`、`G1` 的归一化幅度样本使用 `kstest2`；RMSE 则在统一横坐标上的经验 PDF/CDF 之间计算。

### 4.6 现有 RTI 不是动态卷浪 RTI

`seaReflecty_Second_Step_PH.m` 只生成一次静态海面，然后给每个面元随机分配径向速度。`generateEcho.m` 同样使用固定面元，并用预设 `fd=15 Hz` 的高斯滤波随机散斑制造慢时间变化。

这两种方式可以生成“看起来在变化”的回波矩阵，但不能证明卷浪的运动进入了 RTI。后续 G0/G1 至少需要使用同一组时刻的动态海面几何和面元位置，或明确把慢时间散斑模型作为共享回波层，使三组差异只来自海面几何。

### 4.7 实测 RTI 的峰值强制平移不能用于定量比较

`plot_real_data_rti*.m` 把每个实测片段的最大值平移到 `-70 dBW`。这种操作可以用于统一视觉色标，但会抹掉绝对幅度差异，也会改变固定阈值强散射比例的解释。

后续可选择：

- 若比较形态：所有组按同一规则归一化，并明确标注 normalized amplitude；
- 若比较绝对功率：完成雷达增益、传播损耗和噪声底标定，不再逐图对齐最大值。

当前 GRSL 以经典可视化为主，建议采用第一种方案。

## 5. 三项精简验证与现有代码的映射

| 验证 | 可复用代码 | 必须新增/修正 |
|---|---|---|
| 图 1 Cox-Munk | `Elfouhaily.m`、随机海面生成器、`cox_munk.m` 绘图格式 | 实际表面坡度计算；`B/G0/G1` 独立输入；20 个随机种子；均值和误差棒 |
| 图 2 卷浪外形/CDF | 普通海面背景、`surf`/`patch` 绘图 | 迁入真正 G1 卷曲；实现 Random-Stokes 2022 的 B；读取 Guimarães 数据；面积与长宽比 CDF/KS |
| 图 3 幅度 PDF/CDF | `sim_analyse.m` 的直方图和拟合外壳 | NAV/B/G0/G1 直接叠加；正确的两样本 KS；统一归一化 |
| 图 4 RTI 四联图 | `generateEcho.m` 的 LFM 框架、`plot_real_data_rti*.m` 的绘图外壳 | 修正 TSC 单位；统一 HH 极化；统一色标/归一化；使用同一参数和样本选择规则 |

## 6. 建议的后续验证目录结构

后续开始实施时，建议在 `_Veryfication` 中建立：

```text
20260824_Veryfication/
  config/
    validation_config.m
  src/
    surface/
    breaking/
    scattering/
    echo/
    metrics/
  baselines/
    random_stokes_2022/
  data/
    measured/
    breaking_reference/
  experiments/
    exp01_cox_munk.m
    exp02_breaking_geometry.m
    exp03_distribution_rti.m
  results/
    figures/
    tables/
    mat/
  tests/
```

源目录中的代码应复制后修改，保留 `20260705ServerExport` 作为只读历史快照。

## 7. 建议的第一步实施任务

正式开始验证时，不应先跑大规模海面。第一步应完成一个统一的小网格 smoke test：

1. 修正方向谱为实数、非负并归一化；
2. 修正 TSC dB/线性转换及背向面元屏蔽；
3. 把背景海面、卷浪变换、面元散射封装为函数；
4. 用同一个随机种子输出 `G0/G1` 的海面、RCS 和短 RTI；
5. 确认所有数组均为有限实数，尺寸和单位写入结果文件。

这个 smoke test 通过后，再运行 Cox-Munk、卷浪 CDF 和 NAV 对比，能避免在错误中间结果上反复作图。

