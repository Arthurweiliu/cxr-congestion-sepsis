import fs from "node:fs";
const BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
const sleep = ms => new Promise(r => setTimeout(r, ms));
const get = async (u) => { for (let i=0;i<4;i++){ try{ const r=await fetch(u); if(r.ok) return await r.text(); }catch(e){} await sleep(1200*(i+1)); } throw new Error("fail"); };

const Q = {
  CXR_diuretic: '("chest radiograph"[tiab] OR "chest x-ray"[tiab] OR "chest radiography"[tiab]) AND (diuretic*[tiab] OR furosemide[tiab] OR bumetanide[tiab]) AND ("intensive care"[tiab] OR critically ill[tiab] OR sepsis[tiab] OR ICU[tiab])',
  CXR_therapeutic_impact: '("chest radiograph"[tiab] OR "chest x-ray"[tiab]) AND ("change in management"[tiab] OR "management change"[tiab] OR "therapeutic impact"[tiab] OR "clinical impact"[tiab]) AND ("intensive care"[tiab] OR ICU[tiab] OR critically ill[tiab])',
  fluid_overload_diuretic_decision: '("fluid overload"[tiab] OR "pulmonary edema"[tiab] OR "volume overload"[tiab]) AND (diuretic*[tiab]) AND ("decision"[tiab] OR initiation[tiab] OR trigger*[tiab] OR "clinical reasoning"[tiab])',
  discordant_information_ICU: '(discordan*[tiab] OR conflicting[tiab] OR disagreement[tiab]) AND ("clinical decision"[tiab] OR "decision making"[tiab] OR "information integration"[tiab]) AND ("intensive care"[tiab] OR ICU[tiab] OR critically ill[tiab])',
  deresuscitation_outcome: '(deresuscitat*[tiab] OR "de-resuscitation"[tiab] OR "fluid removal"[tiab] OR "diuretic strategy"[tiab]) AND (sepsis[tiab] OR "critically ill"[tiab]) AND (mortality[tiab] OR outcome*[tiab])',
  diuretic_timing_sepsis: '(diuretic*[tiab] OR furosemide[tiab]) AND (sepsis[tiab] OR "septic shock"[tiab]) AND (outcome*[tiab] OR mortality[tiab] OR "fluid balance"[tiab])'
};

const res = {};
for (const [k, term] of Object.entries(Q)) {
  const d = JSON.parse(await get(`${BASE}esearch.fcgi?db=pubmed&retmode=json&retmax=6&sort=relevance&term=${encodeURIComponent(term)}`));
  console.log(`\n=== ${k} (${d.esearchresult.count}) ===`);
  res[k] = { count: +d.esearchresult.count, ids: d.esearchresult.idlist };
  if (d.esearchresult.idlist.length) {
    const s = JSON.parse(await get(`${BASE}esummary.fcgi?db=pubmed&retmode=json&id=${d.esearchresult.idlist.join(",")}`));
    for (const id of d.esearchresult.idlist) {
      const x = s.result[id];
      if (x) console.log(`${id}\t${(x.pubdate||"").slice(0,4)}\t${x.source}\t${(x.title||"").slice(0,105)}`);
    }
  }
  await sleep(400);
}
fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/_novelty_A.json", JSON.stringify(res, null, 1));
