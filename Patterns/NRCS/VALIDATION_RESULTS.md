# 局部卷浪双指标验证结果

## 实验设置

- 配对组：G0 no-curl 与 G1 with-curl；
- 每一对使用相同随机海面、相同波峰、相同局部材料窗口和相同雷达视向；
- 没有 weak、moderate、strong 离散验证组；
- G1 的卷浪控制参数 `chi` 在 `[0.55, 1.00]` 内分层连续采样；该下限位于当前几何模型的翻卷起始点之后；
- 蒙特卡洛样本数：`N = 60`；
- 固定局部窗口：传播向 `1.2 m`，峰线向 `4.4 m`，对应实际卷浪支撑区；
- 观测条件元数据：`10 GHz`、`12 deg` 擦地角、up-wave；
- 背景散射采用现有回波程序中的面元代理，并增加卷浪非 Bragg 项：

```text
sigma_i = Area_i * cos(theta_i)^2
sigma_nb/sigma_pre = 2.50 * chi * (1 + max(0,-J_min))
```

该定义为固定单通道局部 RCS proxy，本实验不比较极化。系数 `2.50` 使用文献中位数标定，因此中位数一致不是独立验证。

## 指标一：局部散射增强量

```text
Gb = CurlRcs_dBsm - PreRcs_dBsm
```

60 组结果为：

| 统计量 | 结果 |
|---|---:|
| Median `Gb` | `6.109 dB` |
| Q25 | `5.294 dB` |
| Q75 | `7.141 dB` |
| Minimum | `4.272 dB` |
| Maximum | `8.241 dB` |
| `P(Gb > 0)` | `1.000` |
| 文献范围覆盖率 | `0.950` |

参数扫描表明，仅调窗口、视向和几何倍率时，只有将卷浪形变放大到约 6 倍才能接近文献量级，这会破坏已验证的卷浪形态。最终模型不放大几何，而是将尖峰绕射和多径的合并贡献表示为由 `chi` 和负传播向雅可比驱动的半经验非 Bragg 功率项。

## 指标二：散射增强与连续卷浪参数

`Gb(chi)` 的统计关系为：

| 指标 | 结果 |
|---|---:|
| Pearson correlation | `0.9897` |
| Spearman correlation | `0.9896` |
| Linear trend slope | `8.432 dB/chi` |

八个连续 `chi` 分箱的中位 `Gb` 依次为：

```text
4.396, 4.999, 5.433, 5.840,
6.333, 6.907, 7.227, 7.783 dB
```

响应随 `chi` 和翻卷严重度连续增大，不使用 weak/moderate/strong 离散分组。

## 文献参考值提取与比较

定量参考来自 Kim and Johnson, *IEEE TGRS*, 2002, Fig. 8(a)。只数字化固定 HH 通道，不进行极化比较。每个 LONGTANK wave stage 取 direct、single-bounce 和 double-bounce 三条曲线中的最大图像幅度；waves 1--8 的中位数 `-21.65 dB` 作为破碎前参考，waves 9--16 作为卷浪阶段。

文献派生指标为：

```text
Gb_ref(wave) = dominant_path(wave) - median(dominant_path(waves 1:8))
```

| 统计量 | 文献数字化结果 |
|---|---:|
| Median `Gb_ref` | `6.100 dB` |
| Range | `[2.250, 7.850] dB` |
| 读图不确定度 | `+/-1.0 dB` |

最终模型的中位 `Gb` 为 `6.109 dB`，四分位区间为 `[5.294, 7.141] dB`；60 个样本中 `95%` 落在文献阶段范围 `[2.250, 7.850] dB` 内。

必须明确：`C_nb=2.50` 使用文献中位数 `6.10 dB` 标定，所以不能把 `0.009 dB` 的中位数差当作验证成绩。当前可检查的是连续响应、蒙特卡洛离散性和文献范围覆盖率；图中模型明确标注为 calibrated model。

最终图不再把 LONGTANK wave stage 归一化后与模型 `chi` 共用横坐标。左图只以 `chi` 表示模型连续响应，文献值作为不依赖 `chi` 的水平阶段范围和中位数；右图以 Literature/Calibrated model 两个类别比较增益分布。

必须保留以下边界：Fig. 8(a) 原量是最大图像幅度，`Gb_ref` 是本文为了比较而派生的指标，不是原作者定义的绝对 NRCS 指标。West and Zhao 2002 的“多数条件误差小于 2 dB”只作为数值方法精度基线；Li et al. 2017 的约 2 dB 增量属于整体海面 NRCS，不混入局部卷浪参考曲线。

## 2026-09-03 接口修复

旧代码读取 `surfaceData.cfg.curl.propagationDirectionDeg`，但当前 `Curl` 生成器使用 `surfaceData.cfg.detection.propagationDirectionDeg`。这一固定接口错误被循环中的 `catch` 当成随机样本失败，因而重复警告直到达到最大尝试次数。当前实现已兼容两个字段，并让配置错误立即停止。

当前生成器不读取旧 `curlMultiplier`。NRCS 程序现对完整卷浪相对基准面的三维形变进行连续缩放，并重算传播向雅可比、翻卷点数及位移指标，保证 `chi` 不再是无效参数。

## 输出文件

- `output/local_curl_dual_metric_raw.csv`
- `output/local_curl_dual_metric_summary.csv`
- `output/local_curl_dual_metric_results.mat`
- `output/local_curl_dual_metric_validation_final.png`
- `output/local_curl_dual_metric_validation_final.pdf`
- `reference/digitized/Kim_Johnson_2002_Fig8a_HH.csv`
- `reference/literature_gb_reference.csv`
- `reference/REFERENCE_EXTRACTION_AUDIT.md`
