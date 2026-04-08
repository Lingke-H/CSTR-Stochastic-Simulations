# 放热连续搅拌釜式反应器（CSTR）安全关键过程的逆向最优控制

> 基于 MATLAB 的数值计算框架，利用势函数赋形（Potential Shaping）与极值理论（EVT）设计并仿真非线性控制策略，以防止连续搅拌釜式反应器（CSTR）发生随机热失控。

---

## 项目简介

本仓库包含安全关键过程控制短期科研项目的数值仿真源代码及理论文档。该研究针对放热 CSTR 对随机热失控的脆弱性展开，重点解决传统线性控制器因其无界的非高斯误差分布而在极端噪声下失效的风险。

**核心目标**：合成基于“势函数赋形”的“逆向最优控制”律。通过显式构造系统的平稳玻尔兹曼分布，控制器能够严格界定峰值温度偏差，并最小化 Gumbel 尺度参数，从而在极端扰动下保证统计意义上的绝对安全。

### 核心特性

* **随机微分方程 (SDE) 建模**：使用 Euler-Maruyama 方法模拟一维非等温 CSTR 动力学。
* **势函数赋形综合**：设计特定的目标势函数（二次、四次、混合项），以重塑温度偏差的概率密度分布。
* **极值理论 (EVT) 分析**：提取温度偏差的区块极大值并拟合 Gumbel 分布，以严格量化安全裕度。
* **双重增益的非线性弹簧机制**：在平衡态附近实现局部高精度，同时在面对大型随机扰动时激活高刚度的恢复力。

---

## 数学框架

### 1. 系统动力学

非等温 CSTR 被建模为一个包含无量纲温度偏差 $x$ 的随机微分方程：

$$
dx_t = \left[ -x + 0.2 \cdot \left(1 - \frac{x}{22}\right) \cdot \exp\left(\frac{x}{1 + x/20}\right) \right]dt + 1 \cdot u dt + \sigma dW_t
$$

其中漂移函数包含了散热项与 Arrhenius 产热项。

### 2. 逆向控制律

为达到目标势函数 $V(x)$，通过求解 Hamilton-Jacobi-Bellman (HJB) 方程合成最优反馈控制器：

$$
k(x) = -\frac{1}{2} R(x)^{-1} G(x) \nabla V(x)
$$

### 3. 控制架构对比

* **基线组（线性控制）**： $V(x) \propto x^2$ 。强制形成高斯型尾部，使系统在罕见但极端的温度尖峰下处于危险之中。
* **方案 I（四次项）**： $V(x) \propto x^4$ 。提供极陡峭的边界防护，但在设定点附近存在刚度消失（平底）的问题。
* **方案 II（混合项）**： $V(x) \propto x^2 + x^4$ 。最佳控制架构，结合了局部的线性精度与全局的非线性安全边界。

---

## 仿真计算流程

```text
Phase I：开环被控对象建立
      │
      ▼
┌──────────────────────────────────────┐
│  Step 1：漂移函数定义                │
│  建立 Arrhenius 反应动力学模型，     │
│  并识别不稳定的平衡点（分界线 x ≈ 3.6）│
└──────────────┬───────────────────────┘
               │
               ▼
Phase II：控制器综合
               │
               ▼
┌──────────────────────────────────────┐
│  Step 2：势函数赋形                  │
│  分别计算二次、四次及混合目标分布的  │
│  梯度向量 ∇V(x)                      │
└──────────────┬───────────────────────┘
               │
               ▼
Phase III：随机仿真
               │
               ▼
┌──────────────────────────────────────────────────┐
│  Step 3：Euler-Maruyama 积分算法                 │
│  在布朗运动（噪声强度 σ=0.05 或 1.5）驱动下，    │
│  平行仿真多组系统轨迹                            │
└──────────────┬───────────────────────────────────┘
               │
               ▼
Phase IV：统计分析
               │
               ▼
┌──────────────────────────────────────┐
│  Step 4：极值理论与时域渲染          │
│  提取区块极大值，绘制 Gumbel 分布    │
│  以及概率密度直方图                  │
└──────────────────────────────────────┘
```

