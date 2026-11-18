#!/usr/bin/env bun
// scene.json -> self-contained HTML page (default) or embeddable snippet (--snippet).
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { ensureIcons, type Icon } from "./icons.ts";

const ROOT = join(dirname(import.meta.path), "..");
const read = (p: string) => readFileSync(join(ROOT, p), "utf8");

const ATTRIBUTION: Record<string, string> = {
  isoflow: "Isoflow",
  aws: "AWS Architecture Icons",
  gcp: "Google Cloud icons",
  azure: "Microsoft Azure icons",
  kubernetes: "Kubernetes icons (CC BY 4.0)",
};

function usage(msg?: string): never {
  if (msg) console.error(msg);
  console.error("usage: compose.ts <scene.json> [--out file.html] [--snippet] [--renderer svg|three] [--lang es|en]");
  process.exit(2);
}

function args(argv: string[]) {
  const o: { scene?: string; out?: string; snippet: boolean; renderer?: string; lang: string } = { snippet: false, lang: "es" };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--snippet") o.snippet = true;
    else if (a === "--out") o.out = argv[++i];
    else if (a === "--renderer") o.renderer = argv[++i];
    else if (a === "--lang") o.lang = argv[++i];
    else if (a.startsWith("--")) usage(`unknown flag ${a}`);
    else o.scene = a;
  }
  if (!o.scene) usage();
  return o;
}

const esc = (s: string) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);
const json = (v: unknown) => JSON.stringify(v).replace(/</g, "\\u003c");

export async function compose(sceneRaw: any, opt: { snippet?: boolean; renderer?: string; lang?: string } = {}) {
  const icons = await ensureIcons();
  // iso-core.js is DOM-free at load time, so it doubles as the validator here.
  (0, eval)(read("renderers/iso-core.js"));
  const core = (globalThis as any).IsoCore;
  const { errors, warnings } = core.validate(sceneRaw, icons);
  for (const w of warnings) console.error("warning: " + w);
  if (errors.length) {
    for (const e of errors) console.error("error: " + e);
    throw new Error(`${errors.length} scene error(s)`);
  }

  const renderer = opt.renderer || sceneRaw.renderer || "svg";
  if (!["svg", "three"].includes(renderer)) throw new Error(`renderer must be svg or three, got "${renderer}"`);

  const used: Record<string, Icon> = {};
  for (const n of sceneRaw.nodes || []) if (n.icon && icons[n.icon]) used[n.icon] = icons[n.icon];
  const cols = [...new Set(Object.values(used).map((i) => i.c))];
  const attribution = cols.length ? "Icons: " + cols.map((c) => ATTRIBUTION[c] || c).join(", ") : "";

  const id = "isod-" + Math.random().toString(36).slice(2, 8);
  const coreJs = read("renderers/iso-core.js");
  const call = `(document.getElementById(${json(id)}), JSON.parse(document.getElementById(${json(id + "-scene")}).textContent), JSON.parse(document.getElementById(${json(id + "-icons")}).textContent), ${json({ attribution })})`;
  let code: string;
  if (renderer === "svg") {
    code = `<script>\n${coreJs}\n</script>\n<script>\n${read("renderers/iso-svg.js")}\nIsoSVG.mount${call};\n</script>`;
  } else {
    const three = read("renderers/iso-three.js").replace(/^export function mount/m, "function mount");
    code = `<script>\n${coreJs}\n</script>\n<script type="module">\n${three}\nmount${call};\n</script>`;
  }
  const snippet = [
    `<div class="iso-diagram" id="${id}"></div>`,
    `<script type="application/json" id="${id}-scene">${json(sceneRaw)}</script>`,
    `<script type="application/json" id="${id}-icons">${json(used)}</script>`,
    code,
  ].join("\n");
  if (/<\/script/i.test(read(`renderers/iso-${renderer}.js`) + coreJs)) throw new Error("renderer source contains </script");

  if (opt.snippet) return { html: snippet, warnings, renderer };

  const title = sceneRaw.title || "Diagram";
  const page = read("templates/page.html")
    .replace("{{LANG}}", esc(opt.lang || "es"))
    .replace("{{TITLE}}", esc(sceneRaw.pageTitle || title))
    .replace("{{EYEBROW}}", esc(sceneRaw.eyebrow || (renderer === "three" ? "Diagram · 3D" : "Diagram")))
    .replace("{{HEADING}}", esc(title))
    .replace("{{LEDE}}", sceneRaw.description ? `<p class="lede">${esc(sceneRaw.description)}</p>` : "")
    .replace("{{DIAGRAM}}", () => snippet);
  return { html: page, warnings, renderer };
}

if (import.meta.main) {
  const o = args(process.argv.slice(2));
  let scene: any;
  try {
    scene = JSON.parse(readFileSync(o.scene!, "utf8"));
  } catch (e) {
    usage(`cannot read ${o.scene}: ${(e as Error).message}`);
  }
  try {
    const { html, renderer } = await compose(scene, o);
    if (o.out) {
      writeFileSync(o.out, html);
      console.error(`${o.out}  ${renderer}  ${(Buffer.byteLength(html) / 1024).toFixed(1)} KB`);
    } else process.stdout.write(html);
  } catch (e) {
    console.error((e as Error).message);
    process.exit(1);
  }
}
