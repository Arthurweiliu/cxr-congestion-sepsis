import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
let bad = 0;
const rep = (a, b, l) => { if (!md.includes(a)) { console.error("MISSING: " + l); bad++; return; } md = md.replace(a, b); };

rep("Accumulated fluid is consistently associated with organ dysfunction and death [1,2],",
    "Accumulated fluid is consistently associated with organ dysfunction and death [1,2,24],",
    "fluid outcome refs");

const NEW = `24. Kelm DJ, Perrin JT, Cartin-Ceba R, Gajic O, Schenck L, Kennedy CC. Fluid overload in patients with severe sepsis and septic shock treated with early goal-directed therapy is associated with increased acute need for fluid-related medical interventions and hospital death. *Shock* 2015;43:68–73. PMID 25247784.
`;
const anchor = "23. Nørgaard H, Gjørup T, Brems-Dalgaard E, et al. Interobserver variation in the detection of pulmonary venous hypertension in chest radiographs. *Eur J Radiol* 1990;11:203–206. PMID 2265630.\n";
if (!md.includes(anchor)) { console.error("MISSING anchor 23"); bad++; } else md = md.replace(anchor, anchor + NEW);

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
