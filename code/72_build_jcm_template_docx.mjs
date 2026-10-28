// build_jcm_template_docx.mjs — 用 JCM 官方模板（jcm-template.dot）重建主稿
// 做法：保留模板全部部件（styles/numbering/headers/footers/theme），只替换 word/document.xml
import fs from "node:fs";
import path from "node:path";

const ROOT = "F:/openclaw_workspace/CXR_congestion";
const STAGE = path.join(ROOT, "template_stage");
const MD = path.join(ROOT, "submission_JCM_20261025/manuscript/JCM_Manuscript.md");
const OUT = path.join(ROOT, "submission_JCM_20261025/manuscript/JCM_Manuscript_template_v2.docx");
const FIGDIR = path.join(ROOT, "submission_JCM_20261025/figures");

const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
const rPr = o => {
  let s = '<w:rPr><w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>';
  if (o.b) s += "<w:b/>";
  if (o.i) s += "<w:i/>";
  if (o.sup) s += '<w:vertAlign w:val="superscript"/>';
  if (o.sz) s += `<w:sz w:val="${o.sz}"/><w:szCs w:val="${o.sz}"/>`;
  return s + "</w:rPr>";
};
const runs = (text, base = {}) => {
  let out = "";
  for (const p of String(text).split(/(\*\*[^*]+\*\*|\*[^*]+\*)/)) {
    if (!p) continue;
    let b = !!base.b, i = !!base.i, t = p;
    let m;
    if ((m = p.match(/^\*\*([\s\S]+)\*\*$/))) { b = true; t = m[1]; }
    else if ((m = p.match(/^\*([^*]+)\*$/))) { i = true; t = m[1]; }
    out += `<w:r>${rPr({ ...base, b, i })}<w:t xml:space="preserve">${esc(t)}</w:t></w:r>`;
  }
  return out;
};
const para = (style, text, o = {}) =>
  `<w:p><w:pPr><w:pStyle w:val="${style}"/>${o.noNum ? '<w:numPr><w:numId w:val="0"/></w:numPr>' : ""}${o.keepNext ? "<w:keepNext/>" : ""}${o.indent !== undefined ? `<w:ind w:left="${o.indent}" w:firstLine="0"/>` : ""}${o.align ? `<w:jc w:val="${o.align}"/>` : ""}</w:pPr>${runs(text, o)}</w:p>`;
const emptyPara = style => `<w:p><w:pPr><w:pStyle w:val="${style}"/></w:pPr></w:p>`;

// ---------- 读稿 ----------
const md = fs.readFileSync(MD, "utf8").replace(/^\uFEFF/, "").replace(/\r/g, "");
const lines = md.split("\n");
const title = lines.find(l => l.startsWith("# ")).slice(2).trim().replace(/^\uFEFF/, "");

// 作者块：标题后第一个非空、以 "Wei Liu" 开头的行 + 后续单位行
const titleIdx = lines.findIndex(l => l.startsWith("# "));
let i = titleIdx + 1;
while (i < lines.length && lines[i].trim() === "") i++;
const authors = lines[i].trim();
const affs = [];
i++;
while (i < lines.length && !/^---/.test(lines[i])) {
  if (lines[i].trim()) affs.push(lines[i].trim());
  i++;
}
// 摘要
const absStart = lines.findIndex(l => l.startsWith("**Background.**"));
const kwIdx = lines.findIndex(l => l.startsWith("**Keywords:**"));
const absParas = [];
for (let k = absStart; k < kwIdx; k++) if (lines[k].trim()) absParas.push(lines[k].trim());
const keywords = lines[kwIdx].replace(/^\*\*Keywords:\*\*\s*/, "").trim();

