import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/registry/numbers.json";
const reg = JSON.parse(fs.readFileSync(P, "utf8"));
reg.smd_threshold = 0.10;
reg.spline_chi2 = 4.46;
fs.writeFileSync(P, JSON.stringify(reg, null, 2), "utf8");
console.log("spline_chi2", reg.spline_chi2, "smd_threshold", reg.smd_threshold);
