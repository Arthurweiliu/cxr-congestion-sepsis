// 105_render_manuscript.mjs — 从模板 + registry 渲染终稿
import fs from "node:fs";
const ROOT = "F:/openclaw_workspace/CXR_congestion";
const TPL = `${ROOT}/submission_JCM_20261025/manuscript/JCM_Manuscript.template.md`;
const OUT = `${ROOT}/submission_JCM_20261025/manuscript/JCM_Manuscript.md`;
const reg = JSON.parse(fs.readFileSync(`${ROOT}/registry/numbers.json`, "utf8"));

const fmt = (v) => {
  if (typeof v !== "number") return String(v);
  if (Number.isInteger(v)) return Math.abs(v) >= 1000 ? v.toLocaleString("en-US") : (v < 0 ? "−" + Math.abs(v) : String(v));
  return v < 0 ? "−" + Math.abs(v) : String(v);
};
const resolve = (name) => {
  if (/^(or|sub_or|diu_or)/.test(name) && typeof reg[name] === "number") return reg[name].toFixed(2);
  if (/pct|_mort_|^diu_[A-D]$/.test(name) && typeof reg[name] === "number") return reg[name].toFixed(1);
  if (/_3dp$/.test(name) && typeof reg[name] === "number") return reg[name].toFixed(3);
  if (/^(hl_p|spline_p|inc_p)$/.test(name) && typeof reg[name] === "number") return reg[name].toFixed(2);
  if (/^auc_/.test(name) && !/_3dp$/.test(name)) return reg[name].toFixed(4);
  if (name.endsWith("_ci")) {
    const base = name.slice(0, -3);
    return fmt(reg[base + "_lcl"]) + "–" + fmt(reg[base + "_ucl"]);
  }
  if (!(name in reg)) throw new Error("unknown placeholder: " + name);
  return fmt(reg[name]);
};

const tpl = fs.readFileSync(TPL, "utf8");
const out = tpl.replace(/\{\{([a-z0-9_]+)\}\}/gi, (_, n) => resolve(n));
fs.writeFileSync(OUT, out, "utf8");
const used = new Set([...tpl.matchAll(/\{\{([a-z0-9_]+)\}\}/gi)].map(m => m[1]));
console.log(`rendered ${used.size} distinct placeholders → ${OUT}`);
