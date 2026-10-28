# Radiographic congestion, fluid balance and diuretic treatment in sepsis (MIMIC-IV)

Reproducibility package for the manuscript:

> **Discordance between radiographic congestion and fluid balance in sepsis is associated with greater loop diuretic use: a cohort study of 3,955 patients**
> Wei Liu, Dongqing Ma, Jian Jiang, Xuefeng Xu, Rongjuan Zeng, Aoqiong Li, Bo Zhu (corresponding)

## What the study asks

In sepsis, the chest radiograph and the cumulative fluid balance are both used to judge whether a patient is congested, although they describe different things: a film is a snapshot, a balance is a running total. We quantified their agreement, examined how much of the disagreement is explained by treatment given after the film, and assessed the prognostic value of each.

## Data

Secondary analysis of **MIMIC-IV v2.2** and **MIMIC-CXR**, available from PhysioNet (https://physionet.org) to credentialed users. **Patient-level data are not redistributed here.** Only analysis code and aggregate results are provided.

## Cohort

```
32,971  ICU admissions meeting Sepsis-3
25,596  first sepsis-associated ICU admission in adults
 7,050  chest radiograph within ±24 h of ICU admission
 6,595  matched to a radiology report
 4,576  classifiable for congestion status
 3,955  analysed (classifiable, with calculable film-anchored balance)
```

831 deaths within 30 days (21.0%). Exposure window: from the index film to 72 h later.

## Key results

| Analysis | Result |
|---|---|
| Agreement, film vs subsequent 72-h balance | κ = −0.109 (95% CI −0.136 to −0.083); observed 36.6%, expected 42.9% |
| Congestion with a non-positive balance | 500 / 1,338 (37.4%) |
| 30-day mortality, A / B / C / D | 10.4% / 20.0% / 18.2% / 32.8% |
| Adjusted OR vs A | B 1.93 (1.44–2.58); C 1.75 (1.22–2.51); D 3.31 (2.42–4.52) |
| Discrimination | AUC 0.7315 → 0.7401 with congestion over a spline for balance (ΔAUC 0.0086, 0.0028–0.0153) |
| Loop diuretics after the film | A 37.3%, B 19.2%, C 68.8%, D 36.0%; adjusted OR C vs A 2.85 (2.18–3.73) |
| Within group C, treated vs untreated | 72-h balance −28.2 vs −8.9 mL/kg |
| Non-linearity | χ² = 4.27, df = 3, p = 0.23 (spline vs linear) |
| Interaction with congestion | OR 0.999 (0.972–1.026), p = 0.93 |

## Contents

```
code/01_build_cohort.sql        cohort assembly from MIMIC-IV
code/01b–01e_*.sql              report classification, hybrid definition, lactate, window variables
code/18_vad_list.sql            device / transplant exclusions
code/19_clean_and_hierarchy.R   cleaning, congestion hierarchy, structured-label backfill
code/20_criteria_audit.sql      audit of each inclusion criterion
code/21–22_*.sql                staged and final cohort views
code/23_final_models.R          multiple imputation, four-group logistic model, Tables 1–2
code/24_sensitivity_final.R     sensitivity analyses
code/54–58_*.sql                film-level and pre-film balance extracts
code/69–93_*.R                  film-anchored exposure, five-group models, sensitivity analyses, figures
protocol/PROTOCOL.md            analysis protocol
tables/                         aggregate tables (Table 1, Table 2, Supplementary S1–S5)
manuscript.md                   manuscript source (without figures)
```

## Reproducing

1. Obtain credentialed access to MIMIC-IV v2.2 and MIMIC-CXR and load them into PostgreSQL (`mimiciv_hosp`, `mimiciv_icu`, `mimiciv_note`).
2. Run the SQL scripts in `code/` in numeric order; they create the working schema `cxr`.
3. Run the R scripts with R ≥ 4.2 and `mice`, `pROC`, `splines`, `ggplot2`.
4. Scripts assume the working directory of the original analysis; adjust `setwd()` at the top of each R file.

Random seeds are set in every script that involves imputation or bootstrap resampling.

## Interpretation we do and do not claim

The radiograph and the fluid chart disagree substantially, and a wet film with a non-positive balance is common. Much of that pattern follows treatment given after the film, so the chart records the response to the radiograph rather than an independent measurement of congestion. Congestion carries some prognostic information but adds little discrimination once balance, lactate and SOFA are known. The study is observational: it does not support using the radiograph to trigger diuresis, and it does not establish a causal effect of either measure.

## Licence

Code released under the MIT licence. Aggregate tables may be reused with attribution.

