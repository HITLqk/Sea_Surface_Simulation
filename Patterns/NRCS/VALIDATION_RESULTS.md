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
| Median `Gb` | `0.052 dB` |
| Q25 | `0.007 dB` |
| Q75 | `0.099 dB` |
| Minimum | `-0.044 dB` |
| Maximum | `0.247 dB` |
| `P(Gb > 0)` | `0.817` |

上述结果使用 2026-09-03 版卷浪生成器。当前 `Area*cos(theta)^2` 散射代理对新几何的局部积分变化很小，不能支持“卷浪产生数 dB 局部增强”的结论。

## 指标二：散射增强与连续卷浪参数

`Gb(chi)` 的统计关系为：

| 指标 | 结果 |
|---|---:|
| Pearson correlation | `0.5759` |
| Spearman correlation | `0.5447` |
| Linear trend slope | `0.1519 dB/chi` |

八个连续 `chi` 分箱的中位 `Gb` 依次为：

```text
-0.001, 0.049, 0.046, 0.042,
0.042, 0.024, 0.107, 0.164 dB
```

响应总体随 `chi` 增大，但离散较明显且增强量很弱。连续趋势存在，不等于完成了文献量级验证。

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

本文模型的中位 `Gb` 为 `0.052 dB`，比文献派生中位数低 `6.048 dB`；模型四分位区间 `[0.007, 0.099] dB` 不在文献阶段范围 `[2.250, 7.850] dB` 内。因此，更新后的实验明确显示当前面元代理不能复现文献中的局部卷浪散射增强量级。

最终图不再把 LONGTANK wave stage 归一化后与模型 `chi` 共用横坐标。左图只以 `chi` 表示模型连续响应，文献值作为不依赖 `chi` 的水平阶段范围和中位数；右图以 Literature/Present model 两个类别比较增益分布。

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
