# 局部卷浪双指标验证代码

## 实验定义

代码只设置严格配对的两个表面：

- G0：同一个随机海面、同一个波峰，不施加卷曲；
- G1：在 G0 的同一个波峰上施加卷曲。

没有 weak、moderate、strong 三个验证组。G1 使用连续参数 `chi`，每个蒙特卡洛样本计算：

```text
Gb = CurlRcs_dBsm - PreRcs_dBsm
```

所有局部面元均由 G0 的材料坐标窗口选定，G1 沿用相同面元，因此不会因移动窗口或改变面积范围产生虚假增益。第二个验证量是全部配对样本形成的 `Gb(chi)` 响应关系。

## 运行

在 MATLAB 中进入本目录并执行：

```matlab
results = run_local_curl_dual_metric_validation();
```

快速检查可使用：

```matlab
quick = struct();
quick.sampleCount = 6;
quick.maximumAttempts = 30;
quick.output = struct('figureVisible','off','savePdf',false);
results = run_local_curl_dual_metric_validation(quick);
```

程序会自动定位相邻的 `Curl` 目录，并调用：

```text
default_elfouhaily_ideal_curl_config.m
generate_elfouhaily_ideal_curl_surface.m
```

## 输出

`output` 目录包括：

- `local_curl_dual_metric_raw.csv`：每个配对样本的 `Gb`、`chi` 和几何诊断量；
- `local_curl_dual_metric_summary.csv`：连续 `chi` 分箱后的中位数和四分位区间；
- `local_curl_dual_metric_results.mat`：完整 MATLAB 结果；
- `local_curl_dual_metric_validation_final.png/.pdf`：模型 `Gb(chi)` 与文献阶段范围，以及 Literature/Present model 两类增益分布的两栏对比图。文献阶段不再映射为模型 `chi`。

## 散射量边界

当前散射核严格沿用项目现有 `Echo_Caculate.m` 中的面元定义：

```text
sigma_i = Area_i * cos(theta_i)^2
```

它是固定单通道的局部面元 RCS proxy，本实验不进行极化比较。`10 GHz` 仅作为后续替换散射核时的实验条件元数据，当前 proxy 本身不随频率变化。

因此，当前结果能够验证：

- G0/G1 严格配对后，卷曲几何是否改变局部面元响应；
- `Gb` 的蒙特卡洛分布；
- `Gb` 随连续卷曲控制参数 `chi` 的变化。

当前结果不能声称复现 West 2002 或 Li and West 2006 的全波数值。与 Kim and Johnson 2002 的比较只支持“局部增强量级相近”，不支持“绝对 NRCS 已验证”。

## 文献参考值提取

当前已完成的提取为：

- 原图裁剪：`reference/source_figures/Kim_Johnson_2002_Fig8a_HH.png`；
- 逐点数据：`reference/digitized/Kim_Johnson_2002_Fig8a_HH.csv`；
- 主程序参考表：`reference/literature_gb_reference.csv`；
- 口径和限制：`reference/REFERENCE_EXTRACTION_AUDIT.md`。

新增文献曲线时使用以下流程：

1. 将论文中的目标 figure 保存或裁剪为清晰的 PNG，放入 `reference/figures`；
2. 复制并填写 `example_digitize_literature_curve.m` 中的坐标范围和 pre/mature stage；
3. 运行 `digitize_literature_scattering_curve`，依次点击 x-min、x-max、y-min、y-max 刻度，再沿目标曲线点击；
4. 每条曲线保存到 `reference/digitized`；
5. 运行：

```matlab
build_literature_gb_reference();
```

程序会将文献原始散射量先转换到 dB，再在每篇论文内部计算：

```text
Gb_ref(x) = S_ref,dB(x) - S_ref,dB(pre)
chi_ref   = (x - x_pre)/(x_mature - x_pre)
```

最终生成 `reference/literature_gb_reference.csv`，模型验证主程序会自动读取并叠加这些参考曲线。

坐标标定信息和原图路径会保存为 `_metadata.mat`，CSV 同时保留原始横纵轴值及像素坐标，便于检查和重新数字化。禁止从摘要描述猜测数值，也不能把 EGO/GTD 拟合曲线误选为 West 2002 的高可信数值电磁参考。

Sletten 2003 的 plunging-breaker 时域回波不应冒充 absolute RCS。只有原文明确完成绝对标定、且阶段和 breaker 类型匹配的数据才能作为定量参考；否则只作趋势说明。
