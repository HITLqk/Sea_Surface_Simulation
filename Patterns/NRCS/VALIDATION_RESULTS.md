# 局部卷浪双指标验证结果

## 实验设置

- 配对组：G0 no-curl 与 G1 with-curl；
- 每一对使用相同随机海面、相同波峰、相同局部材料窗口和相同雷达视向；
- 没有 weak、moderate、strong 离散验证组；
- G1 的卷浪控制参数 `chi` 在 `[0.15, 1.00]` 内分层连续采样；
- 蒙特卡洛样本数：`N = 60`；
- 固定局部窗口：传播向 `3.2 m`，峰线向 `6.4 m`；
- 观测条件元数据：`10 GHz`、`12 deg` 擦地角、up-wave；
- 散射量采用现有回波程序中的面元代理定义：

```text
sigma_i = Area_i * cos(theta_i)^2
```

该定义为固定单通道局部 RCS proxy，本实验不比较极化。

## 指标一：局部散射增强量

```text
Gb = CurlRcs_dBsm - PreRcs_dBsm
```

60 组结果为：

| 统计量 | 结果 |
|---|---:|
| Median `Gb` | `5.069 dB` |
| Q25 | `2.312 dB` |
| Q75 | `6.919 dB` |
| Minimum | `0.127 dB` |
| Maximum | `9.046 dB` |
| `P(Gb > 0)` | `1.000` |

在当前参数范围和散射代理下，全部 G1 样本的局部积分响应均高于严格配对的 G0。

## 指标二：散射增强与连续卷浪参数

`Gb(chi)` 的统计关系为：

| 指标 | 结果 |
|---|---:|
| Pearson correlation | `0.9794` |
| Spearman correlation | `0.9823` |
| Linear trend slope | `10.592 dB/chi` |

八个连续 `chi` 分箱的中位 `Gb` 依次为：

```text
0.295, 1.465, 3.067, 4.532,
5.572, 6.559, 7.305, 8.025 dB
```

这说明当前几何变换与现有面元 RCS proxy 之间存在清晰、稳定的连续响应，而不是由离散强度组或更换随机海面造成的跳变。

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

本文模型的中位 `Gb` 为 `5.069 dB`，比文献派生中位数低 `1.031 dB`；模型四分位区间 `[2.312, 6.919] dB` 落在文献阶段范围 `[2.250, 7.850] dB` 内。两者增强量级一致，但后半段趋势并不完全一致。

必须保留以下边界：Fig. 8(a) 原量是最大图像幅度，`Gb_ref` 是本文为了比较而派生的指标，不是原作者定义的绝对 NRCS 指标。West and Zhao 2002 的“多数条件误差小于 2 dB”只作为数值方法精度基线；Li et al. 2017 的约 2 dB 增量属于整体海面 NRCS，不混入局部卷浪参考曲线。

## 输出文件

- `output/local_curl_dual_metric_raw.csv`
- `output/local_curl_dual_metric_summary.csv`
- `output/local_curl_dual_metric_results.mat`
- `output/local_curl_dual_metric_validation_final.png`
- `output/local_curl_dual_metric_validation_final.pdf`
- `reference/digitized/Kim_Johnson_2002_Fig8a_HH.csv`
- `reference/literature_gb_reference.csv`
- `reference/REFERENCE_EXTRACTION_AUDIT.md`
