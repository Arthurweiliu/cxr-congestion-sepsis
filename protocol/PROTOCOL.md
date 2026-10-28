# Protocol

**Study:** Discordance between radiographic congestion and fluid balance in sepsis is partly explained by diuretic treatment

## Design

Retrospective cohort study using MIMIC-IV v2.2 and MIMIC-CXR.

## Population

Adults (≥18 years) with Sepsis-3 criteria and a first sepsis-associated ICU stay. A chest radiograph within ±24 h of ICU admission was required and was matched to its radiology report (closest chart time within ±2 h). Patients were excluded for missing admission weight, implausible weight (<20 or >300 kg), implausible fluid balance, ventricular assist device or heart transplantation, and suspected infection outside ±24 h of ICU admission. Reports that never described the lungs could not be classified and were excluded from the primary analysis; they are described separately.

## Exposures

**Radiographic congestion (t0).** Classification of the index film from the radiology report, in a fixed hierarchy: explicit oedema in the impression (positive); explicit negation or "clear lungs" (negative); otherwise the findings section; structured CheXpert labels were used only to assign positivity when both sections were silent. Studies that never described the lungs were classified as unknown and analysed as a separate category.

**Fluid balance (t0 → t0 + 72 h).** Sum of charted intake minus charted output over the 72 h **following the index film**, divided by admission weight. Anchoring the window to the film ensures that the balance follows the exposure in time.

## Cross-classification

Four groups among classifiable patients: A (no congestion, balance ≤0), B (no congestion, balance >0), C (congestion, balance ≤0), D (congestion, balance >0).

## Outcomes

30-day all-cause mortality (primary clinical outcome); in-hospital and 90-day mortality; ICU length of stay; ventilator-free days; loop diuretic administration after the film.

## Statistical analysis

- Agreement: Cohen's κ, expected agreement, PABAK, positive and negative agreement.
- Mortality: multivariable logistic regression of the four-level exposure, adjusted for age, sex, SOFA, lactate, invasive ventilation, vasopressors, heart failure and chronic kidney disease; multiple imputation (m = 20) for missing lactate; joint Wald test across group indicators.
- Discrimination: congestion added to a model containing a natural cubic spline for 72-h balance (primary); four-level exposure added to a model without a balance term (secondary).
- Secondary analyses: spline for non-linearity; interaction with congestion; 24-h versus 24–72 h increment; adjustment for continuous balance and for documented limitations of treatment.
- Sensitivity analyses (nine): findings-first definition; 72-h landmark; excluding heart failure; frontal films only; 24-h window; complete output recording; in-hospital mortality; strict impression-only definition; lactate fallback hierarchy.

## Time anchoring

The index film was taken a median of 1.4 h before ICU admission (IQR −3.5 to +1.7); 62.8% of films preceded admission and none followed it by more than 24 h.

