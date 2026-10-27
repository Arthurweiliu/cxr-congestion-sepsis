import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
const md = fs.readFileSync(P, "utf8");
const log = [];
let fail = 0;
const ok = (name, cond, extra = "") => {
  log.push(`${cond ? "PASS" : "FAIL"}\t${name}\t${extra}`);
  if (!cond) fail++;
};

const must = [
  ["N=3,963", "3,963"], ["deaths 832", "832"], ["21.0%", "21.0%"],
  ["grp A 12.2%", "12.2%"], ["grp B 19.0%", "19.0%"],
  ["grp C 19.3%", "19.3%"], ["grp D 31.2%", "31.2%"],
  ["OR B", "1.43 (95% CI 1.05–1.96)"], ["OR C", "1.59 (1.08–2.33)"], ["OR D", "2.44 (1.76–3.39)"],
  ["kappa", "κ = −0.11"], ["agreement", "34.7%"],
  ["AUC base", "0.7073"], ["AUC new", "0.7171"], ["deltaAUC", "0.0097"],
  ["lactate coverage", "88.3%"], ["unknown OR", "1.70 (1.24–2.33)"],
  ["thirteen", "ten of thirteen"], ["S2 n", "1,729"],
  ["sample size C", "group C (n=430)"], ["sample size A", "group A (n=467)"],
];
for (const [n, s] of must) ok(n, md.includes(s), s);

const stale = [
  ["old deaths 933", "933"], ["old C count 503 in power", "group C (n=471)"],
  ["old congestion n 1,491", "1,491"],
  ["old OR C 1.62", "1.62 (1.12–2.34)"], ["old OR D 2.55", "2.55 (1.86–3.50)"],
  ["old AUC 0.7035", "0.7035"], ["old prevalence 34.3%", "34.3%"],
  ["old mortality 21.4%", "21.4%"], ["old mortality 12.1%", "12.1%"],
  ["old mortality 31.5%", "31.5%"], ["old 'eight of eleven'", "eight of eleven"],
  ["old 'Eleven sensitivity'", "Eleven sensitivity analyses"],
  ["old '87-fold'", "87-fold"], ["old '43 times'", "43 times"],
  ["old unknown OR 1.75", "1.75, 1.29–2.37"],
];
for (const [n, s] of stale) ok(n + " absent", !md.includes(s), s);

const hits4352 = [...md.matchAll(/4,352/g)].length;
const flowOK = /4,576 were classifiable and 4,352 had calculable fluid balance/.test(md) &&
               /4,576 could be classified for congestion status and 4,352 had calculable fluid balance/.test(md);
ok("4,352 only in the two flow sentences", hits4352 === 2 && flowOK, `count=${hits4352}`);

const chk = [
  ["430/3963 = 10.8%", Math.abs(430 / 3963 * 100 - 10.8) < 0.15],
  ["57/467 = 12.2%", Math.abs(57 / 467 * 100 - 12.2) < 0.15],
  ["409/2158 = 19.0%", Math.abs(409 / 2158 * 100 - 19.0) < 0.15],
  ["83/430 = 19.3%", Math.abs(83 / 430 * 100 - 19.3) < 0.15],
  ["283/908 = 31.2%", Math.abs(283 / 908 * 100 - 31.2) < 0.15],
  ["832/3963 = 21.0%", Math.abs(832 / 3963 * 100 - 21.0) < 0.15],
  ["1338/3963 = 33.8%", Math.abs(1338 / 3963 * 100 - 33.8) < 0.15],
  ["3963/102 = 39x", Math.abs(3963 / 102 - 39) < 1],
  ["3963/50 = 79x", Math.abs(3963 / 50 - 79) < 1],
];
for (const [n, c] of chk) ok(n, c);

fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/submission_JCM_20261023/_build/number_audit.txt",
  log.join("\n") + "\n", "utf8");
console.log(log.filter(l => l.startsWith("FAIL")).join("\n") || "ALL PASS");
console.log(`checks: ${log.length}, failures: ${fail}`);
