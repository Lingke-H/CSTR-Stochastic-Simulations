%% === 独立绘图脚本: plot_results.m ===
clear; clc; close all;

% 1. 加载仿真数据 (前提：你已经在主程序里运行了 save('simulation_data.mat'))
if isfile('simulation_data.mat')
    load('simulation_data.mat');
else
    warning('未找到数据文件，请先运行仿真主程序！');
    return;
end

%% === Figure 6: 极值分布 EVT ===
% 重新计算 Block Maxima
T_block = 20; 
points_per_block = round(T_block / dt);
num_blocks = floor(N / points_per_block);

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

h_ev0 = histogram(max_open, 20, 'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', 'LineWidth',1.0, 'EdgeColor', 'k', 'LineStyle', '--'); hold on;

h_ev1 = histogram(max_quad, 20, 'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', 'LineWidth', 1.0, 'EdgeColor', '#0072BD'); hold on;

h_ev2 = histogram(max_quart, 20, 'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', 'LineWidth', 1.0, 'EdgeColor', '#D95319'); hold on;

h_ev3 = histogram(max_mixed, 20, 'Normalization', 'pdf', ...
    'DisplayStyle', 'stairs', 'LineWidth', 1.0, 'EdgeColor', '#7E2F8E'); 

grid on;
title('Figure 6: Extreme Value Distribution (Safety Risk Assessment)', 'FontSize', 12, 'FontWeight', 'bold');
xlabel('Maximum Temperature Deviation per 20s Block (x_{max})');
ylabel('Probability Density');
legend([h_ev0, h_ev1, h_ev2, h_ev3], ...
    'Open-Loop (High Risk)', 'Baseline (Medium Risk)', 'Proposed I (Bounded)', 'Proposed II (Safest)', ...
    'Location', 'NorthEast');
xlim([0 0.4]);

%% === Figure 7: 时间演化 ===
% 将图拆分为上下两部分，避免线条打架
figure(7); clf;
T_view = 50; 
N_view = round(T_view / dt);
t_vec = (0:N_view-1) * dt;

% --- 子图 1: Open-Loop vs Baseline (展示问题的严重性) ---
subplot(2,1,1);
plot(t_vec, x_open(1:N_view), 'k--', 'LineWidth', 1.0); hold on;
plot(t_vec, x_quad(1:N_view), '-', 'LineWidth', 1.2, 'Color', '#0072BD');
yline(0, 'k-', 'Alpha', 0.3);
title('(a) Baseline Control vs. Open-Loop Drift', 'FontSize', 11);
ylabel('Temp Deviation (x)');
legend('Open-Loop', 'Baseline (Linear)', 'Location', 'Best');
grid on; xlim([0, T_view]); ylim([-0.15, 0.35]);

% --- 子图 2: Proposed I vs Proposed II (展示你的改进) ---
subplot(2,1,2);
% 为了对比，把 Baseline 淡淡地画在背景里作为参考
plot(t_vec, x_quad(1:N_view), '-', 'LineWidth', 0.5, 'Color', [0.7 0.8 1]); hold on; 
plot(t_vec, x_quart(1:N_view), '-', 'LineWidth', 1.2, 'Color', '#D95319');
plot(t_vec, x_mixed(1:N_view), '-', 'LineWidth', 1.5, 'Color', '#7E2F8E'); % 紫色最粗
yline(0, 'k-', 'Alpha', 0.3);
title('(b) Proposed Nonlinear Controllers (Best Performance)', 'FontSize', 11);
xlabel('Time (t)');
ylabel('Temp Deviation (x)');
legend('Baseline (Ref)', 'Proposed I (Quartic)', 'Proposed II (Mixed)', 'Location', 'Best');
grid on; xlim([0, T_view]); ylim([-0.15, 0.35]);

sgtitle('Figure 7: Time Domain Performance Comparison'); % 整个图的总标题