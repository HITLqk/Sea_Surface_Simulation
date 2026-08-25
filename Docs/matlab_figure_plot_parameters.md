# MATLAB Figure 绘图参数说明

对应程序：`Curl/run_elfouhaily_ideal_curl_demo.m`。

## 1. Figure 窗口

```matlab
function fig = new_figure(visibility,position)
fig = figure('Visible',visibility,'Color','w','Position',position);
set(gca,'FontName','Times New Roman','FontSize',12, ...
    'LineWidth',0.8,'Layer','top');
end
```

- `Visible`：控制窗口是否弹出，当前由 `cfg.output.figureVisible='on'` 控制。
- `Color='w'`：将 Figure 画布背景设为白色。`w` 是 white 的缩写。
- `Position=[left bottom width height]`：默认单位为像素，前两个数是窗口左下角在屏幕上的位置，后两个数是宽度和高度。

四个窗口的尺寸分别是：

```matlab
new_figure(cfg.output.figureVisible,[80 80 1040 720]);
new_figure(cfg.output.figureVisible,[110 110 1040 720]);
new_figure(cfg.output.figureVisible,[140 140 920 620]);
new_figure(cfg.output.figureVisible,[170 170 1040 720]);
```

三维图为 `1040 x 720 px`，二维截面图为 `920 x 620 px`。逐次增大的 `left` 和 `bottom` 使多个窗口弹出时稍微错开。

## 2. 坐标轴样式

```matlab
set(gca,'FontName','Times New Roman','FontSize',12, ...
    'LineWidth',0.8,'Layer','top');
```

- `gca`：当前坐标轴句柄。
- `FontName`：坐标刻度、轴标签等使用 Times New Roman。
- `FontSize=12`：默认字号为 12 pt。
- `LineWidth=0.8`：坐标轴边框和刻度线宽。
- `Layer='top'`：坐标轴和网格置于图形上层，避免被曲面遮挡。

当前代码只显式设置了 Figure 背景。坐标轴背景使用 MATLAB 默认白色；如需固定，可在 `set(gca,...)` 中增加 `'Color','w'`。

## 3. 三维曲面

```matlab
surf(X,Y,Z,Z,'EdgeColor','none');
axis tight;
pbaspect([1 1 0.28]);
view(44,26);
grid on;
colormap(turbo);
colorbar;
```

- 第四个 `Z` 是曲面颜色数据，即按高度着色。
- `EdgeColor='none'`：隐藏网格边，避免出现密集黑线。
- `axis tight`：坐标范围贴合数据边界。
- `pbaspect([1 1 0.28])`：将绘图框的 x:y:z 视觉比例设为 1:1:0.28，压缩竖直显示高度。它改变显示比例，不改变数据。
- `view(44,26)`：方位角 44 度，仰角 26 度。
- `turbo`：使用 Turbo 伪彩色表；`colorbar` 显示色标。

局部近景图使用：

```matlab
xlim([min(patchX)-0.35,max(patchX)+0.35]);
ylim([min(patchY)-0.35,max(patchY)+0.35]);
zlim([min(patchZ)-0.06,max(patchZ)+0.06]);
axis vis3d;
view(105,18);
```

`xlim/ylim/zlim` 限制显示范围，`axis vis3d` 在旋转视角时保持三维比例，`view(105,18)` 用更低的仰角观察卷唇。

## 4. 二维截面线

```matlab
plot(uBase,zBase(order),'Color',[0.25 0.25 0.25],'LineWidth',1.2);
plot(uCurl(order),zCurl(order),'r-','LineWidth',1.9);
xlim([-1.4 1.8]);
grid on;
```

- 背景海面为 RGB `[0.25 0.25 0.25]` 深灰色，线宽 1.2 pt。
- 卷曲海面为红色实线 `r-`，线宽 1.9 pt，使其成为视觉重点。
- `xlim([-1.4 1.8])` 保留更多正 `u` 方向空间，用于展示向前探出的卷唇。

波峰检测标记使用：

```matlab
plot3(x,y,z,'kp','MarkerFaceColor','w', ...
    'MarkerSize',12,'LineWidth',1.4);
```

`k` 表示黑色，`p` 表示五角星标记，内部填充白色，标记尺寸为 12。

## 5. PNG 导出

```matlab
exportgraphics(figHandle,fileName,'Resolution',180);
```

`Resolution` 是导出分辨率，单位为 DPI。当前两张整体海面图为 180 DPI，截面图为 200 DPI，局部近景为 220 DPI。这个参数影响导出图片的清晰度和文件大小，不改变 MATLAB 弹出窗口的尺寸。
