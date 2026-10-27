import fs from "node:fs";
const IDS = ["27352125","33009098","34125858","39979809","41444865","41879150","39027814",
  "36596836","31831740","26903338","8844239","18064739","22435856","37632500","29174750",
  "37314271","32270297","40828463","25432556","36688507","35709019","2265630","25247784"];

const get = async (u) => { const r = await fetch(u); if (!r.ok) throw new Error(r.status); return await r.text(); };
const txt = await get(`https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=text&rettype=abstract&id=${IDS.join(",")}`);
const blocks = txt.split(/\n\s*\n\s*\n/).filter(b => /PMID:/.test(b));

const out = [];
for (const b of blocks) {
  const pmid = (b.match(/PMID:\s*(\d+)/) || [])[1];
  const flat = b.replace(/\s+/g, " ").trim();
  // title = text after the journal line, before the first author parenthesis; fallback: first 120 chars
  const concl = (flat.match(/(CONCLUSIONS?|INTERPRETATION|RESULTS)[^]*?(?=PMID|$)/i) || [""])[0];
  const head = flat.slice(0, 160);
  out.push({ pmid, head, tail: flat.slice(-460) });
}
out.sort((a, b) => IDS.indexOf(a.pmid) - IDS.indexOf(b.pmid));
for (const o of out) {
  console.log(`\n### PMID ${o.pmid}`);
  console.log("HEAD: " + o.head);
  console.log("TAIL: " + o.tail);
}
fs.writeFileSync("F:/openclaw_workspace/CXR_congestion/_refs_abstracts.txt", out.map(o => `### ${o.pmid}\n${o.head}\n...\n${o.tail}`).join("\n\n"), "utf8");
