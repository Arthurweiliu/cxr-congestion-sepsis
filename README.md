# Radiographic congestion and measured fluid balance in sepsis (MIMIC-IV)

Reproducibility package for the manuscript:

> **Discordance between radiographic congestion and measured fluid balance in sepsis: a cohort study of 3,963 patients**
> Wei Liu, Dongqing Ma, Jian Jiang, Xuefeng Xu, Rongjuan Zeng, Aoqiong Li, Bo Zhu (corresponding)

## What the study asks

Pulmonary congestion in sepsis is assessed in two routine ways — the cumulative fluid balance on the chart and the chest radiograph — and the two are commonly treated as interchangeable. We quantified their agreement and tested whether either carries prognostic information the other does not.

## Data

This is a secondary analysis of **MIMIC-IV v2.2** and **MIMIC-CXR**, available from PhysioNet (https://physionet.org) to credentialed users who complete the required training. **Patient-level data are not redistributed here**, in accordance with the data use agreements. Only analysis code and aggregate results are provided.

## Cohort

```
32,971  ICU admissions meeting Sepsis-3
25,596  first sepsis-associated ICU admission in adults
 7,050  chest radiograph within ±24 h of ICU admission
 6,595  matched to a radiology report
 4,576  classifiable for congestion status
 4,352  fluid balance calculable
 3,963  analysed after plausibility and timing screens
```

832 deaths within 30 days (21.0%); radiographic congestion in 1,338 (33.8%).

## Key results

| Analysis | Result |
|---|---|
| Agreement, radiographic congestion vs 72-h balance | κ = −0.11 (observed agreement 34.7%; PABAK −0.31) |
| Congestion with a non-positive balance | 430 / 1,338 (32.1%) |
| 30-day mortality, groups A / B / C / D | 12.2% / 19.0% / 19.3% / 31.2% |
| Adjusted OR vs group A | B 1.43 (1.05–1.96); C 1.59 (1.08–2.33); D 2.44 (1.76–3.39) |
| Discrimination | AUC 0.7073 → 0.7171 (ΔAUC 0.0097, 0.002–0.017) |
| Post hoc: non-linearity | none (natural spline vs linear, χ² = 1.46, df = 3, p = 0.69) |
| Post hoc: interaction with congestion | none (linear p = 0.68; spline p = 0.89) |
| Post hoc: timing | first 24 h χ² = 12.6 vs 24–72 h increment χ² = 119.0 |
| Sensitivity: code status within 24 h | group C 1.53 (1.04–2.25) |

## Contents

```
code/01_build_cohort.sql        cohort assembly from MIMIC-IV (Sepsis-3, sepsis timing, plausibility screens)
code/01b–01e_*.sql              report classification, hybrid congestion definition, lactate, window variables
code/18_vad_list.sql            ventricular assist device / transplant exclusions
code/19_clean_and_hierarchy.R   cleaning, congestion hierarchy, CheXpert backfill
code/20_criteria_audit.sql      audit of each inclusion criterion
code/21–22_*.sql                staged and final cohort views
code/23_final_models.R          multiple imputation (m = 20), four-group logistic model, Table 1–2
code/24_sensitivity_final.R     13 sensitivity analyses
code/54_fb_prefilm.sql          fluid balance preceding each film
code/58_film_events.sql         film-level events with preceding 24-h balance
code/63_v4_extension.R          post hoc spline / interaction / increment / balance-adjusted models
code/65_v4_figures.R            Figure 5
code/66_v4_table2_addon.R       Table S4 (four groups before and after adjustment for continuous balance)
code/67_audit_v4_manuscript.mjs number audit of the manuscript against source CSVs
code/69_v4_final_numbers.R      authoritative single-imputation-set numbers for Section 3.8
code/70_dnr_sensitivity.R       code status sensitivity analysis (Table S5)
code/71_code_status.sql         extraction of DNR/DNI/comfort-measures status
protocol/PROTOCOL_v1.5.md       pre-specified protocol
protocol/PROTOCOL_CHANGELOG.md  full design history, including abandoned designs and why
tables/                         aggregate result tables (Table 1–2, Supplementary S1–S5)
```

## Reproducing

1. Obtain credentialed access to MIMIC-IV v2.2 and MIMIC-CXR and load them into PostgreSQL (schemas `mimiciv_hosp`, `mimiciv_icu`, `mimiciv_note`).
2. Run the SQL scripts in `code/` in numeric order; they create the working schema `cxr`.
3. Run the R scripts with R ≥ 4.2 and the packages `mice`, `pROC`, `splines`, `ggplot2`, `patchwork`.
4. Scripts assume the working directory used in the original analysis; adjust `setwd()` at the top of each R file.

Random seeds are set in every script that involves imputation or bootstrap resampling, so the reported estimates reproduce exactly.

## Interpretation we do and do not claim

The radiograph and the fluid chart are not interchangeable, and a wet film with a negative balance is common rather than anomalous. Radiographic congestion carries prognostic information that the chart does not, but adds little discrimination once balance, lactate and SOFA are known. The study is observational: it does not support using the radiograph to trigger diuresis, and it does not establish that either measure is causal.

## Licence

Code released under the MIT licence. Aggregate tables may be reused with attribution.