// 正文（从 ## 1. 到 ## References）
const refHead = lines.findIndex(l => l.trim() === "## References");
const figHead = lines.findIndex(l => l.trim() === "## Figure Legends");
const bodyStart = lines.findIndex(l => /^## 1\. /.test(l));
const declStart = lines.findIndex(l => l.trim() === "## Declarations");
const bodyLines = lines.slice(bodyStart, Math.min(refHead, declStart >= 0 ? declStart : refHead));
const refLines = lines.slice(refHead + 1, figHead);
const legendLines = lines.slice(figHead + 1);
const declLines = lines.slice(declStart + 1, refHead);

// ---------- 图 ----------
const figs = [
  { n: 1, file: "Fig1_flow.png" }, { n: 2, file: "Fig2_2x2.png" }, { n: 3, file: "Fig3_KM.png" },
  { n: 4, file: "Fig4_forest.png" }, { n: 5, file: "Fig5_v4.png" },
];
const pngSize = f => {
  const b = fs.readFileSync(f);
  return { w: b.readUInt32BE(16), h: b.readUInt32BE(20) };
};
const figXml = [];
const media = [];
figs.forEach((f, idx) => {
  const p = path.join(FIGDIR, f.file);
  const { w, h } = pngSize(p);
  const maxW = 5_700_000;                       // ≈15.8 cm
  const cx = maxW, cy = Math.round(maxW * h / w);
  const rid = `rId9${idx + 1}`;
  media.push({ rid, file: f.file, target: `media/fig${f.n}.png` });
  figXml[f.n] = `<w:p><w:pPr><w:pStyle w:val="MDPI52figure"/><w:jc w:val="center"/></w:pPr><w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0"><wp:extent cx="${cx}" cy="${cy}"/><wp:effectExtent l="0" t="0" r="0" b="0"/><wp:docPr id="${100 + f.n}" name="Figure ${f.n}"/><wp:cNvGraphicFramePr><a:graphicFrameLocks xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" noChangeAspect="1"/></wp:cNvGraphicFramePr><a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"><a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture"><pic:nvPicPr><pic:cNvPr id="${100 + f.n}" name="Figure ${f.n}"/><pic:cNvPicPr/></pic:nvPicPr><pic:blipFill><a:blip r:embed="${rid}"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill><pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="${cx}" cy="${cy}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>`;
});

// ---------- 表格 ----------
const table = rows => {
  const cols = rows[0].length;
  const total = 10466;
  const first = Math.round(total * 0.28);
  const rest = Math.round((total - first) / (cols - 1));
  const widths = [first, ...Array(cols - 1).fill(rest)];
  const border = s => `<w:${s} w:val="single" w:sz="12" w:space="0" w:color="000000"/>`;
  const cell = (text, w, header, align) => {
    const borders = header ? `<w:tcBorders><w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/></w:tcBorders>` : "";
    return `<w:tc><w:tcPr><w:tcW w:w="${w}" w:type="dxa"/>${borders}</w:tcPr><w:p><w:pPr><w:pStyle w:val="MDPI42tablebody"/><w:jc w:val="${align}"/></w:pPr>${runs(text, { sz: 18, b: header })}</w:p></w:tc>`;
  };
  const trs = rows.map((r, ri) => `<w:tr>${r.map((c, ci) => cell(c, widths[ci], ri === 0, ci === 0 ? "left" : "center")).join("")}</w:tr>`).join("");
  return `<w:tbl><w:tblPr><w:tblW w:w="${total}" w:type="dxa"/><w:jc w:val="center"/><w:tblBorders>${border("top")}${border("bottom")}<w:insideH w:val="nil"/><w:insideV w:val="nil"/><w:left w:val="nil"/><w:right w:val="nil"/></w:tblBorders><w:tblLayout w:type="fixed"/></w:tblPr><w:tblGrid>${widths.map(w => `<w:gridCol w:w="${w}"/>`).join("")}</w:tblGrid>${trs}</w:tbl>`;
};
const splitRow = l => l.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map(s => s.trim());

// ---------- 正文装配 ----------
const body = [];
body.push(para("MDPI11articletype", "Article"));
body.push(para("MDPI12title", title));

// 作者（上标）
const authorRuns = (() => {
  const parts = [];
  const re = /([A-Z][A-Za-z.\-'’]*(?:\s+[A-Z][A-Za-z.\-'’]*)*)\s+([0-9](?:[0-9]|,[0-9*]+)*)/g;
  let m;
  while ((m = re.exec(authors)) !== null) parts.push({ name: m[1].trim(), sup: m[2] });
  return parts.map((p, idx) => {
    let s = `<w:r>${rPr({})}<w:t xml:space="preserve">${esc(p.name)}</w:t></w:r>`;
    s += `<w:r>${rPr({ sup: true })}<w:t xml:space="preserve">${esc(p.sup)}</w:t></w:r>`;
    if (idx < parts.length - 2) s += `<w:r>${rPr({})}<w:t xml:space="preserve">, </w:t></w:r>`;
    else if (idx === parts.length - 2) s += `<w:r>${rPr({})}<w:t xml:space="preserve"> and </w:t></w:r>`;
    return s;
  }).join("");
})();
body.push(`<w:p><w:pPr><w:pStyle w:val="MDPI13authornames"/></w:pPr>${authorRuns}</w:p>`);

