# 三线评审与修订记录（2026-10-25）

稿件：`submission_JCM_20261025/manuscript/JCM_Manuscript.md`
评审：统计方法（v4-pro）、ICU 临床（chat）、医学编辑（v4-pro）；均为独立、只读。

## 三线结论

| 线 | 判断 | 核心问题 |
|---|---|---|
| 统计 | 小修 | 摘要把事后分析写成结论；同一对比两套 CI；ns() 术语；增量模型同源；AUC 未 MI 合并；图 B 与正文不符 |
| 临床 | 大修 | DNR/去复苏/住院时长混杂未讨论；增量模型受存活条件限制；C 组"独立"表述过强；结论不可落地 |
| 编辑 | 需修改后投 | 摘要 455 词超限；Ref 2 作者串损坏；声明缺 IRB/知情同意/作者贡献；补充表引用顺序 S3→S2→S1；S1 为中文 |

## 已执行的修订

### 统计
1. 摘要压缩至 **205 词**，事后分析统一标 exploratory。
2. 删除不可复现的 1.58 (1.00–2.51) 口径；全稿统一 Table 2 插补集，C 组 1.61 (1.10–2.36)；Table S4 注明重复口径结果相同。
3. "restricted cubic spline" → "natural cubic spline (restricted cubic spline)"；补 df=3/5 节位敏感性（p=0.65 / 0.78）。
4. 增量模型：删"dominated"，改"contributed more"，并明确两成分同源（和为 72h）、比较为描述性。
5. 判别力：ΔAUC 0.0077 标注事后且不解释；补 MI 合并 AUC（0.7163→0.7265, Δ0.0102）。
6. 图 5 重绘：横轴截到 P95、纵轴 0.6–3，Panel B 不再出现数据范围外的上扬。
7. §2.9 补功效说明：校正连续平衡的对比非预设、力度不足。

### 临床
8. §3.5 删去"time-dependent effect would predict"，改为两种解释并列。
9. §3.8/§4.2：C 组改为"numerically unchanged… not pre-specified and less powered"，不再称独立。
10. §4.2 新增去复苏表型（入院前利尿、入院后限液）作为与通透性并列的解释；删"points to capillary leak"因果化表述。
11. §4.3 新增第七条局限：无 DNR/治疗限制、无入院前利尿剂、无 ICU 暴露时长；C 组年龄大、心衰多、住得久。
12. 结论改为条件式："描述表型、提示追问为什么湿，而非风险分层工具"。

### 编辑
13. 摘要 205 词（≤250，接近 200）。
14. Ref 2 修复为 "…(PETAL) Clinical Trials Network"；6 条页区间补全；Refs 6–11 统一 Title Case。
15. 声明拆为标准六项：Author Contributions / Funding / IRB Statement / Informed Consent Statement / Data Availability Statement / Conflicts of Interest；删除未使用的 MIMIC-IV-Note。
16. 补充表重编号：S1 模型设定（原 S3）、S2 一致性、S3 敏感性（原 S1，并译成英文）、S4 新增。
17. SOFA、IQR 首次出现补全称。

## 验证

- 数字审计 57 项：**ALL PASS**（`_build/number_audit_v4.txt`）
- DOCX：Word 只读打开无修复提示，278 段、2 表、7,259 词
- 参考文献 24 条，编号连续、全部被引
- Figure 1–5 引用与图注齐全；Table 1–2、S1–S4 全部被引

## 未解决（需人工或需新数据）

| 项 | 原因 |
|---|---|
| DNR/CMO、入院前利尿剂、ICU 暴露时长 | DNR/CMO 已补齐（itemid 223758/228687，24 h 内 184 例 4.6%，全程 365 例 9.2%；Table S5，§4.3 第六条的数值已改为实测）。入院前利尿剂、ICU 暴露时长仍不可得 |
| 作者/CRediT/Funding/COI/仓库 URL | 作者信息 |
| CheXpert DOI/页码、STROBE 页码 | 需出版社页面与排版后页码 |
| 外部验证 | eICU 无结构化影像淤血变量 |
