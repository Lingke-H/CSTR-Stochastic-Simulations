%% CSTR Simulation Step 1: The Plant Setup & Verification
% 目标：建立一维无量纲 CSTR 模型，并验证其开环动力学 f(x) 的不稳定性
clear; clc; close all;

%% 1. 定义系统参数 (System Parameters)
% 这些参数完全对应你截图中的 SDE 方程
Da = 0.2;     % Damkohler number (反应放热潜能)
gamma = 20.0; % Activation energy (活化能参数)
beta = 22.0 % Heat of Reaction (新增：放热参数，允许高温存在)
sigma = 0.05;   % Noise intensity (噪声强度)
dt = 0.01;      % Time step (时间步长)

% 定义仿真时间
T_end = 500;            % 总时长
N = floor(T_end / dt);  % 总步数
t = (0:N-1) * dt;       % 时间轴

% 定义颜色
color_blue = [0, 0.4470, 0.7410];   % MATLAB Standard Blue
color_orange = [0.8500, 0.3250, 0.0980]; % MATLAB Standard Orange

%% 2. 定义系统漂移函数 f(x) (Define Drift Function)
% f(x) = 散热项(-x) + 产热项(Arrhenius)
% 对应公式: dx = [-x + Da*(1-x)*exp(x/(1+x/gamma))]dt ...

% 更新漂移函数 f(x) (引入 beta)
% 注意：这里把 (1-x) 改成了 (1 - x/beta)
% 物理意义：燃料不会在 x=1 时就烧光，而是能支撑温度升到 x=22
f_drift = @(x) -x + Da .* (1 - x ./ beta) .* exp(x ./ (1 + x ./ gamma));

%% 3. 核心验证：画出 f(x) 曲线 (Visualize Open-Loop Dynamics)
% 这一步是为了确认系统是否存在“多重平衡点” (Multiple Equilibria)
% 我们在 x = -1.0 到 8.0 的范围内观察 f(x)
x_test = linspace(-1, 8, 10000); 
f_vals = f_drift(x_test);

figure(1);
plot(x_test, f_vals, 'LineWidth', 2, 'Color', color_blue); hold on;
yline(0, '--', 'LineWidth', 2, 'Color', color_orange); % 画出 y=0 的基准线

% 标注图表
title('Step 1 Verification: Open-loop Dynamics f(x)', 'FontSize', 12);
xlabel('Dimensionless Temperature Deviation (x)', 'FontSize', 12);
ylabel('Rate of Change dx/dt = f(x)', 'FontSize', 12);
legend('System Drift f(x)', 'Equilibrium Line (dx/dt=0)', 'Location', 'Best');
grid on;

% 分析：f(x) 与 y=0 的交点就是系统的平衡点
% 如果曲线穿过红线 3 次，说明系统是不稳定的。

%% Figure 2: Zoomed-In Inspection (核心微观分析)
% 目标：放大观察 x 在 [-1, 5.0] 之间的细节，寻找“临界点”

% 1. 重新定义更精细的观测范围 (Focus on the critical region)
x_zoom = linspace(-1, 5, 1000); 

% 2. 计算该范围内的漂移值
f_zoom = f_drift(x_zoom);

% 3. 绘图
figure(2);
plot(x_zoom, f_zoom, 'LineWidth', 2, 'Color', color_blue); hold on;
yline(0, 'r--', 'LineWidth', 2, 'Color', color_orange); % 零刻度线

% 4. 添加辅助标注，帮助你理解物理意义
% 标记出 f(x) > 0 的危险区域（如果有的话）
% 在这个区域，温度会自动升高 (自加速)
title('Figure 3: Zoomed-in Dynamics near Steady State', 'FontSize', 12);
xlabel('Dimensionless Temperature (x)', 'FontSize', 12);
ylabel('Drift f(x)', 'FontSize', 12);
legend('System Drift f(x)', 'Equilibrium (dx/dt=0)', 'Location', 'Best');
grid on;

% 5. 自动检测并打印交点 (Equilibrium Points)
% 这是一个简单的数值检测，看看曲线穿过了几次 0
crossings = [];
for i = 1:length(f_zoom)-1
    if sign(f_zoom(i)) ~= sign(f_zoom(i+1))
        crossings = [crossings, x_zoom(i)];
    end
end

fprintf('在观察范围内检测到的平衡点 (f(x)=0) 约在 x = \n');
disp(crossings);

%% --- 修正后的热失控可视化 (Runaway Visualization) ---

T_short = 200;            
N_short = floor(T_short / dt);
t_short = (0:N_short-1) * dt;
x_runaway = zeros(1, N_short);

% 1. 增加初始值，确保冲过临界区
x_runaway(1) = 3.8;      

rng(42); 
for k = 1:N_short-1
    x_now = x_runaway(k);
    drift = f_drift(x_now); 
    dW = sqrt(dt) * randn(); 
    x_runaway(k+1) = x_now + drift * dt + sigma * dW;
    
    % 2. 防止数值溢出，但在到达 beta 附近时停止
    if x_runaway(k+1) > 25, x_runaway(k+1) = 25; end
end

figure(3);
% 绘制主轨迹
close all
plot(t_short, x_runaway, 'k', 'LineWidth', 1.0); hold on;

% 1. 标注“生死线” (Unstable Threshold / Separatrix)
% 3.6 是我们在 Step 1 中通过 f(x)=0 找出的不稳定平衡点
yline(3.6, '--', 'Unstable Threshold', 'Color', color_orange, 'LineWidth', 2.0, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 10);

% 2. 标注“高产热稳态” (High-Temp Steady State)
% 对应 beta = 22 的物理极限
yline(21.4, '--', 'Stable High-Temp State','Color', color_blue, 'LineWidth', 2.0, ...
    'LabelHorizontalAlignment', 'left', 'FontSize', 10);

% 3. 装饰与标注
title('FIgure 3: The Physics of Failure: Open-Loop Thermal Runaway', 'FontSize', 13);
xlabel('Time (t)', 'FontSize', 11);
ylabel('Dimensionless Temperature Deviation (x)', 'FontSize', 11);

% 调整显示范围，给标注留一点空间
xlim([0, 5]); 
ylim([0, 26]); 
grid on;

% 添加注释说明爆炸点
text(1.7, 10, '\leftarrow Rapid Ignition Phase', 'FontSize', 10, 'FontWeight', 'bold');

fprintf('演示图像已优化：红虚线代表不稳定的势垒，蓝虚线代表失控后的新平衡。\n');