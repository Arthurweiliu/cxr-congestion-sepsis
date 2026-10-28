// audit_3944.mjs — verify the N=3,944 rebuild end to end
import fs from "node:fs";
const ROOT = "F:/openclaw_workspace/CXR_congestion";
const SUB = `${ROOT}/submission_JCM_20261025`;
const md = fs.readFileSync(`${SUB}/manuscript/JCM_Manuscript.md`, "utf8");
const reg = JSON.parse(fs.readFileSync(`${ROOT}/registry/numbers.json`, "utf8"));
const csv = fs.readFileSync(`${ROOT}/data/film_analysis.csv`, "utf8").trim().split(/\r?\n/);
const head = csv[0].split(",").map(h => h.replace(/^"|"$/g, ""));
const ix = Object.fromEntries(head.map((h, i) => [h, i]));
const rows = csv.slice(1).map(l => l.split(","));

const log = [];
let fail = 0;
const ok = (name, cond, extra = "") => { log.push(`${cond ? "PASS" : "FAIL"}\t${name}\t${extra}`); if (!cond) fail++; };

// A. recompute from the analytic file
const n = rows.length, death = rows.filter(r => r[ix.death30] === "1").length;
const cong = rows.filter(r => Number(r[ix.cong_hybrid]) === 1).length;
const g = {}; for (const r of rows) {
  const k = Number(r[ix.cong_hybrid]) === 1 ? (Number(r[ix.fb72_mlkg]) > 0 ? "D" : "C") : (Number(r[ix.fb72_mlkg]) > 0 ? "B" : "A");
  g[k] ??= { n: 0, d: 0 }; g[k].n++; if (r[ix.death30] === "1") g[k].d++;
}
const pct = (a, b) => (100 * a / b).toFixed(1);
ok("N = 3,944", n === 3944, `csv=${n}`);
ok("deaths 830", death === 830, `csv=${death}`);
ok("mortality 21.0%", pct(death, n) === "21.0", pct(death, n));
ok("congestion 1,331 (33.7%)", cong === 1331 && pct(cong, n) === "33.7", `${cong} / ${pct(cong, n)}%`);
for (const [k, en, ep] of [["A", 602, "10.5"], ["B", 2011, "20.0"], ["C", 493, "18.3"], ["D", 838, "32.8"]]) {
  ok(`group ${k} n=${en}`, g[k].n === en, `csv=${g[k].n}`);
  ok(`group ${k} mortality ${ep}%`, pct(g[k].d, g[k].n) === ep, pct(g[k].d, g[k].n));
}
const pos = rows.filter(r => Number(r[ix.fb72_mlkg]) > 0).length;
const po = rows.filter(r => (Number(r[ix.cong_hybrid]) === 1) === (Number(r[ix.fb72_mlkg]) > 0)).length / n;
const pe = (cong / n) * (pos / n) + (1 - cong / n) * (1 - pos / n);
const kap = (po - pe) / (1 - pe);
ok("kappa -0.109", Math.abs(kap - (-0.109)) < 0.002, kap.toFixed(3));

// registry agrees with source
ok("registry n_total", reg.n_total === n, reg.n_total);
ok("registry n_C", reg.n_C === g.C.n, reg.n_C);
ok("registry orC", reg.orC === 1.75, reg.orC);

