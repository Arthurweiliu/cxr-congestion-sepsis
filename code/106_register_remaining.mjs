import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/registry/numbers.json";
const reg = JSON.parse(fs.readFileSync(P, "utf8").replace(/^\uFEFF/, ""));
Object.assign(reg, {
  pct_lac_available: 88.3, pct_lac_missing: 11.7, n_lac_missing: 464,
  pct_cong_neg_positive: 76.7, med_fb_lower: 13.6, med_fb_higher: 32.4,
  smd_death_selection: 0.08, mort_radio: 21.8, mort_noradio: 18.5, auc_selection: 0.53,
  spline_lin_or: 1.06, spline_lin_lcl: 1.04, spline_lin_ucl: 1.07,
  spline24_chi2: 2.29, spline24_p: 0.52, lin24_or: 1.02, lin24_lcl: 0.99, lin24_ucl: 1.04,
  int_spline_chi2: 1.19, int_spline_p: 0.88, joint_chi2: 63.9,
  sens24_B: 1.18, sens24_B_lcl: 0.88, sens24_B_ucl: 1.57,
  n_diu_A: 227, n_diu_B: 386, n_diu_C: 340, n_diu_D: 302,
  n_provenance: 437, pct_provenance: 88.1, n_inhospital_events: 641,
  pct_cohort_of_eligible: 15.5, n_incivex: 50, n_mund: 102,
  fold_larger: 79, power_pct: 80
});
fs.writeFileSync(P, JSON.stringify(reg, null, 2), "utf8");
console.log("keys:", Object.keys(reg).length);
