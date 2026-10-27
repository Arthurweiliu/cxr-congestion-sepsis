import fs from "node:fs";

const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
const before = md;

function rep(from, to, label) {
  if (!md.includes(from)) { console.error("MISSING: " + label + " :: " + from.slice(0, 60)); process.exitCode = 1; return; }
  md = md.replace(from, to);
}

// ---------- body citations ----------
rep("[3,19], but the effect size is modest", "[1,2], but the effect size is modest", "intro fluid refs");
rep("but the effect size is modest and difficult to separate",
    "but the effect size is modest and varies with comorbidity, ventilatory settings and haemodynamic phenotype [3–5], and is difficult to separate",
    "modifier refs");
rep("nor a comprehensive ultrasound assessment including lung ultrasound and the venous excess ultrasound score.",
    "nor a comprehensive ultrasound assessment including lung ultrasound and the venous excess ultrasound score [6].",
    "INCIVEX");
rep("dialysis requirement or renal recovery.",
    "dialysis requirement or renal recovery [7].",
    "Mund");
rep("using MIMIC-IV v2.2, which contains",
    "using MIMIC-IV v2.2 [8], which contains", "MIMIC-IV");
rep("We additionally used MIMIC-CXR, which provides",
    "We additionally used MIMIC-CXR [9], which provides", "MIMIC-CXR");
rep("meeting Sepsis-3 criteria were identified",
    "meeting Sepsis-3 criteria [10] were identified", "Sepsis-3");
rep("Structured CheXpert labels were used only",
    "Structured CheXpert labels [11] were used only", "CheXpert");
rep("Age, sex, SOFA score at the time of suspected infection",
    "Age, sex, SOFA score [12] at the time of suspected infection", "SOFA");
rep("Analyses used R 4.5.2.",
    "Analyses used R 4.5.2. The study is reported in accordance with the STROBE statement [13].", "STROBE");
rep("has precedent in critical care [22]", "has precedent in critical care [14]", "Puskarich");
rep("extravascular lung water [20,21]", "extravascular lung water [15,16]", "imaging refs");

// ---------- references block ----------
const REFS = `## References

1. Neyra JA, Li X, Canepa-Escaro F, Adams-Huet B, Toto RD, Yee J, et al. Cumulative fluid balance and mortality in septic patients with or without acute kidney injury and chronic kidney disease. *Crit Care Med* 2016;44:1891–1900. PMID 27352125.
2. Messmer AS, Zingg C, Müller M, Gerber JL, Schefold JC, Pfortmueller CA. Fluid overload and mortality in adult critical care patients — a systematic review and meta-analysis of observational studies. *Crit Care Med* 2020;48:1862–1870. PMID 33009098.
3. Tan SMY, Zhang Y, Chen Y, See KC, Feng M. Association of fluid balance with mortality in sepsis is modified by admission hemoglobin levels: a large database study. *PLoS One* 2021;16:e0252629. PMID 34125858.
4. Zhou D, Lv Y, Wang C, Li D. The modified effect of mechanical ventilation setting on relationship between fluid balance and hospital mortality for sepsis patients: a retrospective study. *BMC Anesthesiol* 2025;25:91. PMID 39979809.
5. Chen Y, Liufu R, Dong R, Cao MM, Peng JM, Wang CY, et al. Hemodynamic subphenotypes in septic shock and their different responses to fluid balance in relation to ICU mortality. *BMC Anesthesiol* 2025;25:613. PMID 41444865.
6. Wong A, Cheah K, Papathanakos G, Stefanini F, Zawadka M. The fluid paradox: dissociation between clinical and ultrasound parameters of fluid overload — results of the INCIVEX exploratory study. *Anaesthesiol Intensive Ther* 2026;58:59–65. PMID 41879150.
7. Mund C, Asmus K, Safi W, Ritter O, Petrus D, Patschan S, et al. Clinically evident cardiopulmonary congestion does not significantly impact the prognosis of patients with septic acute kidney injury. *J Clin Med Res* 2024;16:302–309. PMID 39027814.
8. Johnson AEW, Bulgarelli L, Shen L, Gayles A, Shammout A, Horng S, et al. MIMIC-IV, a freely accessible electronic health record dataset. *Sci Data* 2023;10:1. PMID 36596836.
9. Johnson AEW, Pollard TJ, Berkowitz SJ, Greenbaum NR, Lungren MP, Deng CY, et al. MIMIC-CXR, a de-identified publicly available database of chest radiographs with free-text reports. *Sci Data* 2019;6:317. PMID 31831740.
10. Singer M, Deutschman CS, Seymour CW, Shankar-Hari M, Annane D, Bauer M, et al. The Third International Consensus Definitions for Sepsis and Septic Shock (Sepsis-3). *JAMA* 2016;315:801–810. PMID 26903338.
11. Irvin J, Rajpurkar P, Ko M, et al. CheXpert: a large chest radiograph dataset with uncertainty labels and expert comparison. In Proceedings of the AAAI Conference on Artificial Intelligence, Honolulu, HI, USA, 27 January–1 February 2019; Volume 33, pp. 590–597. (Not indexed in PubMed.)
12. Vincent JL, Moreno R, Takala J, Willatts S, De Mendonça A, Bruining H, et al. The SOFA (Sepsis-related Organ Failure Assessment) score to describe organ dysfunction/failure. *Intensive Care Med* 1996;22:707–710. PMID 8844239.
13. von Elm E, Altman DG, Egger M, Pocock SJ, Gøtzsche PC, Vandenbroucke JP. The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement: guidelines for reporting observational studies. *Lancet* 2007;370:1453–1457. PMID 18064739.
14. Puskarich MA, Trzeciak S, Shapiro NI, Arnold RC, Heffner AC, Kline JA, et al. Prognostic value and agreement of achieving lactate clearance or central venous oxygen saturation goals during early sepsis resuscitation. *Acad Emerg Med* 2012;19:252–258. PMID 22435856.
15. Lindow T, Quadrelli S, Ugander M. Noninvasive imaging methods for quantification of pulmonary edema and congestion: a systematic review. *JACC Cardiovasc Imaging* 2023;16:1469–1484. PMID 37632500.
16. Assaad S, Kratzert WB, Shelley B, Friedman MB, Perrino A Jr. Assessment of pulmonary edema: principles and practice. *J Cardiothorac Vasc Anesth* 2018;32:901–914. PMID 29174750.
`;

const start = md.indexOf("## References");
const end = md.indexOf("## Figure legends");
if (start < 0 || end < 0 || end < start) { console.error("refs block bounds not found"); process.exit(1); }
md = md.slice(0, start) + REFS + "\n" + md.slice(end);

fs.writeFileSync(P, md, "utf8");

// ---------- verification ----------
const body = md.split("## References")[0];
const cited = new Set();
for (const m of body.matchAll(/\[([\d,\s–\-]+)\]/g)) {
  for (const part of m[1].split(",")) {
    const p = part.trim();
    if (/^\d+$/.test(p)) cited.add(+p);
    else if (/^\d+[–-]\d+$/.test(p)) {
      const [a, b] = p.split(/[–-]/).map(Number);
      for (let i = a; i <= b; i++) cited.add(i);
    }
  }
}
const total = 16;
const missing = [];
for (let i = 1; i <= total; i++) if (!cited.has(i)) missing.push(i);
console.log("cited:", [...cited].sort((a, b) => a - b).join(","));
console.log("missing:", missing.join(",") || "none");
console.log("changed chars:", md.length - before.length);
