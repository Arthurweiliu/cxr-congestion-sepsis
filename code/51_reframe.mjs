import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
let bad = 0;
const rep = (a, b, l) => { if (!md.includes(a)) { console.error("MISSING: " + l); bad++; return; } md = md.replace(a, b); };

// 1. title
rep("# Radiographic pulmonary congestion and measured fluid balance in sepsis: discordance and independent association with 30-day mortality",
    "# Discordance between radiographic congestion and measured fluid balance in sepsis: a cohort study of 3,963 patients", "title");

// 2. abstract background
rep("Two small studies (n=102 and n=50) reported no association between congestion and outcome and no correlation between fluid balance and other congestion measures, but both were underpowered.",
    "Two small studies (n=50 and n=102) examined related questions and reached broadly negative conclusions, but neither was powered to quantify agreement.", "abstract background");

// 3. abstract methods emphasis
rep("Patients were cross-classified into four groups. The primary outcome was 30-day all-cause mortality.",
    "The primary analysis quantified agreement between the two measures; cross-classification into four groups and 30-day mortality were secondary.", "abstract methods");

// 4. abstract results
rep("Of 25,596 sepsis admissions, 7,050 had an eligible radiograph, 4,576 were classifiable and 4,352 had calculable fluid balance;",
    "Of 25,596 first sepsis-associated ICU admissions in adults, 7,050 had an eligible radiograph, 6,595 could be matched to a report, 4,576 were classifiable and 4,352 had calculable fluid balance;", "abstract results 6595");

rep("The estimate for discordant congestion lay between 1.49 and 2.41 in ten of thirteen pre-specified sensitivity analyses; it was not significant with a 24-h fluid window (1.13, 0.77–1.67), with complete output recording (1.46, 0.98–2.19), or with in-hospital mortality (1.60, 0.97–2.63).",
    "The estimate for group C varied with comorbidity specification (1.39–2.41) and was not significant in three of thirteen sensitivity analyses: a 24-h fluid window (1.13, 0.77–1.67), complete output recording (1.46, 0.98–2.19) and in-hospital mortality (1.60, 0.97–2.63); the adjusted 90-day estimate was 1.38 (0.99–1.92).", "abstract results sensitivity");

// 5. abstract conclusions
rep("**Conclusions.** Radiographic reports of pulmonary oedema and measured fluid balance are largely discordant in sepsis, and each carries independent prognostic information: oedema reported on imaging remained associated with mortality even when the measured balance was non-positive. The added discrimination (ΔAUC 0.0097) fell below the pre-specified 0.01 threshold for clinical relevance, and at present the radiograph report should be read as a descriptor of phenotype rather than as a risk-stratification tool.",
    "**Conclusions.** Radiographic congestion and measured fluid balance disagree more than chance would predict, and one in three patients with radiographic congestion has a non-positive balance. Radiographic congestion carries some prognostic information, but it adds no meaningful discrimination and should be read as a descriptor of phenotype rather than as a risk-stratification tool.", "abstract conclusions");

// 6. intro first sentence split + individual citations
rep("Sepsis is characterised by vasodilation, endothelial injury and capillary leak, and resuscitation therefore generates a positive fluid balance in most patients [1]; randomised comparisons of restrictive and liberal fluid strategies have not demonstrated a mortality benefit [2,3]. Accumulated fluid is consistently associated with organ dysfunction and death [4–6], but the effect size is modest and varies with admission haemoglobin, ventilatory settings and haemodynamic phenotype [7–9], and is difficult to separate from the severity of illness that drives both the fluid given and the outcome.",
    "Sepsis is characterised by vasodilation, endothelial injury and capillary leak. Resuscitation commonly produces a positive fluid balance [1], and randomised comparisons of restrictive with liberal strategies have not demonstrated a mortality benefit [2,3]. Accumulated fluid is consistently associated with organ dysfunction and death [4–6], but the effect size is modest; it varies with admission haemoglobin [7], ventilatory settings [8] and haemodynamic phenotype [9], and is difficult to separate from the severity of illness that drives both the fluid given and the outcome.", "intro first para");

// 7. discussion first para
rep("Each measure was independently associated with 30-day mortality, and patients who were concordantly positive had the highest risk.",
    "Each measure was associated with 30-day mortality, although the estimate for the discordant group was sensitive to comorbidity specification and did not survive every sensitivity analysis.", "discussion para1");

rep("The association with discordant radiographic congestion was robust across ten of thirteen pre-specified sensitivity analyses, but radiographic congestion improved discrimination only marginally (ΔAUC 0.010).",
    "Ten of thirteen sensitivity analyses gave an estimate above 1 for the discordant group, but radiographic congestion improved discrimination only marginally (ΔAUC 0.0097).", "discussion ten of thirteen");

// 8. conclusion
rep("In sepsis, the chest radiograph and the fluid chart disagree about congestion more often than not, and both are independently associated with death. Radiographic congestion identifies a group at higher risk that is not captured by the fluid chart, but it adds little to discrimination and should be regarded as a descriptor of phenotype rather than a risk-stratification tool.",
    "In sepsis, radiographic congestion and the fluid chart disagree more often than chance would predict. Radiographic congestion carries some prognostic information that the chart alone does not, but it adds no meaningful discrimination and should be regarded as a descriptor of phenotype rather than as a risk-stratification tool.", "conclusion");

// 9. secondary outcomes: add adjusted 90-day
rep("Ninety-day mortality was 18.6% in group A, 25.3% in B, 26.3% in C and 37.7% in D; the crude odds ratios relative to A were 1.48 (95% CI 1.15–1.91), 1.56 (1.13–2.14) and 2.64 (2.02–3.45) respectively.",
    "Ninety-day mortality was 18.6% in group A, 25.3% in B, 26.3% in C and 37.7% in D; the crude odds ratios relative to A were 1.48 (95% CI 1.15–1.91), 1.56 (1.13–2.14) and 2.64 (2.02–3.45). After adjustment with the same covariates as the primary model, the odds ratios were 1.34 (1.03–1.75), 1.38 (0.99–1.92) and 2.03 (1.53–2.71).", "secondary 90d adjusted");

// 10. methods: reference S3
rep("Thirteen sensitivity analyses were performed:",
    "Three model specifications differing only in their comorbidity terms are reported in Table S3. Thirteen sensitivity analyses were performed:", "methods S3");

if (bad) { console.error("aborted, " + bad + " missing anchors"); process.exit(1); }
fs.writeFileSync(P, md, "utf8");
console.log("all replacements applied");
