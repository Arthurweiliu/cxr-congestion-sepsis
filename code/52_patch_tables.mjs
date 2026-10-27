import fs from "node:fs";
const D = "F:/openclaw_workspace/CXR_congestion/tables/";

// --- Table 2: p = 0.000 -> <0.001
let t2 = fs.readFileSync(D + "T2_final.md", "utf8");
const before2 = (t2.match(/\| 0\.000 \|/g) || []).length;
t2 = t2.replace(/\| 0\.000 \|/g, "| <0.001 |");
fs.writeFileSync(D + "T2_final.md", t2, "utf8");
console.log("T2 p=0.000 replaced:", before2);

// --- Table 1: add % to binary rows
let t1 = fs.readFileSync(D + "T1_final.md", "utf8");
const binPrefix = ["| Female sex", "| Invasive ventilation", "| Vasopressor use",
  "| Heart failure", "| Chronic kidney disease", "| 30-day mortality"];
let changed = 0;
const lines = t1.split("\n").map(line => {
  if (!binPrefix.some(p => line.startsWith(p))) return line;
  return line.replace(/\((\d+\.\d)\)/g, (m, v) => { changed++; return `(${v}%)`; });
});
fs.writeFileSync(D + "T1_final.md", lines.join("\n"), "utf8");
console.log("T1 percentages annotated:", changed);

// --- Table S1: S16 label
let s1 = fs.readFileSync(D + "S1_final.md", "utf8");
const oldRow = s1.match(/\| S16[^|]*\|[^\n]*/);
if (oldRow) {
  const newRow = oldRow[0]
    .replace("S16 不清洗（原始 4,352）", "S16 不清洗、不做时间锚定（原始 4,352）");
  s1 = s1.replace(oldRow[0], newRow);
  fs.writeFileSync(D + "S1_final.md", s1, "utf8");
  console.log("S16 relabelled");
} else {
  console.log("S16 row not found");
}
