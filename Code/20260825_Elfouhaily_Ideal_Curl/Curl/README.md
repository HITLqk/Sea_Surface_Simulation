# 二维 Elfouhaily 海面局部卷浪

本模块在二维 Elfouhaily 随机海面上自动选择具备破碎几何特征的波峰，并对局部结构网格施加有限支撑的参数化卷曲。它不使用一维高斯波横向复制，也不把卷曲结果重新压缩成单值高度场。

## 卷浪位置判定

对轻度平滑后的海面，沿主传播方向计算一阶和二阶导数。候选点必须同时满足：

```text
z_s >= q_0.88(z_s)
abs(z_u) <= 0.32 std(z_u)
z_uu <= -q_0.70(max(-z_uu,0))
```

评分函数联合考虑高程、负曲率和前向肩部坡度：

```text
Q = 0.50 Q_height + 0.35 Q_curvature + 0.15 Q_forward_slope.
```

程序在联合候选中选择最高评分事件，然后逐个波峰向截面跟踪真实脊线 `u_c(v)`。这套条件用于放置 breaking-eligible event，是静态几何代理，不是普适的流体破碎起始判据。

## 局部卷曲

卷曲前先通过宽过渡窗改变周围非卷曲表面，使前坡、后坡和迎浪肩部连续演化。卷唇由三部分组成：

1. 局部水平前移，使参数曲面在传播方向发生平滑折返；
2. `Ideal_Curl_Wave_Echo.m` 风格的传播向-垂向同角旋转；
3. 与局部波高成比例的小幅卷唇下落。

支点深度、水平前移和卷唇下落均由检测到的局部波高 `Hlocal` 缩放。默认实现删除了旧代码的 `verticalAngleRatio` 和 `pivotDepth=0.915 m`，并使用核心窗 `Wc` 与更宽的过渡窗 `Wt`。卷曲后的结果保存为 `(X,Y,Z)` 参数曲面，三角面连接沿用原结构网格。

几何翻卷由传播方向映射雅可比判断：

```text
J_u = d(u_final)/du < 0.
```

## 默认运行结果

固定随机种子 `20260825` 的结果为：

- 选中波峰：`(20.900, 25.300, 0.176) m`；
- 估计局部波高：`0.1225 m`；
- 自适应支点深度：`0.0796 m`；
- 最大前向位移：`0.2432 m`；
- 最大向下位移：`0.0242 m`，即 `0.198 Hlocal`；
- 最小传播雅可比：`-0.0844`；
- `J_u<0` 的翻卷网格点：`28` 个；
- 紧支撑区域外位移：数值零。

## 文件

- `default_elfouhaily_ideal_curl_config.m`：海面、判定和卷曲参数；
- `generate_elfouhaily_ideal_curl_surface.m`：海面生成、候选判定、脊线跟踪和参数曲面卷曲；
- `run_elfouhaily_ideal_curl_demo.m`：运行断言并分别绘制五张图。

## 输出图

- `01_breaking_location_conditions.png`：高度、近零坡度、负曲率以及联合候选与最终选址；
- `02_elfouhaily_selected_crest.png`：原始海面和选中波峰；
- `03_elfouhaily_local_curled_surface.png`：完整卷曲海面；
- `04_local_curl_center_section.png`：卷曲前后中心参数剖面；
- `05_local_curl_closeup.png`：局部三维卷浪与 `J_u<0` 网格点；
- `elfouhaily_local_curl.mat`：完整结构体数据。

## 运行

```matlab
run_elfouhaily_ideal_curl_demo
```
