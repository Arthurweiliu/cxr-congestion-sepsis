import fs from "node:fs";
const BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
const sleep = ms => new Promise(r => setTimeout(r, ms));
const get = async (u) => { for (let i=0;i<4;i++){ try{ const r=await fetch(u); if(r.ok) return await r.text(); }catch(e){} await sleep(1200*(i+1)); } throw new Error("fail "+u); };

const Q = {
  A_narrow: '(pulmonary edema[tiab] OR pulmonary oedema[tiab]) AND sepsis[tiab] AND (radiograph*[tiab] OR chest x-ray[tiab]) AND (mortality[tiab] OR prognosis[tiab])',
  B_synonyms: '(pulmonary edema[tiab] OR pulmonary oedema[tiab] OR congestion[tiab] OR "vascular engorgement"[tiab] OR "interstitial edema"[tiab] OR "fluid overload"[tiab] OR "volume overload"[tiab]) AND (sepsis[tiab] OR septic[tiab]) AND (radiograph*[tiab] OR "chest x-ray"[tiab] OR "chest xray"[tiab] OR CXR[tiab] OR "chest film"[tiab])',
  C_syn_plus_outcome: '(pulmonary edema[tiab] OR pulmonary oedema[tiab] OR congestion[tiab] OR "vascular engorgement"[tiab] OR "interstitial edema"[tiab] OR "fluid overload"[tiab] OR "volume overload"[tiab]) AND (sepsis[tiab] OR septic[tiab]) AND (radiograph*[tiab] OR "chest x-ray"[tiab] OR "chest xray"[tiab] OR CXR[tiab] OR "chest film"[tiab]) AND (mortality[tiab] OR death[tiab] OR outcome*[tiab] OR prognosis[tiab] OR survival[tiab])',
  D_mesh: '("Radiography, Thoracic"[MeSH] OR "Radiography"[MeSH]) AND ("Sepsis"[MeSH] OR "Shock, Septic"[MeSH])',
  E_cxr_sepsis: '("chest radiograph"[tiab] OR "chest radiography"[tiab] OR "chest x-ray"[tiab] OR CXR[tiab]) AND (sepsis[tiab] OR septic[tiab])',
  F_mesh_edema: '"Pulmonary Edema"[MeSH] AND "Sepsis"[MeSH]',
  G_congestion_outcome: '(radiographic congestion[tiab] OR pulmonary congestion[tiab] OR "vascular congestion"[tiab]) AND (sepsis[tiab] OR septic[tiab] OR critically ill[tiab]) AND (mortality[tiab] OR outcome*[tiab] OR prognosis[tiab])'
};

const res = {};
for (const [k, term] of Object.entries(Q)) {
  const u = `${BASE}esearch.fcgi?db=pubmed&retmode=json&retmax=500&sort=pub+date&term=${encodeURIComponent(term)}`;
  const d = JSON.parse(await get(u));
  res[k] = { count: +d.esearchresult.count, ids: d.esearchresult.idlist };
  console.log(`${k.padEnd(22)} count=${d.esearchresult.count} fetched=${d.esearchresult.idlist.length}`);
  await sleep(400);
}

const A = new Set(res.A_narrow.ids);
const C = new Set(res.C_syn_plus_outcome.ids);
const D = new Set(res.D_mesh.ids);
const E = new Set(res.E_cxr_sepsis.ids);
const F = new Set(res.F_mesh_edema.ids);
console.log("\nA ∩ C =", [...A].filter(x => C.has(x)).length);
console.log("C \\ A =", [...C].filter(x => !A.has(x)).length);
console.log("D \\ A =", [...D].filter(x => !A.has(x)).length);
console.log("F \\ A =", [...F].filter(x => !A.has(x)).length);

// sample of C-not-A titles for eyeballing
const sample = [...C].filter(x => !A.has(x)).slice(0, 25);
const d = JSON.parse(await get(`${BASE}esummary.fcgi?db=pubmed&retmode=json&id=${sample.join(",")}`));
console.log("\n--- C \\ A sample titles ---");
for (const id of sample) {
  const x = d.result[id];
  if (!x) continue;
  console.log(`${id}\t${(x.pubdate||"").slice(0,4)}\t${x.source}\t${(x.title||"").slice(0,110)}`);
}

fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/_search_sensitivity.json", JSON.stringify(res, null, 1));