// B. manuscript must contain
const must = [
  ["title n", "a cohort study of 3,944 patients"],
  ["abstract n", "Retrospective cohort of 3,944 adults"],
  ["abs C n", "493 patients (12.5%)"],
  ["abs mortality", "10.5%, 20.0%, 18.3% and 32.8%"],
  ["abs OR B", "1.90 (95% confidence interval [CI] 1.42–2.56)"],
  ["abs OR C", "1.75 (1.22–2.52)"],
  ["abs OR D", "3.27 (2.39–4.48)"],
  ["abs range", "1.40–2.64 across ten sensitivity analyses"],
  ["abs truncated", "1.40 (0.87–2.25)"],
  ["abs untruncated", "2.27 (1.27–4.04)"],
  ["abs diuretic", "Post hoc, loop diuretics followed the film"],
  ["abs applicability", "These findings apply to patients with a classifiable report and a calculable balance"],
  ["methods flow", "4,341 had calculable fluid balance"],
  ["methods screened", "leaving 4,167 patients"],
  ["methods final", "comprised 3,944 patients"],
  ["methods film pct", "2,464 films (62.5%) preceded admission"],
  ["methods 11 rule (recoverable time)", "whether or not the film time itself could be recovered"],
  ["methods sens", "reported separately for films taken before ICU admission"],
  ["results hf", "62.1% vs 32.9%"],
  ["results agreement", "36.5% observed against 42.8% expected"],
  ["results kappa ci", "−0.136 to −0.083"],
  ["results cells", "Of 1,331 patients with radiographic congestion, 838 (63.0%)"],
  ["results medians", "13.8 vs 32.6 mL/kg"],
  ["results 3.5 range", "1.40–2.64 across the ten sensitivity analyses"],
  ["results 3.5 both strata", "In the complementary 1,480 patients"],
  ["results 3.5 inhosp", "1.86 (1.17–2.95; 640 events)"],
  ["results provenance", "Of the 493 patients in group C, 435 (88.2%)"],
  ["results spline", "χ² = 3.98, df = 3, p = 0.26"],
  ["results increment", "χ² = 105.1, df = 4, p < 0.001"],
  ["results first24", "χ² = 11.1, df = 4, p = 0.025"],
  ["results S4", "1.77, 1.23–2.54"],
  ["results diuretic counts", "225 of 602 patients in group A (37.4%)"],
  ["results diuretic or", "2.84 (95% CI 2.16–3.72)"],
  ["discussion n", "In 3,944 patients with sepsis"],
  ["discussion eligible", "15.4% of the eligible sepsis admissions (3,944 of 25,596)"],
  ["discussion dnr", "183 patients (4.6%)"],
  ["discussion S5", "1.69, 1.18–2.44"],
  ["conclusion power-limited", "the C-versus-A contrast was power-limited"],
  ["conclusion diuretic explanation", "plausibly explains much of the discrepancy"],
  ["fig1 legend", "missing fluid balance (n=235)"],
  ["fig2 legend", "diagonal agreement rate is 36.5%"],
  ["fig4 legend", "shown as two strata, S16a and S16b"],
  ["conclusion hedging", "consistent with treatment given after the film"],
  ["methods 11 rule", "contained no charted intake or output record"],
  ["4.3 24-h current", "With a 24-h window the estimate for discordant congestion was 1.43 (1.00–2.05)"],
  ["3.3 group C mortality", "20.0% in group B, 18.3% in group C and 32.8% in group D"],
  ["3.5 two results", "Two results attenuated the estimate"],
  ["4.3 two results", "including the two results that attenuated"],
  ["abstract inside-ten", "in the 62.5% of patients whose window was truncated"],
  ["90-day = Table S1", "1.70 (95% CI 1.33–2.18), 1.49 (1.09–2.04) and 2.62 (2.00–3.43)"],
  ["conclusion below-chance", "agreed less often than chance would predict"],
  ["conclusion kappa CI", "95% CI −0.14 to −0.08"],
  ["conclusion not independent of magnitude", "neither its independence from the magnitude of the balance"],
  ["conclusion abstract truncation", "nor its excess risk in the 62.5% with a truncated window"],
  ["intro question 2", "beyond the direction of the fluid balance"],
  ["4.1 metric caveat", "consistent in direction with the descriptive component"],
  ["conclusion discrimination marginal", "improved discrimination only marginally"],
  ["terminology fixed", "denotes this cross-classification (group C) only"],
  ["title rebalanced", "Discordance between radiographic congestion and the charted fluid balance"],
  ["ARD CI", "7.8 percentage points (95% CI 3.6 to 12.0"],
  ["strict no backfill", "permits no structured-label backfill"],
  ["manual review caveat", "consistency check rather than a reliability study"],
  ["MI not repeated", "not repeated under multiple imputation"],
  ["ARD C vs A", "95% CI 3.6 to 12.0; 18.3% vs 10.5%"],
  ["interaction test", "χ² = 2.29, df = 3, p = 0.52"],
  ["complete-case n", "Complete-case estimates (n = 3,484)"],
  ["power note in table", "The C-versus-A contrast is power-limited"],
  ["chex distribution", "negative in 97 (3.1%)"],
  ["dose timing limit", "dose and timing were not analysed"],
  ["no substitution claim", "should therefore not replace existing risk scores or the fluid chart"],
  ["applicability", "These findings apply to patients with a classifiable report"],
  ["conclusion truncated detail", "particularly in the 62.5% of patients whose window was truncated"],
  ["conclusion truncated limit", "excess risk in the 62.5% with a truncated window was established"],
  ["HF not mechanistic", "does not by itself separate cardiogenic"],
  ["dAUC threshold precision", "upper confidence limit lies above it"],
];
for (const [k, s] of must) ok(k, md.includes(s), s.slice(0, 46));

