// 102_patch_registry.mjs — 用表格（唯一由分析脚本生成的产物）覆盖 registry 中的模型估计
import fs from "node:fs";
const ROOT = "F:/openclaw_workspace/CXR_congestion";
const reg = JSON.parse(fs.readFileSync(`${ROOT}/registry/numbers.json`, "utf8"));

const rows = (file, start) => {
  const txt = fs.readFileSync(`${ROOT}/v4/film/${file}`, "utf8");
  return txt.split("\n").filter(l => l.startsWith("|") && !/^\|[-: ]+\|/.test(l) && !l.startsWith("| " + start));
};

// Table 2
const t2 = {};
for (const l of rows("T2.md", "Variable")) {
  const c = l.split("|").map(x => x.trim()).filter(x => x !== "");
  if (c.length >= 3) t2[c[0]] = { OR: Number(c[1]), CI: c[2].split("–").map(Number) };
}
const g = (p) => Object.entries(t2).find(([k]) => k.startsWith(p))[1];
for (const [k, tag] of [["B", "Group B"], ["C", "Group C"], ["D", "Group D"]]) {
  const v = g(tag);
  reg["or" + k] = v.OR; reg["or" + k + "_lcl"] = v.CI[0]; reg["or" + k + "_ucl"] = v.CI[1];
}
for (const [label, v] of Object.entries(t2)) {
  const slug = "t2_" + label.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "").slice(0, 28);
  reg[slug] = v.OR; reg[slug + "_lcl"] = v.CI[0]; reg[slug + "_ucl"] = v.CI[1];
}

// Table S2 (kappa)
const s2 = fs.readFileSync(`${ROOT}/v4/film/S2.md`, "utf8");
const m = s2.match(/\| Hybrid \(primary\) \| (\d+) \| ([\d.]+) \| ([\d.]+) \| (-?[\d.]+) \((-?[\d.]+) to (-?[\d.]+)\) \| (-?[\d.]+) \| ([\d.]+) \| ([\d.]+) \|/);
if (m) {
  reg.n_total = Number(m[1]);
  reg.po = Number((Number(m[2]) * 100).toFixed(1));
  reg.pe = Number((Number(m[3]) * 100).toFixed(1));
  reg.kappa = Number(m[4]); reg.kappa_lcl = Number(m[5]); reg.kappa_ucl = Number(m[6]);
  reg.pabak = Number(m[7]); reg.ppos = Number(m[8]); reg.pneg = Number(m[9]);
}

// Table S3 (sensitivity C estimates)
for (const l of rows("S3.md", "Specification")) {
  const c = l.split("|").map(x => x.trim()).filter(x => x !== "");
  if (c.length >= 5) {
    const v = c[4].replace(/\*/g, "");
    const mm = v.match(/([\d.]+) \(([\d.]+)-([\d.]+)\)/);
    if (mm) {
      const key = "sens_" + c[0].replace(/[^a-zA-Z0-9]+/g, "_").replace(/^_|_$/g, "").toLowerCase();
      reg[key] = Number(mm[1]); reg[key + "_lcl"] = Number(mm[2]); reg[key + "_ucl"] = Number(mm[3]);
    }
  }
}

fs.writeFileSync(`${ROOT}/registry/numbers.json`, JSON.stringify(reg, null, 2), "utf8");
console.log("registry keys:", Object.keys(reg).length, "| orB", reg.orB, "orC", reg.orC, "orD", reg.orD, "| kappa", reg.kappa);
