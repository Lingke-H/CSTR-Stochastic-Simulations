%% CSTR Simulation Step 1: The Plant Setup & Verification
% 目标：建立一维无量纲 CSTR 模型，并验证其开环动力学 f(x) 的不稳定性
clear; clc; close all;

%% 1. 定义系统参数 (System Parameters)
% 这些参数完全对应你截图中的 SDE 方程
Da = 0.2;     % Damkohler number (反应放热潜能)
gamma = 20.0; % Activation energy (活化能参数)
beta = 22.0 % Heat of Reaction (新增：放热参数，允许高温存在)
sigma = 1.5;   % Noise intensity (噪声强度)
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
title('Figure 1: Step 1 Verification: Open-loop Dynamics f(x)', 'FontSize', 12);
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
title('Figure 2: Zoomed-in Dynamics near Steady State', 'FontSize', 12);
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

%% 4. 预演：SDE 仿真框架 (SDE Simulation Skeleton)
% 这里搭建 Euler-Maruyama 方法的骨架，为下一步加入控制器做准备
% 目前 u = 0 (开环测试)

x_traj = zeros(1, N); % 初始化状态轨迹数组
x_traj(1) = 0.1;      % 初始状态 (给一点点微小的扰动，看它会不会跑飞)

rng(42); % 固定随机种子，保证每次结果可复现

for k = 1:N-1
    x_now = x_traj(k);
    
    % --- 控制器接口 (目前是开环，u=0) ---
    % 下一步 Method I 时，我们将在这里填入: u = -f_drift(x_now) - grad_V(x_now)
    u = 0; 
    
    % --- 计算漂移 (Drift) ---
    drift = f_drift(x_now) + u;
    
    % --- 计算扩散 (Diffusion / Noise) ---
    % dW 是布朗运动增量，服从 N(0, dt)
    dW = sqrt(dt) * randn(); 
    
    % --- 更新状态 (Euler-Maruyama Step) ---
    x_next = x_now + drift * dt + sigma * dW;
    
    % 存储
    if x_next > 30, x_next = 30; end
    x_traj(k+1) = x_next;
end

% 画出随时间变化的轨迹
figure(3);
plot(t, x_traj, 'k');
title('Figure 3: Time Evolution of x (Open Loop with Noise)', 'FontSize', 12);
xlabel('Time (t)');
ylabel('Temperature Deviation (x)');
xlim([0 250])
grid on;

fprintf('代码运行完成。请观察 Figure 1 确认交点情况。\n');

%% Step 2: Controller Synthesis & Comparison (3 Scenarios)
% clear; clc; close all;

% 1. 参数设置
Da = 0.2;     
gamma = 20.0; 
beta = 22.0; 
sigma = 1.5;   
dt = 0.01; 
T_sim = 2000;          
N = floor(T_sim / dt);

% 2. 初始化三个平行宇宙 (Parallel Universes)
x_open = zeros(1, N);
x_quad = zeros(1, N);  % Scenario 1: Baseline (x^2)
x_quart = zeros(1, N); % Scenario 2: Proposed I (x^4)
x_mixed = zeros(1, N); % Scenario 3: Proposed II (Mixed: x^2 + x^4)

% 初始状态
x_open(1) = 0;
x_quad(1) = 0; 
x_quart(1) = 0;
x_mixed(1) = 0; 

% 3. 定义势能参数
k_quad = 0.5;  % 线性刚度 (负责 0 附近的精度)
k_quart = 80; % 非线性刚度 (负责大偏差时的“墙”)

rng(100); % 固定种子
fprintf('开始进行三路对比仿真 (T=%d)... \n', T_sim);

