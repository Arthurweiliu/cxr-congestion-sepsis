// 67_audit_v4_manuscript.mjs — 新稿数字与结构审计
import fs from "node:fs";

const MD = "F:/openclaw_workspace/CXR_congestion/submission_JCM_20261025/manuscript/JCM_Manuscript.md";
const CSV = "F:/openclaw_workspace/CXR_congestion/data/final_cohort.csv";
const md = fs.readFileSync(MD, "utf8");
const lines = fs.readFileSync(CSV, "utf8").trim().split(/\r?\n/);
const head = lines[0].split(",");
const col = Object.fromEntries(head.map((h, i) => [h, i]));
const rows = lines.slice(1).map(l => l.split(","));

const n = rows.length;
const death = rows.filter(r => r[col.death30] === "1").length;
const cong = rows.filter(r => Number(r[col.cong_hybrid]) === 1).length;
const grp = {};
for (const r of rows) {
  const g = Number(r[col.cong_hybrid]) === 1
    ? (Number(r[col.fb72_mlkg]) > 0 ? "D" : "C")
    : (Number(r[col.fb72_mlkg]) > 0 ? "B" : "A");
  grp[g] ??= { n: 0, d: 0 };
  grp[g].n++;
  if (r[col.death30] === "1") grp[g].d++;
}
const pct = (a, b) => (100 * a / b).toFixed(1);

const log = [];
let fail = 0;
const ok = (name, cond, extra = "") => {
  log.push(`${cond ? "PASS" : "FAIL"}\t${name}\t${extra}`);
  if (!cond) fail++;
};

// 1. 与源数据重算
ok("N = 3,963", n === 3963, `csv=${n}`);
ok("deaths 832", death === 832, `csv=${death}`);
ok("mortality 21.0%", pct(death, n) === "21.0", pct(death, n));
ok("congestion 1,338 (33.8%)", cong === 1338 && pct(cong, n) === "33.8", `${cong} / ${pct(cong, n)}%`);
for (const [g, expN, expP] of [["A", 467, "12.2"], ["B", 2158, "19.0"], ["C", 430, "19.3"], ["D", 908, "31.2"]]) {
  ok(`group ${g} n=${expN}`, grp[g].n === expN, `csv=${grp[g].n}`);
  ok(`group ${g} mortality ${expP}%`, pct(grp[g].d, grp[g].n) === expP, pct(grp[g].d, grp[g].n));
}

// 2. 稿件必须出现的字符串
const must = [
  ["abstract N", "3,955 adults with Sepsis-3 in MIMIC-IV (831 deaths, 21.0%)"],
  ["kappa", "κ = −0.11"],
  ["agreement 36.6%", "agreed in only 36.6%"],
  ["OR B", "1.89 (95% CI 1.41–2.54)"],
  ["OR C", "1.73 (1.21–2.48)"],
  ["OR D", "3.25 (2.38–4.44)"],
  ["AUC base", "0.7084"],
  ["AUC +groups", "0.7259"],
  ["dAUC", "ΔAUC 0.0083"],
  ["spline LR", "χ²=4.46, df=3, p=0.22"],
  ["knot sensitivity", "p=0.65 and 0.78"],
  ["interaction linear", "0.999 per 10 mL/kg, 0.972–1.027; p=0.97"],
  ["interaction spline", "χ²=1.19, df=4; p=0.88"],
  ["increment chi2", "χ²=104.6, df=4, p<0.001"],
  ["first24 chi2", "χ²=10.5, df=4, p=0.033"],
  ["group C 24h", "1.14, 0.77–1.69"],
  ["adjusted B", "1.89 to 1.12"],
  ["adjusted D", "3.25 to 2.09"],
  ["adjusted C", "1.75, 1.22–2.51"],
  ["Table S4 ref", "Table S4"],
  ["Figure 5A", "Figure 5A"],
  ["Figure 5B", "Figure 5B"],
  ["Figure 5C", "Figure 5C"],
  ["secondary analyses", "Four secondary analyses"],
];
for (const [name, s] of must) ok(name, md.includes(s), s.slice(0, 48));

// 3. 陈旧数字不得出现
const stale = [
  ["old C 1.62", "1.62 (1.12"],
  ["old D 2.55", "2.55 (1.86"],
  ["old dAUC 0.0101 only as IDI", "ΔAUC 0.0101"],
  ["old AUC wording", "Adding congestion increased the AUC"],
  ["old 'Exploratory interaction' heading", "Exploratory interaction"],
  ["removed unreproducible CI", "1.58, 1.00–2.51"],
  ["removed 112.5 chi2", "112.5"],
  ["MIMIC-IV-Note removed from declarations", "MIMIC-IV-Note"],
];
for (const [name, s] of stale) ok(name + " absent", !md.includes(s), s);

// 4. 图表引用完整性
const figRefs = new Set([...md.matchAll(/Figure (\d)/g)].map(m => m[1]));
for (const f of ["1", "2", "3", "4", "5"]) ok(`Figure ${f} cited`, figRefs.has(f));
const legends = [...md.matchAll(/\*\*Figure (\d)\.\*\*/g)].map(m => m[1]);
ok("5 figure legends", legends.length === 5 && legends.join(",") === "1,2,3,4,5", legends.join(","));
const tabRefs = new Set([...md.matchAll(/Table (S?\d)/g)].map(m => m[1]));
for (const t of ["1", "2", "S1", "S2", "S3", "S4"]) ok(`Table ${t} cited`, tabRefs.has(t));

// 5. 参考文献编号连续
const refLine = md.slice(md.indexOf("## References"), md.indexOf("## Figure Legends"));
const nums = [...refLine.matchAll(/^(\d+)\. /gm)].map(m => Number(m[1]));
const seq = nums.every((v, i) => v === i + 1);
ok("references 1..N sequential", seq, `n=${nums.length}, last=${nums.at(-1)}`);
const cited = new Set([...md.matchAll(/\[(\d+(?:[–-]\d+)?(?:,\s*\d+(?:[–-]\d+)?)*)\]/g)]
  .flatMap(m => m[1].split(",").flatMap(x => {
    const p = x.trim().split(/[–-]/).map(Number);
    return p.length === 2 ? Array.from({ length: p[1] - p[0] + 1 }, (_, i) => p[0] + i) : p;
  })));
const uncited = nums.filter(x => !cited.has(x));
ok("all references cited", uncited.length === 0, `uncited: ${uncited.join(",") || "none"}`);

// 6. 结构
ok("sections 1-5", ["## 1. Introduction", "## 2. Materials and Methods", "## 3. Results", "## 4. Discussion", "## 5. Conclusions"].every(s => md.includes(s)));
const words = md.replace(/[#|*]/g, " ").split(/\s+/).filter(Boolean).length;
ok("word count plausible", words > 6500 && words < 8500, `words≈${words}`);

fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/submission_JCM_20261025/_build/number_audit_v4.txt",
  log.join("\n") + `\n\n${fail === 0 ? "ALL PASS" : fail + " FAIL"}\n`, "utf8");
console.log(log.join("\n"));
console.log(`\n${fail === 0 ? "ALL PASS" : fail + " FAIL"}`);
process.exit(fail === 0 ? 0 : 1);