// C. stale values must be absent
const stale = [
  ["3,955"], ["3,963"], ["831 deaths"], ["496 patients"], ["1.89 (1.41"], ["1.73 (1.21–2.48)"],
  ["3.25 (2.38"], ["1.39 (0.87–2.24)"], ["2.17 (1.22–3.83)"], ["62.8% of films"], ["68.3%"], ["37.0% of group A"],
  ["Missing lactate (464"], ["184 patients"], ["0.003 lies below"], ["1,334 patients"], ["2,621 patients"],
  ["0.7406"], ["0.0018–0.0156"], ["4.46, df=3"], ["104.6"], ["10.5, df=4"], ["n=2,532"],
  ["1.89 to 1.12"], ["3.25 to 2.09"], ["1.82 (1.15–2.87)"], ["1.67, 1.16–2.40"],
  ["most likely source"], ["1.42 (0.99–2.03)"],
  ["18.1%"], ["Two analyses attenuated"],
  ["close to statistically independent"], ["show poor agreement"], ["concordance no better than chance"],
  ["Once balance was modelled continuously, it added"], ["independent of fluid balance and of shock severity"],
  ["is associated with greater loop diuretic use: a cohort study"],
  ["discordance with the charted balance and greater loop diuretic use"],
  ["the pattern that treatment given after the film would produce"],
  ["The association is therefore not established in the 62.5%"], ["This may overstate the prevalence of radiographic congestion"],
  ["1.71 (95% CI 1.33–2.20)"], ["argues against pure cardiogenic"], ["Congestion and the chart disagree more than chance"],
];
for (const [s] of stale) ok(`absent: ${s}`, !md.includes(s), s);

// D. supplementary tables
const T = f => fs.readFileSync(`${SUB}/tables_supplementary/${f}`, "utf8");
const t1 = T("Table_S1.md"), t2 = T("Table_S2.md"), t3 = T("Table_S3.md"), t4 = T("Table_S4.md"), t5 = T("Table_S5.md");
ok("S1 M3 = Table 2", t1.includes("1.90 (1.42–2.56)") && t1.includes("1.75 (1.22–2.52)") && t1.includes("3.27 (2.39–4.48)"));
ok("S2 n=3944", t2.includes("| 3944 |"));
ok("S2 kappa", t2.includes("-0.109 (-0.136 to -0.083)"));
ok("S3 main", t3.includes("1.90 (1.42-2.56)") && t3.includes("1.75 (1.22-2.52)") && t3.includes("3.27 (2.39-4.48)"));
ok("S3 S16a", t3.includes("S16a") && t3.includes("1.40 (0.87-2.25)"));
ok("S3 S16b", t3.includes("S16b") && t3.includes("2.27 (1.27-4.04)"));
ok("S3 counting rule", t3.includes("two strata of one post hoc temporal analysis"));
ok("S3 strata sum to N", t3.includes("| 2464 |") && t3.includes("| 1480 |"));
ok("S4 base = Table 2", t4.includes("1.90 (1.42–2.56)") && t4.includes("1.77 (1.23–2.54)"));
ok("S4 n", t4.includes("n = 3,944, deaths = 830"));
ok("S5 n + dnr", t5.includes("n = 3,944") && t5.includes("183 patients (4.6%)"));
ok("S5 C", t5.includes("1.69 (1.18–2.44)"));