---

## 项目目录结构

```text
Inverse_Optimal_Control_CSTR/
├── src/                                  
│   ├── setup_small_sigma1.m              # 核心 SDE 仿真脚本（标准噪声 σ=0.05）
│   ├── setup_large_sigma.m               # 鲁棒性测试仿真脚本（极端噪声 σ=1.5）
│   ├── thermal_runaway2.m                # 可视化热失控物理过程（随机爆炸现象）
│   ├── controller_snythesis3.m           # 标准绘图脚本：极值分布与时域性能对比
│   └── controller_synthesis3_smooth.m    # 高级绘图脚本：包含 PCHIP 插值与强平滑算法
├── output/                               # 渲染生成的 MATLAB 图像存储目录
├── .gitignore
└── README.md
```

---

## 本地环境配置

若要在本地执行数值仿真并生成论文级别的图表，请确保配置了以下 MATLAB 运行环境。

### 前置要求
* **MATLAB R2021a 或更高版本**：用于兼容高级图形对象句柄及 `histcounts` 函数。
* **Statistics and Machine Learning Toolbox**：进行高级概率分布拟合必备。

### 运行说明

**1. 克隆仓库**
```bash
git clone [https://github.com/](https://github.com/)<your-username>/Inverse_Optimal_Control_CSTR.git
cd Inverse_Optimal_Control_CSTR/src
```

**2. 运行核心仿真**
打开 MATLAB，执行主设置脚本以生成轨迹数据及基线概率密度直方图（对应海报 Figure 4）：
```matlab
run('setup_small_sigma1.m')
```
*（此操作将自动输出漂移函数的结构分析图，并将计算环境保存至 `simulation_data.mat` 文件中。）*

**3. 生成高级统计可视化图表**
若需渲染极值分布图（Figure 5）及系统时域对比图（Figure 6），请在主仿真完成后执行平滑绘图脚本：
```matlab
run('controller_synthesis3_smooth.m')
```


# Inverse Optimal Control for Safety-Critical Processes in Exothermic CSTRs

> A MATLAB-based computational framework for designing and simulating nonlinear control strategies to prevent stochastic thermal runaway in Continuous-Stirred Tank Reactors (CSTRs) using Potential Shaping and Extreme Value Theory (EVT).

---

## Project Overview

This repository contains the numerical simulation source code and theoretical documentation for a short-term research project on safety-critical process control. The study addresses the vulnerability of exothermic CSTRs to stochastic thermal runaway—a critical risk where traditional linear controllers fail due to their unbounded Gaussian error distributions.

**Core Objective**: To synthesize an "Inverse Optimal Control" law based on "Potential Shaping." By explicitly constructing the system's stationary Boltzmann distribution, the controller strictly bounds peak temperature excursions and minimizes the Gumbel scale parameter, thereby guaranteeing statistical safety under extreme noise disturbances.

### Core Features

* **Stochastic Differential Equation (SDE) Modeling**: Simulating 1D non-isothermal CSTR dynamics using the Euler-Maruyama method.
* **Potential Shaping Synthesis**: Designing specific potential functions (Quadratic, Quartic, Mixed) to reshape the probability density of temperature deviations.
* **Extreme Value Theory (EVT) Analysis**: Quantifying safety margins by fitting block maxima of temperature excursions to Gumbel distributions.
* **Dual-Benefit Nonlinear Spring Mechanism**: Achieving local precision near the equilibrium state while activating a stiff restoring force against large random disturbances.

---

## Mathematical Framework

### 1. System Dynamics

The non-isothermal CSTR is modeled as an SDE with dimensionless temperature deviation $x$:

$$
dx_t = \left[ -x + 0.2 \cdot \left(1 - \frac{x}{22}\right) \cdot \exp\left(\frac{x}{1 + x/20}\right) \right]dt + 1 \cdot u dt + \sigma dW_t
$$

