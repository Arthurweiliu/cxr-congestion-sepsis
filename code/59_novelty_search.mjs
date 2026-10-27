import fs from "node:fs";
const BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
const sleep = ms => new Promise(r => setTimeout(r, ms));
const get = async (u) => { for (let i=0;i<4;i++){ try{ const r=await fetch(u); if(r.ok) return await r.text(); }catch(e){} await sleep(1200*(i+1)); } throw new Error("fail"); };

const Q = {
  serial_CXR_fluid: '("chest radiograph"[tiab] OR "chest radiography"[tiab] OR "chest x-ray"[tiab] OR CXR[tiab]) AND ("fluid balance"[tiab] OR "fluid overload"[tiab] OR "cumulative fluid"[tiab]) AND (serial[tiab] OR daily[tiab] OR repeated[tiab] OR longitudinal[tiab] OR trajectory[tiab])',
  CXR_fluid_any: '("chest radiograph"[tiab] OR "chest radiography"[tiab] OR "chest x-ray"[tiab] OR CXR[tiab]) AND ("fluid balance"[tiab] OR "fluid overload"[tiab]) AND (critically ill[tiab] OR ICU[tiab] OR "intensive care"[tiab] OR sepsis[tiab])',
  daily_CXR_ICU: '(daily[tiab] OR routine[tiab] OR serial[tiab]) AND ("chest radiograph"[tiab] OR "chest x-ray"[tiab]) AND ("intensive care"[tiab] OR ICU[tiab] OR critically ill[tiab])',
  LUS_fluid_daily: '("lung ultrasound"[tiab] OR "B-lines"[tiab] OR "lung water"[tiab]) AND ("fluid balance"[tiab] OR "fluid overload"[tiab] OR "cumulative fluid"[tiab]) AND (daily[tiab] OR serial[tiab] OR longitudinal[tiab] OR trajectory[tiab] OR repeated[tiab])',
  MIMIC_CXR_fluid: '(MIMIC[tiab]) AND ("chest radiograph"[tiab] OR "chest x-ray"[tiab] OR CXR[tiab]) AND ("fluid"[tiab] OR congestion[tiab])',
  radiographic_congestion_ICU: '(radiographic congestion[tiab] OR pulmonary congestion[tiab] OR "vascular congestion"[tiab] OR "pulmonary edema"[tiab]) AND ("intensive care"[tiab] OR critically ill[tiab] OR sepsis[tiab]) AND (trajectory[tiab] OR change[tiab] OR "serial"[tiab])'
};

const res = {};
for (const [k, term] of Object.entries(Q)) {
  const d = JSON.parse(await get(`${BASE}esearch.fcgi?db=pubmed&retmode=json&retmax=6&sort=relevance&term=${encodeURIComponent(term)}`));
  res[k] = { count: +d.esearchresult.count, ids: d.esearchresult.idlist };
  console.log(`\n=== ${k} (${d.esearchresult.count}) ===`);
  if (d.esearchresult.idlist.length) {
    const s = JSON.parse(await get(`${BASE}esummary.fcgi?db=pubmed&retmode=json&id=${d.esearchresult.idlist.join(",")}`));
    for (const id of d.esearchresult.idlist) {
      const x = s.result[id];
      if (x) console.log(`${id}\t${(x.pubdate||"").slice(0,4)}\t${x.source}\t${(x.title||"").slice(0,110)}`);
    }
  }
  await sleep(400);
}
fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/_novelty_search.json", JSON.stringify(res, null, 1));
