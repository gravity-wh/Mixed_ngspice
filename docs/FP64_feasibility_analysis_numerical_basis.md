# FP64 孤岛可行性分析 — 数值计算理论基础

## 核心问题

> 为什么可以通过**静态数值分析**（不运行仿真）判断一个 FP64 孤岛是否能用纯 FP32 数值方法替代？

答案在于 IEEE 754 浮点运算的**误差模型**和 **Wilkinson 向后误差分析**框架——每个浮点运算的误差行为是**数学上可预测的**，不需要实测。

---

## 1. 浮点误差的数学模型

IEEE 754 基本模型（对 +, −, ×, ÷, √）：

$$fl(a \circ b) = (a \circ b)(1 + \delta), \quad |\delta| \leq \epsilon_{machine}$$

其中 $\epsilon_{machine}$ = $2^{-23} \approx 1.19 \times 10^{-7}$ (FP32) 或 $2^{-52} \approx 2.22 \times 10^{-16}$ (FP64)。

这意味着：**每个运算的误差是确定的、有界的、不依赖于具体数值**。这就为静态分析提供了数学基础。

---

## 2. 两类失效模式的数学本质

HTML 文档将 6 个孤岛分为两类根因。从数值分析角度看：

### 类型 A：溢出（Overflow）—— 范围问题

**判断标准**（二值条件，无需仿真）：

$$|z_{intermediate}| \gtrsim FLT\_MAX = 3.4028235 \times 10^{38}$$

**为什么是可静态分析的**：这是一个**存在性**命题。只要计算图的任何一个中间节点值超过 FLT_MAX，该路径就是不可行的。你可以用**区间算术**（interval arithmetic）为每个中间变量计算上界：

```
nsd ∈ [1e18, 1e21]    (掺杂浓度范围)
ndep ∈ [1e16, 1e19]
→ nsd × ndep ∈ [1e34, 1e40]  ← 上界超过 FLT_MAX
→ 路径不可行 ❌
```

对于 Vbi 和 NOIA，乘积/默认值分别达到 6.48×10³⁸ 和 6.25×10⁴¹——明显超出，判断是确定的。

### 类型 B：消去误差（Cancellation）—— 精度问题

**判断标准**（条件数）：

对于减法 $c = a - b$，相对误差放大因子为：

$$\kappa_{sub} = \frac{|a| + |b|}{|a - b|}$$

当 $\kappa_{sub} \gg 1$ 时，结果的有效位数丢失 $\approx \log_{10}(\kappa_{sub})$ 个十进制位。

**为什么是可静态分析的**：条件数 $\kappa$ 只依赖于**操作数的近似值**，不需要精确仿真结果。对于 BSIM4 模型参数，典型值是已知的：

| 孤岛 | 运算 | a 典型值 | b 典型值 | $\|a-b\|$ | $\kappa_{sub}$ | 有效位丢失 |
|------|------|----------|----------|-----------|----------------|-----------|
| Leff | 45nm − 1.2nm | 4.5×10⁻⁸ | 1.2×10⁻⁹ | 4.38×10⁻⁸ | 1.03 | **0** (但 dl 计算链 ~10⁴) |
| Abulk | Leff/(Leff + 2d) | ≈1 | ≈1 | O(1) | 嵌套 | 链式累积 |
| Vbseff | T₀² − 0.004·vbsc | 10⁻⁶ | ~0.004 | 可很小 | 可达 10³ | 3–4 位 |
| Vth k1ox | 16.5 − 0.2 | 16.5 | 0.2 | 16.3 | 1.02 | **<1 位** ⚠️ |

> ⚠️ **注意**：Vth k1ox 的条件数只有 ~1.02——两项差 80 倍意味着这**实际上不是**一个经典的消去问题。该孤岛的精度需求可能来自下游敏感度（Vth → gm → Ids 的放大链），而非减法本身的条件数。这是文档中一个值得再审查的边界案例。

---

## 3. 误差传播的链式分析

单次运算的条件数只说明**局部**精度。完整的可行性分析需要追踪**误差沿计算图的传播**。

### 一阶误差传播公式

对于函数 $y = f(x_1, x_2, ..., x_n)$，前向误差：

$$\Delta y \approx \sum_{i=1}^{n} \frac{\partial f}{\partial x_i} \Delta x_i$$

这就引出了**相对条件数**的乘法性质：

$$\kappa_{total} \approx \prod_{j=1}^{k} \kappa_j$$

在对数空间中：

