// 96_crosscheck_tables.mjs — 正文与表格逐条交叉核对
import fs from "node:fs";

const ROOT = "F:/openclaw_workspace/CXR_congestion/submission_JCM_20261025";
const md = fs.readFileSync(`${ROOT}/manuscript/JCM_Manuscript.md`, "utf8");
const s3 = fs.readFileSync(`${ROOT}/tables_supplementary/Table_S3.md`, "utf8");
const s4 = fs.readFileSync(`${ROOT}/tables_supplementary/Table_S4.md`, "utf8");

const log = [];
let fail = 0;
const ok = (name, cond, extra = "") => { log.push(`${cond ? "PASS" : "FAIL"}\t${name}\t${extra}`); if (!cond) fail++; };

const block = (start, end) => {
  const a = md.indexOf(start); const b = md.indexOf(end, a);
  if (a < 0 || b < 0) return "";
  return md.slice(a, b);
};

// ---- Table 2 rows ----
const t2 = block("**Table 2.", "**Note.** OR, odds ratio");
const rows = t2.split("\n").filter(l => l.startsWith("|") && !/^\|[-: ]+\|/.test(l) && !l.startsWith("| Variable"));
const t2map = {};
for (const r of rows) {
  const c = r.split("|").map(x => x.trim()).filter(x => x !== "");
  if (c.length >= 3) t2map[c[0]] = { OR: c[1], CI: c[2] };
}
ok("Table 2 parsed 11 rows", Object.keys(t2map).length === 11, `n=${Object.keys(t2map).length}`);

// ---- §3.3 text must contain every OR/CI ----
const text = md;
const discussed = /^(Group|Age|SOFA|Lactate|Invasive ventilation|Heart failure|Chronic kidney disease)/;
for (const [label, v] of Object.entries(t2map)) {
  if (!discussed.test(label)) continue;
  const or = v.OR, [c1, c2] = v.CI.split("–");
  if (label.startsWith("Group")) {
    ok(`text: ${label}`, text.includes(`${or} (95% CI ${c1}–${c2})`) || text.includes(`${or} (${c1}–${c2})`), `${or} (${c1}–${c2})`);
    continue;
  }
  const form = label.startsWith("Age") ? `${or} per year, ${c1}–${c2}`
    : label.startsWith("SOFA") ? `${or} per point, ${c1}–${c2}`
    : label.startsWith("Lactate") ? `${or} per mmol/L, ${c1}–${c2}`
    : `${or}, ${c1}–${c2}`;
  ok(`text: ${label}`, text.includes(form), form);
}
for (const [label, v] of []) {
  const or = v.OR, ci = v.CI.split("–");
  const short = `${or} (${ci[0]}–${ci[1]})`;
  const alt = `${or} (95% CI ${ci[0]}–${ci[1]})`;
  const loose = `${or}, ${ci[0]}–${ci[1]}`;
  const present = text.includes(short) || text.includes(alt) || text.includes(loose) ||
                  text.includes(`${or} (${ci[0]}–${ci[1]})`) ||
                  text.includes(`${or}, ${ci[0]}–${ci[1]}`);
  if (label.startsWith("Group")) ok(`text: ${label}`, text.includes(`${or} (`) || text.includes(`${or}, `), short);
  else ok(`text: ${label}`, present, short);
}

// ---- Table 1 mortality must match §3.3 sentence ----
const t1 = block("**Table 1.", "**Note.** SMDs");
const mort = t1.split("\n").find(l => l.startsWith("| 30-day mortality"));
if (mort) {
  const pct = [...mort.matchAll(/\((\d+\.\d)%\)/g)].map(m => m[1]);
  for (const p of pct) ok(`Table1 mortality ${p}% in text`, text.includes(`${p}%`), p);
}

// ---- Abstract group ORs must equal Table 2 ----
const abs = md.slice(md.indexOf("**Results.**"), md.indexOf("**Conclusions.**"));
const getG = (g) => Object.entries(t2map).find(([k]) => k.startsWith(g))?.[1];
for (const g of ["Group B", "Group C", "Group D"]) {
  const v = getG(g);
  ok(`abstract ${g}`, abs.includes(`${v.OR} (${v.CI})`), `${v.OR} (${v.CI})`);
}

// ---- §3.5 must quote Table S3 values for the analyses it names ----
const s3rows = {};
for (const r of s3.split("\n").filter(l => l.startsWith("|") && !/^\|[-: ]+\|/.test(l) && !l.startsWith("| Specification"))) {
  const c = r.split("|").map(x => x.trim()).filter(x => x !== "");
  if (c.length >= 5) s3rows[c[0]] = c[4].replace(/\*/g, "").trim();
}
const named = {
  "S1 Findings-first definition": "1.72",
  "S3 Landmark at 72 h": "1.69",
  "S5 Frontal radiographs only": "1.68",
  "S12 Strict impression-only": "2.16",
  "S15 Lactate fallback hierarchy": "1.73",
  "S4 Excluding heart failure": "2.55"
};
for (const [k, expect] of Object.entries(named)) {
  const v = s3rows[k];
  ok(`S3 row ${k}`, v && v.startsWith(expect), `table=${v} text=${expect}`);
  ok(`§3.5 quotes ${expect}`, md.includes(expect), expect);
}

// ---- Table S4 C estimate must match §3.8 ----
const s4c = s4.split("\n").find(l => l.startsWith("| Group C"));
if (s4c) {
  const m = s4c.match(/\| ([\d.]+) \(([\d.]+)–([\d.]+)\) \|\s*$/);
  if (m) ok("§3.8 quotes Table S4 group C", md.includes(`${m[1]}, ${m[2]}–${m[3]}`), `${m[1]}, ${m[2]}–${m[3]}`);
}

fs.writeFileSync(`${ROOT}/_build/crosscheck.txt`, log.join("\n") + `\n\n${fail === 0 ? "ALL PASS" : fail + " FAIL"}\n`, "utf8");
console.log(log.join("\n"));
console.log(`\n${fail === 0 ? "ALL PASS" : fail + " FAIL"}`);
process.exit(fail === 0 ? 0 : 1);
