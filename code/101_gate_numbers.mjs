// 101_gate_numbers.mjs — 数字闸门：正文中每个数字必须可追溯到 registry 或白名单
import fs from "node:fs";

const ROOT = "F:/openclaw_workspace/CXR_congestion";
const md = fs.readFileSync(`${ROOT}/submission_JCM_20261025/manuscript/JCM_Manuscript.md`, "utf8");
const reg = JSON.parse(fs.readFileSync(`${ROOT}/registry/numbers.json`, "utf8"));

const body = md.slice(0, md.indexOf("## References"))
  .split("\n").filter(l => !l.trimStart().startsWith("|")).join("\n");
// strip citations [1], [2,3], [4–6] and section numbers at line starts
const cleaned = body
  .replace(/\[\d+(?:[–,-]\s*\d+)*\]/g, " ")
  .replace(/^#{1,3}\s*\d+(?:\.\d+)*\.?\s*/gm, " ")
  .replace(/\bSection \d+(?:\.\d+)?/g, " ");

// allowed structural values
const allow = new Set([
  "1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","30","48","72","90","95","500","0.05","0.01","20","300","100","0.3","2008","2019","50813","221794","228340","229639","4.5","0.001","0.003","0.05","1.6","3.8"
]);

const regValues = new Set();
for (const v of Object.values(reg)) {
  const s = String(v);
  regValues.add(s);
  const n = Number(v);
  if (Number.isFinite(n)) {
    regValues.add(Math.abs(n).toFixed(0));
    regValues.add(Math.abs(n).toFixed(1));
    regValues.add(Math.abs(n).toFixed(2));
    regValues.add(Math.abs(n).toFixed(3));
    regValues.add(Math.abs(n).toFixed(4));
    regValues.add(Math.abs(n).toLocaleString("en-US"));
  }
}

const tokens = [...cleaned.matchAll(/(?<![\w.])-?\d[\d,]*(?:\.\d+)?/g)].map(m => m[0]);
const unknown = new Map();
for (const raw of tokens) {
  const t = raw.replace(/,/g, "");
  if (regValues.has(raw) || regValues.has(t) || allow.has(t)) continue;
  const key = raw;
  if (!unknown.has(key)) {
    const i = cleaned.indexOf(raw);
    unknown.set(key, cleaned.slice(Math.max(0, i - 55), i + 45).replace(/\s+/g, " "));
  }
}

const out = [];
out.push(`registry keys: ${Object.keys(reg).length}`);
out.push(`numeric tokens: ${tokens.length}; untraceable: ${unknown.size}`);
out.push("");
for (const [k, ctx] of [...unknown.entries()].sort((a, b) => b[0].length - a[0].length)) {
  out.push(`${k}\t…${ctx}…`);
}
fs.writeFileSync(`${ROOT}/registry/gate_report.txt`, out.join("\n") + "\n", "utf8");
console.log(out.slice(0, 60).join("\n"));
console.log(`\n${unknown.size} untraceable token(s); full report: registry/gate_report.txt`);
