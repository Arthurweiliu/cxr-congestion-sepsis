const BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/";
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

const Q = [
  ["R12 Sepsis-3", 'The Third International Consensus Definitions for Sepsis and Septic Shock (Sepsis-3)[ti]'],
  ["R13 MIMIC-IV", 'MIMIC-IV, a freely accessible electronic health record dataset[ti]'],
  ["R14 MIMIC-CXR", 'MIMIC-CXR, a de-identified publicly available database of chest radiographs with free-text reports[ti]'],
  ["R16 SOFA 1996", 'The SOFA (Sepsis-related Organ Failure Assessment) score[ti]'],
  ["R17 STROBE", 'Strengthening the Reporting of Observational Studies in Epidemiology (STROBE)[ti]'],
  ["R18 Pencina NRI", 'Extensions of net reclassification improvement calculations to measure usefulness of new biomarkers[ti]'],
  ["R15 CheXpert", 'CheXpert[ti]']
];

const get = async (u) => { for (let i = 0; i < 3; i++) { try { const r = await fetch(u); if (r.ok) return await r.text(); } catch (e) {} await sleep(1500); } throw new Error("fail"); };

for (const [label, term] of Q) {
  const u = `${BASE}esearch.fcgi?db=pubmed&retmode=json&retmax=3&term=${encodeURIComponent(term)}`;
  const d = JSON.parse(await get(u));
  const ids = d.esearchresult.idlist;
  console.log(`\n### ${label}  (hits=${d.esearchresult.count})`);
  if (!ids.length) { console.log("   NO HIT"); await sleep(400); continue; }
  const s = JSON.parse(await get(`${BASE}esummary.fcgi?db=pubmed&retmode=json&id=${ids.join(",")}`));
  for (const id of ids) {
    const x = s.result[id];
    if (!x) continue;
    const au = (x.authors || []).map(a => a.name).slice(0, 4).join(", ");
    console.log(`   PMID ${id} | ${x.source} ${x.pubdate} ;${x.volume}(${x.issue}):${x.pages} | ${au} | ${x.title}`);
  }
  await sleep(400);
}