for k = 1:N-1
    % --- 提取各自宇宙的当前状态 ---
    x0 = x_open(k);
    x1 = x_quad(k);
    x2 = x_quart(k);
    x3 = x_mixed(k); % 这是一个独立的系统！
    
    % --- 1. 计算各自的自然漂移 f(x) ---
    f0 = -x0 + Da * (1 - x0) * exp(x0 / (1 + x0 / gamma));
    f1 = -x1 + Da * (1 - x1) * exp(x1 / (1 + x1 / gamma));
    f2 = -x2 + Da * (1 - x2) * exp(x2 / (1 + x2 / gamma));
    f3 = -x3 + Da * (1 - x3) * exp(x3 / (1 + x3 / gamma));
    
    % --- 2. 计算各自的目标势能梯度 (关键差异点) ---
    % Scenario 1: 只有线性项
    grad_V1 = k_quad * x1;      
    
    % Scenario 2: 只有四次项 (平底锅问题)
    grad_V2 = k_quart * x2^3;   
    
    % Scenario 3: 混合项 (最佳组合)
    % 注意：必须用 x3 来计算！不能混合 x1 或 x2
    grad_V3 = k_quad * x3 + k_quart * x3^3; 
    
    % --- 3. 合成控制器 u = -f - grad_V ---
    u0 = 0;
    u1 = -f1 - grad_V1; 
    u2 = -f2 - grad_V2;
    u3 = -f3 - grad_V3;
    
    % --- 4. 欧拉-马鲁山迭代 ---
    dW = sqrt(dt) * randn(); % 相同的噪声袭击所有系统
    
    x_open(k+1)  = x0 + (f0 + u0) * dt + sigma * dW;

    % Update Scenario 1
    x_quad(k+1) = x1 + (f1 + u1) * dt + sigma * dW;
    
    % Update Scenario 2
    x_quart(k+1) = x2 + (f2 + u2) * dt + sigma * dW;
    
    % Update Scenario 3
    x_mixed(k+1) = x3 + (f3 + u3) * dt + sigma * dW;
end

%% 4. 结果可视化：三个控制器的对比
figure(4); 
% clf; 清空旧图

% Plot 0: Open-Loop (Black Dashed) - The "Danger Zone"
h0 = histogram(x_open, 100, 'Normalization', 'pdf', 'DisplayStyle', 'stairs', ...
    'LineWidth', 1.5, 'EdgeColor', 'k', 'LineStyle', '--'); 
hold on;

% Plot 1: Baseline (Blue)
h1 = histogram(x_quad, 100, 'Normalization', 'pdf', 'DisplayStyle', 'stairs', ...
    'LineWidth', 1.5, 'EdgeColor', '#0072BD'); % MATLAB Blue
hold on;

% Plot 2: Proposed I (Orange) - The "Flat Bottom"
h2 = histogram(x_quart, 100, 'Normalization', 'pdf', 'DisplayStyle', 'stairs', ...
    'LineWidth', 1.5, 'EdgeColor', '#D95319'); % MATLAB Orange
hold on;

% Plot 3: Proposed II (Purple) - The "Perfect Shape"
h3 = histogram(x_mixed, 100, 'Normalization', 'pdf', 'DisplayStyle', 'stairs', ...
    'LineWidth', 1.5, 'EdgeColor', '#7E2F8E'); % MATLAB Purple (显眼颜色)

% 设置坐标轴
set(gca, 'YScale', 'log'); 
grid on;

% 这里的 Legend 顺序必须和画图顺序一致
legend([h0, h1, h2, h3], ...
    'Open-Loop: No Control (Large Steady-State Error)', ...
    'Baseline: Quadratic V(x)=x^2', ...
    'Proposed I: Quartic V(x)=x^4 (Flat Top)', ...
    'Proposed II: Mixed V(x)=x^2+x^4 (Best)', ...
    'Location', 'SouthOutside'); % 把图例放下面，防止遮挡

title('Figure 5: Impact of Different Control Strategies on Probability Density', 'FontSize', 12);
xlabel('Temperature Deviation (x)');
ylabel('Probability Density (Log Scale)');

% xlim([-0.30 0.4]); % 聚焦中心区域看差异
xlim([-10 10])
ylim([1e-5, 5])
fprintf('仿真完成！注意观察 Purple 线是否兼具 Blue 的尖峰和 Orange 的窄尾; 虚线代表没有控制的自然状态。\n');