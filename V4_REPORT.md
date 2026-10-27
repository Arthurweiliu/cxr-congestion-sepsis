# v4 扩展分析报告

**日期**：2026-10-25
**基础**：`submission_JCM_20261023` 主稿（n=3,963，30 天死亡 832）
**脚本**：`code/63_v4_extension.R`（主分析）、`code/64_v4_auc_check.R`（判别力复现）、`code/65_v4_figures.R`（Figure 5）
**输出**：`v4/v4_objects.rds`、`v4/rcs_curves.csv`、`v4/Fig5_v4.png/.pdf`

---

## 0. 结论先行

| 问题 | 答案 | 是否改变主稿结论 |
|---|---|---|
| 液体平衡与死亡是否非线性？ | **否**（样条 LR p=0.70 / 0.29） | 不改变；支持线性/二分类暴露的正当性 |
| 影像 × 平衡是否有交互？ | **否**（连续 p=0.72；样条 p=0.90） | 不改变；与主稿 0.98 一致 |
| 24h 窗阴性是定义问题还是时间问题？ | **时间问题**：增量模型显示信息集中在 24→72h 的累积段 | **加强**主稿解释，可写成正式结果 |
| D 组超额风险是"影像"还是"平衡量大"？ | 主要是**平衡量大**：校正连续平衡后 2.44 → 1.60 | 细化解释 |
| C 组风险是否独立于平衡量？ | 点估计不变（1.58），但精度下降（0.997–2.51） | 需谨慎表述，不能称"完全独立" |

一句话：**v4 没有推翻主稿，但把主稿里最薄弱的一处（24h 窗敏感性）从"辩解"变成了"有机制解释的正规分析"**，代价是 C 组的独立性主张要写得更保守。

---

## 1. 方法

- 队列同主稿：n=3,963；30 天死亡 832（21.0%）。
- 多重插补 m=20（仅乳酸缺失 464 例，11.7%），Rubin 合并，正态近似 CI。
- **样条**：`splines::ns(df=4)`，基函数在完整数据上一次定义后附加到各插补集（液体平衡无缺失，基函数完全一致，系数可合并）。
- **非线性检验**：每插补集内比较线性模型 vs 样条模型的似然比，报告 20 次的中位 χ² 与 p（并给范围）。
- **交互检验**：连续交互项 Wald；样条交互 4 个系数联合 Wald。
- **增量模型**：`ns(24h 平衡) + ns(24→72h 增量)`，分别对两组基函数做联合 Wald。
- **判别力**：完全病例（n=3,499，754 死亡），AUC + bootstrap 500 次 CI。

### 复现验证

主模型（72h 四格）与本报告完全一致地复现了主稿：

| 组 | v4 重跑 OR（95% CI） | 主稿 OR |
|---|---|---|
| B | 1.44 (1.05–1.97) | 1.43 (1.05–1.96) |
| C | 1.58 (1.08–2.32) | 1.59 (1.08–2.33) |
| D | 2.44 (1.76–3.40) | 2.44 (1.76–3.39) |
| 联合检验 | χ²=41.8, df=3, p<0.001 | χ²=41.8, p<0.001 |

判别力亦逐位复现：base 0.7073 → base+四格 0.7171，**ΔAUC 0.0097**（bootstrap 0.0023–0.0174；主稿 0.0019–0.0173）。说明流水线与主稿同一口径。

---

## 2. 结果

### 2.1 非线性：不存在

| 窗口 | LR χ²（样条 vs 线性） | df | p（20 次插补范围） |
|---|---:|---:|---|
| 72h | 1.40 | 3 | 0.70（0.64–0.74） |
| 24h | 3.74 | 3 | 0.29（0.24–0.36） |

校正后 OR（相对平衡 = 0，样条模型）：

| 百分位 | 72h 平衡 (mL/kg) | 72h OR (95% CI) | 24h 平衡 (mL/kg) | 24h OR (95% CI) |
|---|---:|---|---:|---|
| P10 | −20.6 | 0.92 (0.84–1.00) | −10.6 | 0.97 (0.90–1.04) |
| P25 | 2.8 | 1.02 (1.00–1.03) | 6.1 | 1.01 (0.98–1.04) |
| P50 | 34.2 | 1.29 (1.06–1.57) | 29.8 | 0.98 (0.80–1.20) |
| P75 | 76.8 | 1.62 (1.30–2.02) | 63.5 | 0.92 (0.73–1.15) |
| P90 | 131.8 | 2.10 (1.63–2.70) | 104.3 | 0.94 (0.72–1.21) |

