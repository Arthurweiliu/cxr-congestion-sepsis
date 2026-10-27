import fs from "node:fs";

const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
const cut = md.indexOf("## References");
const body = md.slice(0, cut);
const refsSec = md.slice(cut);

// parse existing reference entries
const entries = {};
for (const line of refsSec.split("\n")) {
  const m = line.match(/^(\d+)\.\s+(.*)$/);
  if (m) entries[+m[1]] = m[2];
}
const total = Object.keys(entries).length;
console.log("existing refs:", total);

// collect citation order
const order = [];
function pushNum(n) { if (!order.includes(n)) order.push(n); }
for (const m of body.matchAll(/\[([\d,\s–\-]+)\]/g)) {
  for (const p0 of m[1].split(",")) {
    const p = p0.trim();
    if (/^\d+$/.test(p)) pushNum(+p);
    else if (/^\d+[–-]\d+$/.test(p)) {
      const [a, b] = p.split(/[–-]/).map(Number);
      for (let i = a; i <= b; i++) pushNum(i);
    }
  }
}
console.log("first-appearance order (old numbers):", order.join(","));
const missing = [];
for (let i = 1; i <= total; i++) if (!order.includes(i)) missing.push(i);
if (missing.length) { console.error("refs never cited:", missing.join(",")); process.exit(1); }

const map = new Map(order.map((old, idx) => [old, idx + 1]));

// rewrite body citations
function compact(nums) {
  const s = [...new Set(nums)].sort((a, b) => a - b);
  const parts = [];
  let i = 0;
  while (i < s.length) {
    let j = i;
    while (j + 1 < s.length && s[j + 1] === s[j] + 1) j++;
    if (j - i >= 2) { parts.push(`${s[i]}–${s[j]}`); i = j + 1; }
    else { parts.push(String(s[i])); i++; }
  }
  return parts.join(",");
}
const newBody = body.replace(/\[([\d,\s–\-]+)\]/g, (full, inner) => {
  const nums = [];
  for (const p0 of inner.split(",")) {
    const p = p0.trim();
    if (/^\d+$/.test(p)) nums.push(map.get(+p));
    else if (/^\d+[–-]\d+$/.test(p)) {
      const [a, b] = p.split(/[–-]/).map(Number);
      for (let i = a; i <= b; i++) nums.push(map.get(i));
    }
  }
  return "[" + compact(nums) + "]";
});

// rebuild reference section in new order
const lines = ["## References", ""];
order.forEach((old, idx) => lines.push(`${idx + 1}. ${entries[old]}`));
lines.push("");
const out = newBody + lines.join("\n") + refsSec.split("## Figure legends")[1].replace(/^/, "## Figure legends");

fs.writeFileSync(P, out, "utf8");

// PMID sequence for gen_refs
const PMIDS = ["27352125","33009098","34125858","39979809","41444865","41879150","39027814",
  "36596836","31831740","26903338",null,"8844239","18064739","22435856","37632500","29174750",
  "37314271","32270297","40828463","25432556","36688507","35709019","2265630","25247784"];
const newOrder = order.map(o => PMIDS[o - 1]);
console.log("new PMID order:", JSON.stringify(newOrder));
fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/_new_ref_order.json", JSON.stringify(newOrder));

// verify ascending appearance
const check = [...out.split("## References")[0].matchAll(/\[([\d,\s–\-]+)\]/g)]
  .flatMap(m => m[1].split(",").flatMap(p0 => {
    const p = p0.trim();
    if (/^\d+$/.test(p)) return [+p];
    const [a, b] = p.split(/[–-]/).map(Number);
    const r = []; for (let i = a; i <= b; i++) r.push(i); return r;
  }));
let asc = true, prev = 0; const seen = new Set();
for (const n of check) { if (!seen.has(n)) { if (n <= prev) asc = false; prev = n; seen.add(n); } }
console.log("ascending on first appearance:", asc, "| distinct cited:", seen.size);
