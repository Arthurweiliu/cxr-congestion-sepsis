import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
let bad = 0;
const rep = (a, b, l) => { if (!md.includes(a)) { console.error("MISSING: " + l); bad++; return; } md = md.replace(a, b); };

rep("and resuscitation therefore generates a positive fluid balance in most patients [17].",
    "and resuscitation therefore generates a positive fluid balance in most patients [17]; randomised comparisons of restrictive and liberal fluid strategies have not demonstrated a mortality benefit [21,22].",
    "fluid trials sentence");

rep("the radiology report is an imperfect measure of extravascular lung water [15,16];",
    "the radiology report is an imperfect measure of extravascular lung water [15,16], and interobserver agreement for pulmonary venous congestion on chest radiographs is limited [23];",
    "CXR reliability");

const NEW = `21. National Heart, Lung, and Blood Institute Prevention and Early Treatment of Acute Lung Injury Clinical Trials Network; Shapiro NI, Douglas IS, Brower RG, et al. Early restrictive or liberal fluid management for sepsis-induced hypotension. *N Engl J Med* 2023;388:499–510. PMID 36688507.
22. Meyhoff TS, Hjortrup PB, Wetterslev J, et al. Restriction of intravenous fluid in ICU patients with septic shock. *N Engl J Med* 2022;386:2459–2470. PMID 35709019.
23. Nørgaard H, Gjørup T, Brems-Dalgaard E, et al. Interobserver variation in the detection of pulmonary venous hypertension in chest radiographs. *Eur J Radiol* 1990;11:203–206. PMID 2265630.
`;
const anchor = "20. Malbrain ML, Marik PE, Witters I, et al. Fluid overload, de-resuscitation, and outcomes in critically ill or injured patients: a systematic review with suggestions for clinical practice. *Anaesthesiol Intensive Ther* 2014;46:361–380. PMID 25432556.\n";
if (!md.includes(anchor)) { console.error("MISSING anchor 20"); bad++; } else md = md.replace(anchor, anchor + NEW);

if (bad) process.exit(1);
fs.writeFileSync(P, md, "utf8");

const body = md.split("## References")[0];
const refs = md.split("## References")[1];
const total = (refs.match(/^\d+\.\s/gm) || []).length;
const cited = new Set();
for (const m of body.matchAll(/\[([\d,\s–\-]+)\]/g)) for (const p0 of m[1].split(",")) {
  const p = p0.trim();
  if (/^\d+$/.test(p)) cited.add(+p);
  else if (/^\d+[–-]\d+$/.test(p)) { const [a,b] = p.split(/[–-]/).map(Number); for (let i=a;i<=b;i++) cited.add(i); }
}
const missing = []; for (let i=1;i<=total;i++) if (!cited.has(i)) missing.push(i);
console.log("refs:", total, "| uncited:", missing.join(",") || "none");