// E. figures
const figs = ["Fig1_flow.png", "Fig2_2x2.png", "Fig3_KM.png", "Fig4_forest.png", "Fig5_v4.png",
              "Figure1.tiff", "Figure2.tiff", "Figure3.tiff", "Figure4.tiff", "Figure5.tiff"];
const since = new Date("2026-10-28T16:15:00+08:00").getTime();
for (const f of figs) {
  const st = fs.existsSync(`${SUB}/figures/${f}`) ? fs.statSync(`${SUB}/figures/${f}`) : null;
  ok(`figure ${f}`, !!st && st.size > 5000 && st.mtimeMs > since, st ? `${st.size}B ${new Date(st.mtimeMs).toISOString().slice(11, 19)}` : "missing");
}

// F. structure
ok("sections 1-5", ["## 1. Introduction", "## 2. Materials and Methods", "## 3. Results", "## 4. Discussion", "## 5. Conclusions"].every(s => md.includes(s)));
const legends = [...md.matchAll(/\*\*Figure (\d)\.\*\*/g)].map(m => m[1]);
ok("5 figure legends", legends.length === 5 && legends.join(",") === "1,2,3,4,5", legends.join(","));
const figIdx = [1, 2, 3, 4, 5].map(n => md.indexOf(`Figure ${n}`));
ok("figures cited in ascending order", figIdx.every((v, i) => v > 0 && (i === 0 || v > figIdx[i - 1])), figIdx.join(","));
const methodsBlock = md.slice(md.indexOf("## 2. Materials"), md.indexOf("## 3. Results"));
ok("no figure cited in Methods", !/Figure\s\d/.test(methodsBlock));
const tOrder = [...new Set([...md.matchAll(/Table (S?\d)/g)].map(m => m[1]))];
ok("main tables cited 1 then 2", tOrder.filter(x => !x.startsWith("S")).join(",") === "1,2", tOrder.join("→"));
const supp = tOrder.filter(x => x.startsWith("S"));
ok("supplementary tables ascending", supp.join(",") === [...supp].sort((a, b) => +a.slice(1) - +b.slice(1)).join(","), supp.join("→"));
const tabRefs = new Set([...md.matchAll(/Table (S?\d)/g)].map(m => m[1]));
for (const t of ["1", "2", "S1", "S2", "S3", "S4"]) ok(`Table ${t} cited`, tabRefs.has(t));
const refLine = md.slice(md.indexOf("## References"), md.indexOf("## Figure Legends"));
const nums = [...refLine.matchAll(/^(\d+)\. /gm)].map(m => Number(m[1]));
ok("reference count", nums.length === 30, `n=${nums.length}`);
ok("references 1..N sequential", nums.every((v, i) => v === i + 1), `n=${nums.length}`);

// G. docx
const docx = `${SUB}/manuscript/JCM_Manuscript_template.docx`;
ok("template docx exists", fs.existsSync(docx), fs.existsSync(docx) ? `${(fs.statSync(docx).size / 1024).toFixed(0)}KB` : "");
const docxPlain = `${SUB}/manuscript/JCM_Manuscript.docx`;
ok("plain docx exists", fs.existsSync(docxPlain) && fs.statSync(docxPlain).size > 100000);

fs.writeFileSync(`${SUB}/_build/audit_3944.txt`, log.join("\n") + `\n\n${fail === 0 ? "ALL PASS" : fail + " FAIL"}\n`, "utf8");
console.log(log.filter(l => l.startsWith("FAIL")).join("\n") || "no failures");
console.log(`\n${fail === 0 ? "ALL PASS" : fail + " FAIL"} (${log.length} checks)`);
process.exit(fail === 0 ? 0 : 1);