// 单位
affs.forEach(a0 => {
  const a = a0.replace(/^\\\*/, "*");
  const m = a.match(/^(\*|\d)\s*(.*)$/);
  if (m) body.push(`<w:p><w:pPr><w:pStyle w:val="MDPI16affiliation"/></w:pPr><w:r>${rPr({ sup: true })}<w:t xml:space="preserve">${esc(m[1])}</w:t></w:r><w:r>${rPr({})}<w:t xml:space="preserve">${esc(m[2])}</w:t></w:r></w:p>`);
  else body.push(para("MDPI16affiliation", a));
});

const metaTbl = fs.readFileSync(path.join(ROOT, "_tpl_meta_tbl.xml"), "utf8")
  .replace("Academic Editor: Firstname Lastname", "Academic Editor: to be assigned")
  .replace("Received: date", "Received: 27 October 2026")
  .replace("Revised: date", "Revised: —")
  .replace("Accepted: date", "Accepted: —")
  .replace("Published: date", "Published: —")
  .replace("© 2025", "© 2026");
body.push(metaTbl);
// 摘要
body.push(para("MDPI17abstract", "Abstract", { b: true }));
absParas.forEach(p => { if (!/^---+$/.test(p)) body.push(para("MDPI17abstract", p)); });
body.push(para("MDPI18keywords", `Keywords: ${keywords}`));

