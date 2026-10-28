import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/registry/numbers.json";
const reg = JSON.parse(fs.readFileSync(P, "utf8"));
const add = { ...reg,
  n_sepsis3: 32971, n_first: 25596, n_film: 7050, n_matched: 6595,
  n_classifiable: 4576, n_fb_calculable: 4352, n_screened: 4178, n_final: 3955,
  ex_no_report: 455, ex_no_lungs: 2019, ex_no_fb: 224, ex_implausible: 174,
  ex_weight: 7, ex_fb_implausible: 155, ex_vad: 12, ex_timing: 223,
  n_unknown: 1729, unknown_mort: 22.4,
  pct90_A: 16.4, pct90_B: 26.6, pct90_C: 25.0, pct90_D: 39.4,
  or90_B: 1.72, or90_B_lcl: 1.34, or90_B_ucl: 2.21,
  or90_C: 1.49, or90_C_lcl: 1.09, or90_C_ucl: 2.04,
  or90_D: 2.65, or90_D_lcl: 2.02, or90_D_ucl: 3.47,
  hf_C_pct: 61.9, hf_A_pct: 32.8, smd_hf: 0.61, age_C: 72, age_A: 67, smd_age: 0.28,
  smd_sofa: 0.18, smd_vaso: 0.09, smd_lac: -0.04, smd_vent: 0.02,
  diu_any_A: 40.2, diu_any_B: 19.4, diu_any_C: 70.4, diu_any_D: 36.5,
  diu_within_C_treated: -27.8, diu_within_C_untreated: -8.9,
  diu_within_B_treated: 48.0, diu_within_B_untreated: 48.8,
  dnr_n: 184, dnr_pct: 4.7,
  epv: 76, n_params: 11, vif: 1.29, hl_chi2: 3.51, hl_p: 0.90,
  film_median: 1.4, film_q1: -3.5, film_q3: 1.7, film_pct_pre: 62.8,
  pct_positive_balance: 72.0, sub_n: 2486,
  sub_orB: 1.43, sub_orB_lcl: 0.98, sub_orB_ucl: 2.08,
  sub_orC: 1.42, sub_orC_lcl: 0.89, sub_orC_ucl: 2.28,
  sub_orD: 2.51, sub_orD_lcl: 1.68, sub_orD_ucl: 3.74,
  sens_count: 9
};
fs.writeFileSync(P, JSON.stringify(add, null, 2), "utf8");
console.log("keys:", Object.keys(add).length);
