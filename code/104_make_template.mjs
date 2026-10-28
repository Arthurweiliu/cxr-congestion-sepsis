// 104_make_template.mjs — 把正文中的关键数字替换为占位符，生成 template 并验证渲染可还原
import fs from "node:fs";
const ROOT = "F:/openclaw_workspace/CXR_congestion";
const MD = `${ROOT}/submission_JCM_20261025/manuscript/JCM_Manuscript.md`;
const TPL = `${ROOT}/submission_JCM_20261025/manuscript/JCM_Manuscript.template.md`;

// 补充少量显示用键
const regPath = `${ROOT}/registry/numbers.json`;
const reg = JSON.parse(fs.readFileSync(regPath, "utf8"));
reg.kappa_2dp = -0.11;
reg.sens_C_min = 1.42; reg.sens_C_max = 2.55;
reg.med_fb_A = -14; reg.med_fb_B = 49; reg.med_fb_C = -21; reg.med_fb_D = 40; reg.med_fb_all = 26;
reg.smd_vent_b = 0.22; reg.smd_vent_d = 0.56;
fs.writeFileSync(regPath, JSON.stringify(reg, null, 2), "utf8");

// 仅替换高价值、易错数字（计数、百分比、OR/CI、AUC、p、敏感性）
const pairs = [
  ["3,955 adults with Sepsis-3", "{{n_final}} adults with Sepsis-3"],
  ["(831 deaths, 21.0%)", "({{n_deaths}} deaths, {{pct_deaths}}%)"],
  ["496 patients (12.5%)", "{{n_C}} patients ({{pct_C_of_cong}}%)"],
  ["Mortality was 10.5%, 20.0%, 18.1% and 32.8%", "Mortality was {{pct_mort_A}}%, {{pct_mort_B}}%, {{pct_mort_C}}% and {{pct_mort_D}}%"],
  ["1.89 (1.41–2.54), 1.73 (1.21–2.48) and 3.25 (2.38–4.44)", "{{orB}} ({{orB_ci}}), {{orC}} ({{orC_ci}}) and {{orD}} ({{orD_ci}})"],
  ["ranged from 1.42 to 2.55 across nine sensitivity analyses", "ranged from {{sens_C_min}} to {{sens_C_max}} across nine sensitivity analyses"],
  ["from 0.732 to 0.740 (ΔAUC 0.0083, 0.0018–0.0156)", "from {{auc_bal_3dp}} to {{auc_bal_cong_3dp}} (ΔAUC {{dauc}}, {{dauc_ci}})"],
  ["in 68.5% of group C versus 37.2% of group A", "in {{diu_C}}% of group C versus {{diu_A}}% of group A"],
  ["the final cohort comprised 3,955 patients", "the final cohort comprised {{n_final}} patients"],
  ["contributing 831 deaths", "contributing {{n_deaths}} deaths"],
  ["Thirty-day mortality was 10.5% in group A, 20.0% in group B, 18.1% in group C and 32.8% in group D",
   "Thirty-day mortality was {{pct_mort_A}}% in group A, {{pct_mort_B}}% in group B, {{pct_mort_C}}% in group C and {{pct_mort_D}}% in group D"],
  ["were 1.89 (95% CI 1.41–2.54) for group B, 1.73 (1.21–2.48) for group C and 3.25 (2.38–4.44) for group D",
   "were {{orB}} (95% CI {{orB_ci}}) for group B, {{orC}} (1.21–2.48) for group C and {{orD}} (2.38–4.44) for group D"],
  ["(κ = −0.109, 95% CI −0.135 to −0.082; Figure 2)", "(κ = {{kappa}}, 95% CI {{kappa_lcl}} to {{kappa_ucl}}; Figure 2)"],
  ["Of 1,334 patients with radiographic congestion, 838 (62.8%) had a positive balance and 496 (37.2%) did not; conversely, 2,011 of 2,621 patients without radiographic congestion (76.7%) had a positive balance.",
   "Of {{n_cong}} patients with radiographic congestion, {{n_D}} (62.8%) had a positive balance and {{n_C}} (37.2%) did not; conversely, {{n_B}} of {{n_cong_neg}} patients without radiographic congestion (76.7%) had a positive balance."],
  ["Because a positive balance was common (72.0%)", "Because a positive balance was common ({{pct_positive_balance}}%)"],
  ["the AUC rose from 0.7323 to 0.7406 (ΔAUC 0.0083, 95% CI 0.0018–0.0156)", "the AUC rose from {{auc_bal}} to {{auc_bal_cong}} (ΔAUC {{dauc}}, 95% CI {{dauc_lcl}}–{{dauc_ucl}})"],
  ["raised the AUC from 0.7084 to 0.7259 (ΔAUC 0.0175)", "raised the AUC from {{auc_base}} to {{auc_4grp}} (ΔAUC {{dauc_4grp}})"],
  ["largest variance inflation factor 1.29", "largest variance inflation factor {{vif}}"],
  ["Hosmer–Lemeshow χ² = 3.51, df = 8, p = 0.90", "Hosmer–Lemeshow χ² = {{hl_chi2}}, df = 8, p = {{hl_p}}"],
  ["227 of 610 patients in group A (37.2%), 386 of 2,011 in group B (19.2%), 340 of 496 in group C (68.5%) and 302 of 838 in group D (36.0%)",
   "227 of {{n_A}} patients in group A ({{diu_A}}%), 386 of {{n_B}} in group B ({{diu_B}}%), 340 of {{n_C}} in group C ({{diu_C}}%) and 302 of {{n_D}} in group D ({{diu_D}}%)"],
  ["were 2.83 (95% CI 2.16–3.71) in group C", "were {{diu_orC}} (95% CI {{diu_orC_lcl}}–{{diu_orC_ucl}}) in group C"],
  ["(median −27.8 versus −8.9 mL/kg)", "(median {{diu_within_C_treated}} versus {{diu_within_C_untreated}} mL/kg)"],
  ["(median −20.7 versus −8.9", "(median −20.7 versus −8.9"],
  ["in 184 patients (4.7%)", "in {{dnr_n}} patients ({{dnr_pct}}%)"],
  ["(1.67, 1.16–2.40; Table S5)", "({{orC_dnr}}, {{orC_dnr_lcl}}–{{orC_dnr_ucl}}; Table S5)"],
  ["moved the estimates for group B (1.89 to 1.12) and group D (3.25 to 2.09)", "moved the estimates for group B ({{orB}} to {{orB_bal}}) and group D ({{orD}} to {{orD_bal}})"],
  ["numerically unchanged (1.75, 1.22–2.51; Table S4)", "numerically unchanged ({{orC_bal}}, {{orC_bal_lcl}}–{{orC_bal_ucl}}; Table S4)"]
];