// 正文块
let pendingTable = null;
let tblCount = 0;
let capNext = false;
const cited = new Set();
for (let k = 0; k < bodyLines.length; k++) {
  const l = bodyLines[k];
  if (/^## /.test(l)) {
    const h = l.replace(/^##\s*/, "");
    const flush = /^(References|Declarations)$/i.test(h.trim());
    body.push(para("MDPI21heading1", h, flush ? { indent: 0 } : { indent: 2608 }));
    continue;
  }
  if (/^### /.test(l)) { body.push(para("MDPI22heading2", l.replace(/^###\s*/, ""), { noNum: true, indent: 2608 })); continue; }
  if (/^\|/.test(l)) {
    if (/^\|[\s:|-]+\|$/.test(l.trim())) continue;
    if (!pendingTable) pendingTable = [];
    pendingTable.push(splitRow(l));
    continue;
  }
  if (pendingTable) {
    body.push(table(pendingTable)); tblCount++; pendingTable = null;
  }
  if (!l.trim() || /^---+$/.test(l.trim())) continue;
  if (/^\*\*Table \d\./.test(l)) { body.push(para("MDPI41tablecaption", l)); continue; }
  if (/^\*\*Note\.\*\*/.test(l)) { body.push(para("MDPI43tablefooter", l)); continue; }
  body.push(para("MDPI31text", l.replace(/\s+$/, "")));
  // 首次引用图 → 插图 + 图注
  for (const f of figs) {
    if (!cited.has(f.n) && new RegExp(`Figure ${f.n}(?![0-9])`).test(l)) {
      cited.add(f.n);
      body.push(figXml[f.n]);
      const legend = legendLines.find(x => x.startsWith(`**Figure ${f.n}.`));
      if (legend) body.push(para("MDPI51figurecaption", legend));
    }
  }
}
if (pendingTable) { body.push(table(pendingTable)); tblCount++; }

// 未在正文引用的图，补在参考文献前
for (const f of figs) if (!cited.has(f.n)) {
  body.push(figXml[f.n]);
  const legend = legendLines.find(x => x.startsWith(`**Figure ${f.n}.`));
  if (legend) body.push(para("MDPI51figurecaption", legend));
}

// 参考文献
body.push(para("MDPI21heading1", "References", { indent: 0 }));
refLines.filter(l => /^\d+\.\s/.test(l.trim())).forEach(l => body.push(para("MDPI81references", l.trim(), { noNum: true })));

// 声明
if (declLines.length) {
  body.push(para("MDPI21heading1", "Declarations", { indent: 0 }));
  declLines.filter(l => l.trim() && !/^---+$/.test(l.trim())).forEach(l => body.push(para("MDPI62backmatter", l.trim(), { indent: 0 })));
}

// ---------- 包 ----------
// 每次构建从原始 .dot 重新解包，避免 rels/media 重复
import { execFileSync as execSync } from "node:child_process";
const PRISTINE = path.join(ROOT, "template_pristine");
if (fs.existsSync(STAGE)) fs.rmSync(STAGE, { recursive: true, force: true });
fs.cpSync(PRISTINE, STAGE, { recursive: true });

const docXml = fs.readFileSync(path.join(STAGE, "word/document.xml"), "utf8");
const sectPr = docXml.match(/<w:sectPr[\s\S]*?<\/w:sectPr>/)[0];
const head = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"><w:body>';
const xml = head + body.join("") + sectPr + "</w:body></w:document>";
fs.writeFileSync(path.join(STAGE, "word/document.xml"), xml, "utf8");

// rels + media
let rels = fs.readFileSync(path.join(STAGE, "word/_rels/document.xml.rels"), "utf8");
media.forEach(m => {
  fs.copyFileSync(path.join(FIGDIR, m.file), path.join(STAGE, "word", m.target));
  rels = rels.replace("</Relationships>", `<Relationship Id="${m.rid}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="${m.target}"/></Relationships>`);
});
fs.writeFileSync(path.join(STAGE, "word/_rels/document.xml.rels"), rels, "utf8");

// content types: template -> document
let ct = fs.readFileSync(path.join(STAGE, "[Content_Types].xml"), "utf8");
ct = ct.replace("wordprocessingml.template.main+xml", "wordprocessingml.document.main+xml");
fs.writeFileSync(path.join(STAGE, "[Content_Types].xml"), ct, "utf8");

// zip（正斜杠）
const { execFileSync } = await import("node:child_process");
if (fs.existsSync(OUT)) fs.unlinkSync(OUT);
execFileSync("powershell", ["-NoProfile", "-Command",
  `$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.IO.Compression; Add-Type -AssemblyName System.IO.Compression.FileSystem;
   $zip=[System.IO.Compression.ZipFile]::Open('${OUT.replace(/\//g, "\\")}','Create');
   Get-ChildItem -Path '${STAGE.replace(/\//g, "\\")}' -Recurse -File | ForEach-Object {
     $rel=$_.FullName.Substring('${STAGE.replace(/\//g, "\\")}'.Length+1).Replace('\\','/');
     [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,$_.FullName,$rel,[System.IO.Compression.CompressionLevel]::Optimal) | Out-Null };
   $zip.Dispose()`], { stdio: "inherit" });

console.log("written:", OUT);
console.log("tables:", tblCount, " figures:", cited.size, " refs:", refLines.filter(l => /^\d+\.\s/.test(l.trim())).length);
