import fs from "node:fs";

const P = "F:/openclaw_workspace/CXR_congestion/manuscript/MANUSCRIPT_v1.md";
let md = fs.readFileSync(P, "utf8");
let bad = 0;
function rep(from, to, label) {
  if (!md.includes(from)) { console.error("MISSING: " + label); bad++; return; }
  md = md.replace(from, to);
}

// --- body citations ---
rep("and resuscitation therefore generates a positive fluid balance in most patients.",
    "and resuscitation therefore generates a positive fluid balance in most patients [17].", "JAMA review");

rep("and the venous excess ultrasound score [6].",
    "and the venous excess ultrasound score [6,18].", "VExUS");

rep("argues against pure cardiogenic oedema and in favour of a component related to inflammatory capillary leak. Two caveats follow",
    "argues against pure cardiogenic oedema and in favour of a component related to inflammatory capillary leak. Whether congestion identified on imaging should prompt active fluid removal is now addressed in guidance on the de-escalation phase [19,20], but no trial has selected patients by radiographic rather than ultrasound criteria. Two caveats follow",
    "de-escalation sentence");

// --- append new references ---
const NEW = `17. Zampieri FG, Bagshaw SM, Semler MW. Fluid therapy for critically ill adults with sepsis: a review. *JAMA* 2023;329:1967–1980. PMID 37314271.
18. Beaubien-Souligny W, Rola P, Haycock K, et al. Quantifying systemic congestion with point-of-care ultrasound: development of the venous excess ultrasound grading system. *Ultrasound J* 2020;12:16. PMID 32270297.
19. Ostermann M, Alshamsi F, Artigas Raventos A, et al. European Society of Intensive Care Medicine clinical practice guideline on fluid therapy in adult critically ill patients: Part 3 — fluid removal at de-escalation phase. *Intensive Care Med* 2025;51:1749–1763. PMID 40828463.
20. Malbrain ML, Marik PE, Witters I, et al. Fluid overload, de-resuscitation, and outcomes in critically ill or injured patients: a systematic review with suggestions for clinical practice. *Anaesthesiol Intensive Ther* 2014;46:361–380. PMID 25432556.
`;
const anchor = "16. Assaad S, Kratzert WB, Shelley B, Friedman MB, Perrino A Jr. Assessment of pulmonary edema: principles and practice. *J Cardiothorac Vasc Anesth* 2018;32:901–914. PMID 29174750.\n";
if (!md.includes(anchor)) { console.error("MISSING: anchor ref 16"); bad++; }
else md = md.replace(anchor, anchor + NEW);

if (bad) { console.error("aborted with " + bad + " missing anchors"); process.exit(1); }

fs.writeFileSync(P, md, "utf8");

// --- verify ---
const body = md.split("## References")[0];
const refsSec = md.split("## References")[1];
const total = (refsSec.match(/^\d+\.\s/gm) || []).length;
const cited = new Set();
for (const m of body.matchAll(/\[([\d,\s–\-]+)\]/g)) {
  for (const part of m[1].split(",")) {
    const p = part.trim();
    if (/^\d+$/.test(p)) cited.add(+p);
    else if (/^\d+[–-]\d+$/.test(p)) {
      const [a, b] = p.split(/[–-]/).map(Number);
      for (let i = a; i <= b; i++) cited.add(i);
    }
  }
}
const missing = [];
for (let i = 1; i <= total; i++) if (!cited.has(i)) missing.push(i);
console.log("references:", total, "| cited:", [...cited].sort((a,b)=>a-b).join(","));
console.log("uncited:", missing.join(",") || "none");