Where the drift function encompasses heat dissipation and Arrhenius heat generation.

### 2. Inverse Control Law

To achieve a target potential $V(x)$, the optimal feedback controller is synthesized via the solution of the Hamilton-Jacobi-Bellman (HJB) equation:

$$
k(x) = -\frac{1}{2} R(x)^{-1} G(x) \nabla V(x)
$$

### 3. Control Architectures Compared

* **Baseline (Linear)**: $V(x) \propto x^2$. Enforces Gaussian-like tail behavior, leaving the system vulnerable to rare but extreme spikes.
* **Proposed I (Quartic)**: $V(x) \propto x^4$. Provides steep bounds but suffers from vanishing stiffness near the setpoint (flat bottom).
* **Proposed II (Mixed)**: $V(x) \propto x^2 + x^4$. The optimal architecture combining local linear precision with global nonlinear safety bounds.

---

## Simulation Workflow

```text
Phase I: Open-Loop Plant Setup
      │
      ▼
┌──────────────────────────────────────┐
│  Step 1: Drift Function Definition   │
│  Establishing the Arrhenius reaction │
│  kinetics and identifying unstable   │
│  equilibria (separatrix at x ≈ 3.6)  │
└──────────────┬───────────────────────┘
               │
               ▼
Phase II: Controller Synthesis
               │
               ▼
┌──────────────────────────────────────┐
│  Step 2: Potential Shaping           │
│  Computing the gradient ∇V(x) for    │
│  Quadratic, Quartic, and Mixed       │
│  target distributions                │
└──────────────┬───────────────────────┘
               │
               ▼
Phase III: Stochastic Simulation
               │
               ▼
┌──────────────────────────────────────────────────┐
│  Step 3: Euler-Maruyama Integration              │
│  Simulating parallel system trajectories under   │
│  Brownian motion (noise intensity σ=0.05 or 1.5) │
└──────────────┬───────────────────────────────────┘
               │
               ▼
Phase IV: Statistical Analysis
               │
               ▼
┌──────────────────────────────────────┐
│  Step 4: EVT & Time-Domain Rendering │
│  Extracting block maxima and         │
│  plotting Gumbel distributions       │
│  alongside probability density       │
└──────────────────────────────────────┘
```

---

## Repository Structure

```text
Inverse_Optimal_Control_CSTR/
├── src/                                  
│   ├── setup_small_sigma1.m              # Primary SDE simulation with standard noise (σ=0.05)
│   ├── setup_large_sigma.m               # Robustness testing simulation with extreme noise (σ=1.5)
│   ├── thermal_runaway2.m                # Visualizes the physics of failure (stochastic explosion)
│   ├── controller_snythesis3.m           # Standard plotting script for EVT and time-domain performance
│   └── controller_synthesis3_smooth.m    # Advanced plotting script with PCHIP interpolation
├── output/                               # Directory for generated MATLAB figures
├── .gitignore
└── README.md
```

---

## Local Environment Setup

To execute the numerical simulations and generate the paper-ready figures, ensure the following MATLAB environment is configured.

### Prerequisites
* **MATLAB R2021a or higher**: Required for advanced graphic objects handling and `histcounts`.
* **Statistics and Machine Learning Toolbox**: Required for advanced distribution fitting.

### Execution Instructions

**1. Clone the repository**
```bash
git clone [https://github.com/](https://github.com/)<your-username>/Inverse_Optimal_Control_CSTR.git
cd Inverse_Optimal_Control_CSTR/src
```

**2. Run the Core Simulation**
Open MATLAB and execute the main setup script to generate trajectory data and baseline probability density histograms (Figure 4):
```matlab
run('setup_small_sigma1.m')
```
*(This will automatically output the structural analysis of the drift function and save the computational environment to `simulation_data.mat`.)*

**3. Generate Advanced Statistical Visualizations**
To render the Extreme Value Distributions (Figure 5) and Time Domain Comparisons (Figure 6), execute the smoothing script post-simulation:
```matlab
run('controller_synthesis3_smooth.m')
```
