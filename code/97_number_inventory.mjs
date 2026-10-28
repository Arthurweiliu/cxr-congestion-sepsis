import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/submission_JCM_20261025/manuscript/JCM_Manuscript.md";
const md = fs.readFileSync(P, "utf8");
const body = md.slice(0, md.indexOf("## References"));

// split into sections by headings
const parts = body.split(/\n(?=#{2,3} )/);
const out = [];
for (const p of parts) {
  const head = p.split("\n")[0].replace(/^#+\s*/, "").slice(0, 40);
  const nums = [...p.matchAll(/(?<![\w.])-?\d+(?:\.\d+)?%?/g)].map(m => m[0]);
  const uniq = [...new Set(nums)];
  out.push({ head, n: nums.length, uniq: uniq.join(" ") });
}
for (const o of out) {
  if (!o.uniq) continue;
  console.log(`\n## ${o.head}  (${o.n} tokens)`);
  console.log(o.uniq);
}