$$\log_{10}(\kappa_{total}) \approx \sum_{j=1}^{k} \log_{10}(\kappa_j)$$

这就是为什么 **Abulk 和 Leff/Weff 被判定为"真正需要 FP64"**：

- **Abulk**：T₁ 有 ~3 次消去操作，T₂ 有 ~2 次消去操作，T₁·T₂ 再做一次消去。链路乘积极失 ≈ 10²–10⁴，等效丢失 2–4 个十进制位。FP32 的 7 位 → 仅剩 3–5 位 → 对 DC 收敛（需要 ~10⁻⁶ 精度）不够。

- **Leff/Weff**：`pow(Lnew, Lln)` 的条件数 ≈ |ln(Lnew)| ≈ |ln(4.5×10⁻⁸)| ≈ 16.9。随后的除法、相加、最终减法形成嵌套链。累积误差导致 Leff 相对误差 ~0.5%，通过 gm ∝ 1/Leff 传播到所有小信号量。

相比之下，**Vbi log 拆分**的条件数是 1（恒等式），**NOIA log 存储**的条件数也是 1（单调变换）。这些不需要链式分析就能判定为可行。

---

## 4. 纯 FP32 修复的数值方法理论基础

### 4.1 Log 域运算（Vbi）

**恒等式**：

$$\log\left(\frac{n_{sd} \cdot n_{dep}}{n_i^2}\right) = \log(n_{sd}) + \log(n_{dep}) - 2\log(n_i)$$

**为什么是精确的**：这是数学恒等式，不是近似。实数上的 log 是双射（在 ℝ⁺ 上），变换不改变函数值。唯一引入的额外误差来自 3 次 log 运算代替 1 次 log 运算——但每次 log 的相对误差是 ε_machine 级别的，总和远小于原始溢出的 ∞ 误差。

**数值验证**：
```
直接法: log(6.48e38) → FP32 overflow → +Inf → 失败
拆分法: log(2e20) + log(3.24e18) - 2×log(1.5e10)
       = 46.73 + 42.63 - 2×23.42
       = 46.73 + 42.63 - 46.84
       = 42.52
→ Vbi = 0.02585 × 42.52 ≈ 1.099V ✅
```

### 4.2 补偿减法 / Dekker 算法（Vth k1ox）

Dekker 精确减法使用 6 个 FP32 运算恢复 `a - b` 的丢失位：

```
// Dekker's exact subtraction
diff = a - b;            // 浮点近似
b_virtual = diff - a;    // 恢复丢失位
a_virtual = diff - b_virtual;
b_roundoff = b - b_virtual;
a_roundoff = a - a_virtual;
correction = a_roundoff - b_roundoff;  // 补偿项
exact_diff = diff + correction;         // 更高精度
```

**为什么有效**：Dekker 算法基于一个定理——当 |a| ≥ |b| 时，`a - (a - b)` 精确恢复 b 的有效位。6 次运算的开销远小于 FP64 硬件转换。

### 4.3 Log 存储（噪声 NOIA）

存储 $\log(NOIA)$ 而非 NOIA 本身：

$$NOIA = e^{\log(NOIA)}$$

**为什么有效**：log 将乘法变成加法。后续的噪声公式涉及 NOIA 的乘积和幂运算，在 log 域中全部退化为加法和乘法——避免了中间量溢出。最终结果（噪声功率谱密度，pA²/Hz 量级）转回线性域时在 FP32 范围内。

$\log(6.25 \times 10^{41}) = 96.2$ —— 远小于 FLT_MAX ≈ 3.4×10³⁸。

### 4.4 平方差分解（Vbseff）

恒等式：

$$T_0^2 - C = (T_0 - \sqrt{C})(T_0 + \sqrt{C})$$

**为什么有效**：当 $T_0^2$ 和 $C$ 接近相等时，直接相减丢失有效位。将减法移到 sqrt 外面——$(T_0 - \sqrt{C})$ 和 $(T_0 + \sqrt{C})$ 不在接近相等的危险区间内（前者接近 0，后者远离 0），乘积恢复精度。

**代价**：多 1 次 sqrt 运算，但 sqrt 在 FP32 中也是精确到 ε_machine 的。

---

## 5. 为什么可行性分析不需要运行仿真

总结起来，静态可行性分析依赖三个数学支柱：

