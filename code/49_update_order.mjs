import fs from "node:fs";
const P = "F:/openclaw_workspace/CXR_congestion/submission_JCM_20261023/_build/gen_refs.mjs";
let s = fs.readFileSync(P, "utf8");
const NEW = `const ORDER = ["37314271","36688507","35709019","27352125","33009098","25247784",
  "34125858","39979809","41444865","41879150","32270297","39027814","36596836","31831740",
  "26903338",null,"8844239","18064739","22435856","40828463","25432556","37632500",
  "29174750","2265630"];`;
s = s.replace(/const ORDER = \[[^\]]*\];/s, NEW);
fs.writeFileSync(P, s, "utf8");
console.log("gen_refs ORDER updated");
