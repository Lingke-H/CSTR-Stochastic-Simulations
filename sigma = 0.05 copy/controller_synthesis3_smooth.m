%% === 独立绘图脚本: plot_results.m (Smoothed Manual Version) ===
clear; clc; close all;

% 1. 加载仿真数据
if isfile('simulation_data.mat')
    load('simulation_data.mat');
else
    error('未找到数据文件 simulation_data.mat！请先运行主仿真程序。');
end

%% === Figure 6: 极值分布 ===
fprintf('正在生成 Figure 6 ...\n');

% 重新计算 Block Maxima
T_block = 20; 
points_per_block = round(T_block / dt);
% Use actual data length to avoid errors
N_actual = length(x_open);
num_blocks = floor(N_actual / points_per_block);

max_open  = zeros(1, num_blocks);
max_quad  = zeros(1, num_blocks);
max_quart = zeros(1, num_blocks);
max_mixed = zeros(1, num_blocks);

for i = 1:num_blocks
    idx = (i-1)*points_per_block + 1 : i*points_per_block;
    max_open(i)  = max(x_open(idx));
    max_quad(i)  = max(x_quad(idx));
    max_quart(i) = max(x_quart(idx));
    max_mixed(i) = max(x_mixed(idx));
end

figure(6); clf;
hold on; 

% --- 核心：定义平滑绘图函数 (在脚本末尾定义) ---
plot_smooth = @(data, color, style, width, name) ...
    plot_distribution_manual_v2(data, color, style, width, name);

% 1. Open-Loop (黑色虚线)
plot_smooth(max_open, 'k', '--', 1.2, 'Open-Loop (Risky)');

% 2. Baseline (蓝色实线)
plot_smooth(max_quad, '#0072BD', '-', 1.2, 'Baseline');

% 3. Proposed I (橙色实线)
plot_smooth(max_quart, '#D95319', '-', 1.2, 'Proposed I');

% 4. Proposed II (紫色实线)
[xx_mixed, yy_mixed] = plot_smooth(max_mixed, '#7E2F8E', '-', 1.2, 'Proposed II (Safest)');

% === 填充紫色区域 (Fix for fill error) ===
% Convert hex color to RGB for fill function compatibility in older MATLAB versions
purple_rgb = [0.4940 0.1840 0.5560]; % RGB for #7E2F8E
fill([xx_mixed, fliplr(xx_mixed)], [yy_mixed, zeros(size(yy_mixed))], ...
     purple_rgb, 'FaceAlpha', 0.1, 'EdgeColor', 'none', 'HandleVisibility', 'off');

grid on;
title('Figure 5: Extreme Value Distribution (Smoothed)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Max Temperature Deviation per 20s Block (x_{max})');
ylabel('Probability Density');
xlim([0 0.35])
legend('Location', 'Best'); 

fprintf('Figure 6 生成完毕。\n');


%% === Figure 7: 时间演化 (Subplot) ===
fprintf('正在生成 Figure 7 (时间演化)...\n');
figure(7); clf;

T_view = 50; 
N_view = min(round(T_view / dt), length(x_open)); 
t_vec = (0:N_view-1) * dt;

% Subplot 1
subplot(2,1,1);
plot(t_vec, x_open(1:N_view), 'k--', 'LineWidth', 1.0); hold on;
plot(t_vec, x_quad(1:N_view), '-', 'LineWidth', 1.0, 'Color', '#0072BD');
yline(0, 'k-', 'Alpha', 0.3);
title('(a) Baseline Control vs. Open-Loop Drift', 'FontSize', 11);
ylabel('Temp Deviation (x)');
legend('Open-Loop', 'Baseline (Linear)', 'Location', 'Best');
grid on; xlim([0, t_vec(end)]); 
ylim([min(x_open(1:N_view))-0.12, max(x_open(1:N_view))+0.1]);

% Subplot 2
subplot(2,1,2);
plot(t_vec, x_quad(1:N_view), '-', 'LineWidth', 0.5, 'Color', [0.7 0.8 1]); hold on; 
plot(t_vec, x_quart(1:N_view), '-', 'LineWidth', 0.8, 'Color', '#D95319');
plot(t_vec, x_mixed(1:N_view), '-', 'LineWidth', 0.8, 'Color', '#7E2F8E'); 
yline(0, 'k-', 'Alpha', 0.3);
title('(b) Proposed Nonlinear Controllers (Best Performance)', 'FontSize', 11);
xlabel('Time (t)');
ylabel('Temp Deviation (x)');
legend('Baseline (Ref)', 'Proposed I (Quartic)', 'Proposed II (Mixed)', 'Location', 'Best');
grid on; xlim([0, t_vec(end)]); ylim([-0.15, 0.15]);

sgtitle('Figure 6: Time Domain Performance Comparison', 'FontWeight', 'bold'); 
fprintf('所有绘图完成。\n');


%% === 辅助函数 (针对稀疏数据优化) ===
function [xx, yy] = plot_distribution_manual_v2(data, color, style, width, name)
    % 1. 智能决定 Bin 的数量
    % 如果数据点很少(比如只有100个)，就只用15个柱子，否则用30个
    % 这样可以避免"过度拟合"噪声
    if length(data) < 200
        num_bins = 15;  % 数据少，桶就少，反而更准
    else
        num_bins = 40;  % 数据多，细节就多
    end

    [counts, edges] = histcounts(data, num_bins, 'Normalization', 'pdf'); 
    centers = (edges(1:end-1) + edges(2:end)) / 2;
    
    % 2. 在两端补 0
    centers = [edges(1)-diff(edges(1:2)), centers, edges(end)+diff(edges(end-1:end))];
    counts  = [0, counts, 0];
    
    % 3. *** 增强型平滑 (Aggressive Smoothing) ***
    % 使用 5 点移动平均，而不是原来的 3 点
    window_size = 5; 
    kernel = ones(1, window_size) / window_size;
    
    % 第一轮平滑
    counts_smooth = conv(counts, kernel, 'same');
    
    % 第二轮平滑 (Double Pass): 再次平滑可以让曲线像奶油一样顺滑
    % 仅当数据非常稀疏时才建议这么做
    if length(data) < 500
        counts_smooth = conv(counts_smooth, [0.25 0.5 0.25], 'same');
    end
    
    % 4. 插值
    xx = linspace(min(edges), max(edges), 200); 
    yy = interp1(centers, counts_smooth, xx, 'pchip'); 
    
    % 5. 修正负值
    yy(yy < 0) = 0;
    
    % 6. 画图
    plot(xx, yy, 'Color', color, 'LineStyle', style, 'LineWidth', width, 'DisplayName', name);
end