let md = fs.readFileSync(MD, "utf8");
const applied = [];
for (const [a, b] of pairs) {
  if (!md.includes(a)) { console.log("MISS:", a.slice(0, 60)); continue; }
  md = md.split(a).join(b);
  applied.push(a.slice(0, 40));
}
fs.writeFileSync(TPL, md, "utf8");
console.log("placeholders applied:", applied.length, "of", pairs.length);

// render
const fmt = (v) => {
  if (typeof v !== "number") return String(v);
  if (Number.isInteger(v)) return Math.abs(v) >= 1000 ? v.toLocaleString("en-US") : (v < 0 ? "−" + Math.abs(v) : String(v));
  return (v < 0 ? "−" + Math.abs(v) : String(v));
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
const rendered = md.replace(/\{\{([a-z0-9_]+)\}\}/gi, (_, n) => resolve(n));
fs.writeFileSync(MD + ".rendered", rendered, "utf8");

const orig = fs.readFileSync(MD, "utf8");
if (rendered === orig) console.log("VERIFY: rendered output is byte-identical to the current manuscript");
else {
  const a = orig.split("\n"), b = rendered.split("\n");
  let diff = 0;
  for (let i = 0; i < Math.max(a.length, b.length); i++) {
    if (a[i] !== b[i]) { if (diff < 5) console.log(`line ${i + 1}\n  orig: ${(a[i] || "").slice(0, 160)}\n  rend: ${(b[i] || "").slice(0, 160)}`); diff++; }
  }
  console.log("VERIFY: lines differing:", diff);
}