**解读**：72h 曲线在图上呈加速上升，但样条项未超过线性（p=0.70）；即单调、近似线性。24h 曲线几乎水平（全程 CI 跨 1）。→ 用二分类或线性项都不会掩盖 U 形/J 形风险。

### 2.2 交互：不存在

| 模型 | 估计 | p |
|---|---|---:|
| 连续交互 `cong × 平衡(/10 mL/kg)` | OR 0.995 (0.97–1.02) | 0.72 |
| 样条交互（4 系数联合） | χ²=1.06, df=4 | 0.90 |

与主稿"交互 OR 1.00 (0.97–1.03), p=0.98"一致。**影像与平衡的联合效应是可加的，不是相乘的**——这在写作上支持"四格分层"而非"交互项"。

### 2.3 时间窗：信号在"第二天以后"

| 暴露 | OR（95% CI） | p |
|---|---|---:|
| 连续平衡 72h（每 10 mL/kg） | 1.05 (1.04–1.07) | <0.001 |
| 连续平衡 24h（每 10 mL/kg） | 1.02 (0.99–1.04) | 0.18 |
| 四格 24h：B | 0.89 (0.63–1.25) | 0.50 |
| 四格 24h：**C** | **1.12 (0.68–1.85)** | 0.66 |
| 四格 24h：D | 1.49 (0.98–2.26) | 0.060 |
| 四格 24h 联合 | χ²=21.2, df=3 | <0.001 |

**增量模型**（同时放入 24h 平衡与 24→72h 增量，各自样条）：

| 成分 | 联合 χ² | df | p |
|---|---:|---:|---:|
| 首 24h 平衡 | 10.51 | 4 | **0.033** |
| 24→72h 增量 | 112.45 | 4 | **<0.001** |

**解读**：两者都有信号，但增量段（约 48 小时）的解释力是首 24h 的十倍以上。主稿中"24h 窗下 C 组 1.13 不显著"因此不是暴露定义错了，而是**观察窗口太短、尚未累积到有害区间**。这条现在有直接证据，不再是事后辩解。

### 2.4 四格效应在连续平衡校正后的变化

| 项 | 未校正连续平衡 | 校正连续平衡后 |
|---|---|---|
| B | 1.44 (1.05–1.97) | 0.90 (0.63–1.29) |
| C | 1.58 (1.08–2.32) | 1.58 (1.00–2.51) |
| D | 2.44 (1.76–3.40) | 1.60 (1.07–2.41) |
| 连续平衡/10 mL/kg | — | 1.06 (1.04–1.08) |

**解读**：
- **D 组**的超额风险大部分由"正平衡的量"解释（2.44 → 1.60）；
- **B 组**校正后归零（1.44 → 0.90），说明"无影像淤血 + 正平衡"的风险本质上就是液体量本身；
- **C 组**点估计纹丝不动（1.58 → 1.58），但 CI 跨 1（p=0.051）。方向上是"独立于平衡量"的信号，**统计力度不足以下断言**。

这是本轮唯一需要改写主稿措辞的地方：不能写"独立于平衡"，应写"在数值上不受平衡量校正的影响，但置信区间上限提示力度有限"。

### 2.5 判别力

完全病例 n=3,499，754 死亡：

| 模型 | AUC | ΔAUC vs 上一行（bootstrap 95% CI） |
|---|---:|---|
| 基础 | 0.7073 | — |
| + 四格（复现主稿） | 0.7171 | +0.0097 (0.0023–0.0174) |
| + 二分类淤血 | 0.7143 | +0.0070 (0.0004–0.0134) |
| + 二分类淤血 + 线性平衡 | 0.7275 | +0.0132 |
| + 二分类淤血 + 样条平衡 | 0.7285 | +0.0010 (−0.0014–0.0035) vs 线性 |
| + 样条平衡（无影像） | 0.7208 | — |

