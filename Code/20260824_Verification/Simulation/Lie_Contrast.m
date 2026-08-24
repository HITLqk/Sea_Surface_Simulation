% ========================================================
% 修正Lie变换及坐标压缩卷浪仿真 (抗混叠优化版)
% ========================================================
clear; clc;

%% 1. 场景与参数设置
L = 2000;            % 海面物理尺寸 (m)
N = 256;            % 采样点数 (建议保持256，太高容易引发数值不稳定)
U10 = 12;           % 10m高度处风速 (m/s) - 建议10~12，20m/s会导致二阶近似发散
g = 9.81;

% 空间与波数网格
x = linspace(-L/2, L/2, N);
y = linspace(-L/2, L/2, N);
[X, Y] = meshgrid(x, y);

dk = 2 * pi / L;
kx = [0:N/2-1, -N/2:-1] * dk;
ky = [0:N/2-1, -N/2:-1] * dk;
[Kx, Ky] = meshgrid(kx, ky);
K = sqrt(Kx.^2 + Ky.^2);
K(1,1) = 1e-6;

%% 2. 构建基础 Elfouhaily 海谱与线性频域海面
S_2D = get_Elfouhaily2D(Kx, Ky, K, U10);

% 随机高斯白噪声激励
rng(42); % 固定随机种子以便复现好看的浪型，实际使用可注释掉
Z = (randn(N, N) + 1i * randn(N, N)) / sqrt(2);
H_linear = Z .* sqrt(S_2D * dk^2 / 2);
H_linear(1,1) = 0; 

%% 3. 核心修正：引入高频截断滤波器 (Anti-aliasing)
% 消除导数平方项导致的高频能量爆炸
k_max = max(K(:));
% 巴特沃斯低通滤波器，衰减最高频的30%区域
filter_W = exp(-(K / (0.7 * k_max)).^4); 
H_filtered = H_linear .* filter_W;

%% 4. 修正 Lie 变换计算 (基于滤波后的平滑场)
H_tx = 1i * Kx .* H_filtered;
H_ty = 1i * Ky .* H_filtered;

h_tx = real(ifft2(H_tx * N^2));
h_ty = real(ifft2(H_ty * N^2));

% 导数平方的频域表示
F_tx2 = fft2(h_tx.^2) / N^2;
F_txty = fft2(h_tx .* h_ty) / N^2;
F_ty2 = fft2(h_ty.^2) / N^2;

% 计算修正Lie变换二阶项 L*
L_star = -(Kx.^2 ./ (2.*K)) .* (U10 .* Kx ./ K) .* F_tx2 ...
         -(Kx .* Ky ./ K) .* F_txty ...
         -(Ky.^2 ./ (2.*K)) .* (U10 .* Ky ./ K) .* F_ty2;
L_star(1,1) = 0;

% 叠加非线性项，并再次抑制极高频毛刺
H_nl = (H_linear + L_star) .* filter_W; 
h_nl = real(ifft2(H_nl * N^2));

%% 5. 坐标压缩计算 (Choppy Effect)
% 计算水平位移场，利用 filter_W 防止水平位移发生微观网格交叉
Dx_freq = -1i .* (Kx ./ K) .* H_nl .* filter_W;
Dy_freq = -1i .* (Ky ./ K) .* H_nl .* filter_W;

Dx_freq(1,1) = 0; Dy_freq(1,1) = 0;

dx = real(ifft2(Dx_freq * N^2));
dy = real(ifft2(Dy_freq * N^2));

% 卷曲强度系数 (适度调节，过大依然会产生局部自交叉锯齿)
lambda = 1.2; 
X_new = X + lambda .* dx;
Y_new = Y + lambda .* dy;

%% 6. 可视化渲染
figure;
surf(X_new, Y_new, h_nl, 'EdgeColor', 'none', 'FaceColor', 'interp');
% title(['平滑修正Lie变换卷浪 (风速: ' num2str(U10) ' m/s)']);
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');

% 渲染光影质感
colormap(parula);
% light('Position', [-1, -1, 1], 'Style', 'infinite');
% lighting gouraud;
% material shiny;
% camlight('headlight');
zlim([-8 8]);
xlim([-100 100]);
ylim([-100 100]);
view(-35, 45);

%% 局部函数：Elfouhaily 2D
function S_2D = get_Elfouhaily2D(Kx, Ky, K, U10)
    g = 9.81;
    Omega = 0.84; 
    kp = g * (Omega / U10)^2;
    
    L_PM = exp(-1.25 * (kp ./ K).^2);
    Gamma = exp(-(sqrt(K/kp)-1).^2 / (2 * 0.08^2));
    J_p = 1.7 .^ Gamma;
    
    Bl = 0.5 * 0.006 * sqrt(Omega) * L_PM .* J_p; 
    Bh = 0.5 * 0.01 .* L_PM; 
    S_K = (K.^(-3)) .* (Bl + Bh);
    
    phi = atan2(Ky, Kx);
    D_theta = (2/pi) * cos(phi/2).^2; 
    
    S_2D = S_K .* D_theta ./ K;
    S_2D(isnan(S_2D) | isinf(S_2D)) = 0;
end