| 支柱 | 内容 | 不依赖仿真的原因 |
|------|------|-----------------|
| **范围分析** | 区间算术计算每个中间值的上界 | 只需参数范围（datasheet 或工艺文件），无需具体值 |
| **条件数分析** | 对每个减法/加法估算 $\kappa_{sub}$ | 条件数是操作数的函数，可用典型值或区间估计 |
| **链式累积** | $\kappa_{total} \approx \prod \kappa_j$ | 这是误差分析的标准结论（Higham, §3），不依赖仿真 |

**最终判定逻辑**：

```
if (任何中间量 > FLT_MAX):
    → 溢出问题
    if (可以用 log 恒等式重写):
        → 🟢 纯 FP32 可解决
    else:
        → 🔴 需要 FP64

elif (任何减法 κ_sub > 10⁴, 即丢失 >4 个十进制位):
    → 消去问题
    if (单层消去, κ_chain < 10⁵):
        → 🟡 补偿算术可解决 (Dekker, double-double)
    elif (嵌套消去链, κ_chain > 10⁵):
        → 🔴 需要 FP64（或 double-double 开销过大）
    else:
        → 🟢 平方差/对数和差等恒等式变换可解决

else:
    → 🟢 FP32 无问题
```

这个决策树是**完全确定性的**——$\kappa$ 和区间边界是数学量，不是测量量。

---

## 6. 边界案例：Vth k1ox 再审查

回顾 Vth k1ox 孤岛的条件数：

$$\kappa_{sub} = \frac{|\text{k1ox} \cdot \sqrt{\phi_s}| + |\text{k1} \cdot \sqrt{\phi_0}|}{|\text{k1ox} \cdot \sqrt{\phi_s} - \text{k1} \cdot \sqrt{\phi_0}|} \approx \frac{16.5 + 0.2}{16.3} \approx 1.02$$

这个条件数说明减法本身只丢失不到 1 个有效位（$\log_{10}(1.02) \approx 0.01$ 个十进制位）。

**那么为什么它被标记为 FP64 孤岛？**

可能的原因不是"消去误差"本身，而是：

1. **参数 k1ox 和 k1 的量级差异**（~100×）意味着 $\sqrt{\phi_s}$ 和 $\sqrt{\phi_0}$ 的微小差异（来自 $\phi_s = f(V_{bs})$ 和 $\phi_0$ 的独立计算）会被 k1ox 放大 100 倍——这是**输入敏感度**问题，不是减法条件数问题。

2. **下游放大链**：Vth → Vth 的微小误差 → exp(Vgs−Vth) → Ids 的指数放大。1mV 的 Vth 误差 ≈ 4% Ids 变化（亚阈值斜率 ~60mV/dec）。

从这个角度看，该孤岛的正确定性应为：**减法本身条件良好，但输入敏感度 + 下游放大链要求额外的尾数精度**。这仍然可以静态分析——只需扩展到输入参数的敏感度分析 $\partial V_{th}/\partial k_{1ox}$ 和输出链 $\partial I_{ds}/\partial V_{th}$。

---

## 7. 结论

该可行性分析方法是 Wilkinson 向后误差分析在 BSIM4 模型上的直接应用：

1. **IEEE 754 保证**每个浮点运算的误差是确定的、有界的
2. **条件数**是操作数的纯数学函数——不需要仿真
3. **区间算术**判断溢出——不需要仿真
4. **链式累积**预测总精度损失——不需要仿真
5. **修复的可行性**由数值分析理论保证——log 恒等式（精确）、Dekker 减法（可证明的误差界）、平方差分解（精确）

6 个孤岛中 4 个可以用纯 FP32 数值方法解决，不是因为"试过了可以"，而是因为**数值分析理论保证了可以**。只有 Abulk 和 Leff/Weff 的多层嵌套消去链累积误差超过了 FP32 补偿方法的有效范围——但这些都不在热路径上。

---

## 参考文献

- Wilkinson, J.H. (1963). *Rounding Errors in Algebraic Processes*. Prentice-Hall.
- Higham, N.J. (2002). *Accuracy and Stability of Numerical Algorithms* (2nd ed.). SIAM. §3: Floating Point Arithmetic.
- Dekker, T.J. (1971). "A floating-point technique for extending the available precision." *Numerische Mathematik*, 18:224–242.
- Goldberg, D. (1991). "What Every Computer Scientist Should Know About Floating-Point Arithmetic." *ACM Computing Surveys*, 23(1):5–48.
- Kahan, W. (1965). "Pracniques: further remarks on reducing truncation errors." *Communications of the ACM*, 8(1):40.