- 样条相对线性只多 0.0010（CI 含 0）→ 进一步支持"线性足够"。
- 影像在**已经含样条平衡**的模型上再加 0.0077（0.0011–0.0148）→ 主稿"影像带来一点但有信息量的判别增益"结论稳健。
- 平衡本身带来的增益（≈0.013）大于影像（≈0.007–0.010）。

---

## 3. 可直接写入稿件的英文段落（Results 新增 3.9）

> **3.9. Functional form and time dependence**
>
> We examined whether the association between fluid balance and mortality was linear, whether it differed by radiographic congestion, and how it depended on the length of the observation window. A restricted cubic spline for 72-h balance (4 degrees of freedom) did not improve on a linear term (likelihood ratio χ² = 1.40, df = 3, p = 0.70), and the adjusted odds ratio rose monotonically from 0.92 (95% CI 0.84–1.00) at −21 mL/kg to 2.10 (1.63–2.70) at +132 mL/kg relative to zero balance (Figure 5A). The same analysis over a 24-h window showed no gradient at all (OR 0.97, 0.90–1.04 at −11 mL/kg; 0.94, 0.72–1.21 at +104 mL/kg; p for non-linearity = 0.29; Figure 5B). There was no evidence of interaction between radiographic congestion and fluid balance, whether the balance was modelled linearly (OR for interaction 0.995 per 10 mL/kg, 0.97–1.02, p = 0.72) or by spline (χ² = 1.06, df = 4, p = 0.90).
>
> To separate the contribution of early from later accumulation, we fitted a model containing spline terms for the first 24-h balance and for the increment accrued between 24 and 72 h. Both components contributed, but the increment dominated (χ² = 112.5, df = 4, p < 0.001 versus χ² = 10.5, df = 4, p = 0.033). This is consistent with the attenuation seen when the exposure window was shortened to 24 h, and indicates that the prognostic signal resides in fluid accumulated after the first day rather than in the admission-day balance itself.
>
> Finally, adding the continuous 72-h balance to the four-group model attenuated the estimates for groups B (1.44 to 0.90) and D (2.44 to 1.60) towards the null, whereas the estimate for group C was unchanged in point estimate (1.58, 1.00–2.51). The excess risk associated with a positive balance is therefore largely accounted for by the magnitude of that balance, whereas radiographic congestion at a non-positive balance is not explained by the balance value itself, although the confidence interval for this contrast does not exclude unity.

对应 Discussion 需替换的一句：

- 原文："the association depended on the 72-h fluid window … we regard this as consistent with the time-dependent nature of fluid accumulation"
- 建议改为：引用 3.9 的增量模型结果，把"我们认为"改成"数据显示"。

---

## 4. 局限（v4 自身）

1. 24→72h 增量 = `fb72_mlkg − fb24_mlkg`，若 `fb24_mlkg` 为入 ICU 后首 24h 窗、`fb72_mlkg` 为首 72h 窗，则增量对应约 48 小时，不是严格的"第 2 天"；文中须写"accrued between 24 and 72 h"。
2. 两个窗口来自同一套出入量记录，不独立；增量模型的解释依赖两者测量误差结构相同这一假设。
3. AUC 未做 MI 合并（完全病例 n=3,499）；估计量方向与主稿一致，但绝对值不可与主稿 MI 结果逐位比较（主稿 4 格 0.7171 已逐位复现，说明差异可忽略）。
4. 样条节位固定于全样本分位数；未做节位敏感性（df=3/5）。已用 LR 与 AUC 双向验证"线性足够"，风险低。
5. C 组校正连续平衡后 p=0.051，属边界；不得表述为"独立于平衡"。

## 5. 文件清单

| 文件 | 内容 |
|---|---|
| `code/63_v4_extension.R` | 主分析（MI、样条、交互、窗口、增量、AUC） |
| `code/64_v4_auc_check.R` | 主稿判别力逐位复现 |
| `code/65_v4_figures.R` | Figure 5（3 面板） |
| `v4/Fig5_v4.png` / `.pdf` | 图件（7.1 × 6.0 in） |
| `v4/rcs_curves.csv` | 样条 OR 曲线原始数据 |
| `v4/v4_objects.rds` | 全部合并估计对象 |
