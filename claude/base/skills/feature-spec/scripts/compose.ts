#!/usr/bin/env bun
// feature.json + section fragments + flow scenes -> one bilingual (ES/EN) artifact page.
//
//   bun compose.ts <feature-dir|feature.json> [--out page.html] [--check]
//
// Exits 1 with one line per problem; --check validates without writing.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";

type Bi = { es: string; en: string };
const SKILL = join(dirname(import.meta.path), "..");
const BUILTIN: Record<string, Bi> = {
  flows: { es: "Flujos", en: "Flows" },
  "use-cases": { es: "Casos de uso", en: "Use cases" },
  tickets: { es: "Tickets", en: "Tickets" },
};

const errors: string[] = [];
const warnings: string[] = [];
const esc = (s: unknown) => String(s ?? "").replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c]!);
const json = (v: unknown) => JSON.stringify(v).replace(/</g, "\\u003c");
const isBi = (v: any): v is Bi => v && typeof v === "object" && typeof v.es === "string" && typeof v.en === "string" && Object.keys(v).length === 2;
const bi = (v: any, where: string, html = false) => {
  if (typeof v === "string") { warnings.push(`${where}: single-language text, shown in both languages`); v = { es: v, en: v }; }
  if (!isBi(v)) { errors.push(`${where}: needs {"es": "...", "en": "..."}`); return ""; }
  const f = html ? (s: string) => s : esc;
  return `<span lang="es">${f(v.es)}</span><span lang="en">${f(v.en)}</span>`;
};
// Picks one language out of any nested {es, en} pair (used for iso scenes).
const pick = (v: any, l: "es" | "en"): any =>
  isBi(v) ? v[l] : Array.isArray(v) ? v.map((x) => pick(x, l)) : v && typeof v === "object" ? Object.fromEntries(Object.entries(v).map(([k, x]) => [k, pick(x, l)])) : v;

function isoCompose(): string {
  const dirs = [process.env.CLAUDE_CONFIG_DIR && join(process.env.CLAUDE_CONFIG_DIR, "skills/iso-diagram"), join(homedir(), ".claude/skills/iso-diagram"), join(SKILL, "../iso-diagram")];
  for (const d of dirs) if (d && existsSync(join(d, "scripts/compose.ts"))) return join(d, "scripts/compose.ts");
  throw new Error("iso-diagram skill not found (needed for flows)");
}

async function main() {
  const argv = process.argv.slice(2);
  let input = "", out = "", check = false;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--out") out = argv[++i];
    else if (argv[i] === "--check") check = true;
    else if (argv[i].startsWith("--")) { console.error(`unknown flag ${argv[i]}`); process.exit(2); }
    else input = argv[i];
  }
  if (!input) { console.error("usage: compose.ts <feature-dir|feature.json> [--out page.html] [--check]"); process.exit(2); }
  const file = input.endsWith(".json") ? resolve(input) : join(resolve(input), "feature.json");
  const dir = dirname(file);
  const F = JSON.parse(readFileSync(file, "utf8"));
  const rel = (p: string) => resolve(dir, p);

  for (const k of ["slug", "title", "tickets"]) if (F[k] == null) errors.push(`feature.json: missing "${k}"`);
  if (F.slug && !/^[a-z0-9]+(-[a-z0-9]+)*$/.test(F.slug)) errors.push(`slug "${F.slug}" must be lowercase kebab-case`);

  // tickets and use cases: ids, cross references, repos
  const tickets: any[] = F.tickets || [];
  const ucs: any[] = F.use_cases || [];
  const tids = new Set<string>(), uids = new Set<string>();
  for (const t of tickets) {
    if (!t.id) { errors.push("ticket without id"); continue; }
    if (tids.has(t.id)) errors.push(`duplicate ticket id ${t.id}`);
    tids.add(t.id);
    for (const k of ["repo", "type", "title", "acceptance"]) if (t[k] == null || (Array.isArray(t[k]) && !t[k].length)) errors.push(`ticket ${t.id}: missing "${k}"`);
    if (t.repo && F.repos && !F.repos[t.repo]) errors.push(`ticket ${t.id}: repo "${t.repo}" is not in "repos"`);
    if (t.title && t.title.length > 60) warnings.push(`ticket ${t.id}: title over 60 chars, branch names get truncated`);
  }
  for (const u of ucs) {
    if (!u.id) { errors.push("use case without id"); continue; }
    if (uids.has(u.id)) errors.push(`duplicate use case id ${u.id}`);
    uids.add(u.id);
  }
  for (const t of tickets) {
    for (const d of t.deps || []) if (!tids.has(d)) errors.push(`ticket ${t.id}: depends on unknown ticket ${d}`);
    for (const u of t.use_cases || []) if (!uids.has(u)) errors.push(`ticket ${t.id}: unknown use case ${u}`);
  }
  for (const u of ucs) for (const t of u.tickets || []) if (!tids.has(t)) errors.push(`use case ${u.id}: unknown ticket ${t}`);
  // dependency cycles
  const byId = new Map(tickets.map((t) => [t.id, t]));
  const seen = new Map<string, number>();
  const visit = (id: string, path: string[]): void => {
    if (seen.get(id) === 2) return;
    if (seen.get(id) === 1) { errors.push(`dependency cycle: ${[...path, id].join(" -> ")}`); return; }
    seen.set(id, 1);
    for (const d of byId.get(id)?.deps || []) if (byId.has(d)) visit(d, [...path, id]);
    seen.set(id, 2);
  };
  for (const t of tickets) if (t.id) visit(t.id, []);

  // flows: each scene composed twice (es, en) and stacked in one grid cell
  const flowHtml = new Map<string, string>();
  const flows: any[] = F.flows || [];
  if (flows.length) {
    const { compose } = await import(isoCompose());
    for (const f of flows) {
      if (!f.id || !f.scene) { errors.push(`flow ${f.id ?? "?"}: needs "id" and "scene"`); continue; }
      const p = rel(f.scene);
      if (!existsSync(p)) { errors.push(`flow ${f.id}: scene ${f.scene} not found`); continue; }
      const scene = JSON.parse(readFileSync(p, "utf8"));
      const parts: string[] = [];
      for (const l of ["es", "en"] as const) {
        try {
          const { html } = await compose(pick(scene, l), { snippet: true, sceneDir: dirname(p), lang: l });
          parts.push(`<div lang="${l}">${html}</div>`);
        } catch (e) { errors.push(`flow ${f.id} (${l}): ${(e as Error).message}`); }
      }
      flowHtml.set(f.id, `<div class="flow" id="flow-${esc(f.id)}">${f.title ? `<h3>${bi(f.title, `flow ${f.id} title`)}</h3>` : ""}${f.lede ? `<p>${bi(f.lede, `flow ${f.id} lede`)}</p>` : ""}<div class="lpair">${parts.join("")}</div></div>`);
    }
  }

  // views and fragments
  const views: { id: string; nav: Bi; count?: number }[] = (F.views || []).map((v: any) => ({ id: v.id, nav: v.nav }));
  for (const v of views) if (!isBi(v.nav)) errors.push(`view ${v.id}: "nav" needs {es, en}`);
  const want = (id: string, on: boolean) => { if (on && !views.some((v) => v.id === id)) views.push({ id, nav: BUILTIN[id] }); };
  const placed = new Set<string>();
  const sections: string[] = [];
  for (const s of F.sections || []) {
    if (!views.some((v) => v.id === s.view)) errors.push(`section ${s.file}: view "${s.view}" is not in "views"`);
    const p = rel(s.file);
    if (!existsSync(p)) { errors.push(`section ${s.file} not found`); continue; }
    let html = readFileSync(p, "utf8");
    const nes = (html.match(/lang="es"/g) || []).length, nen = (html.match(/lang="en"/g) || []).length;
    if (nes !== nen) warnings.push(`section ${s.file}: ${nes} lang="es" vs ${nen} lang="en" blocks`);
    if (!nes) warnings.push(`section ${s.file}: no lang blocks, the text will not switch language`);
    html = html.replace(/<!--\s*flow:([\w-]+)\s*-->/g, (_, id) => {
      if (!flowHtml.has(id)) { errors.push(`section ${s.file}: unknown flow "${id}"`); return ""; }
      placed.add(id);
      return flowHtml.get(id)!;
    });
    sections.push(`<section data-view="${esc(s.view)}">\n${html}\n</section>`);
  }
  const loose = flows.filter((f) => flowHtml.has(f.id) && !placed.has(f.id));
  want("flows", loose.length > 0);
  want("use-cases", ucs.length > 0);
  want("tickets", true);
  const add = (view: string, html: string) => sections.push(`<section data-view="${view}">\n${html}\n</section>`);
  if (loose.length) add("flows", loose.map((f) => flowHtml.get(f.id)).join("\n"));

  if (ucs.length) {
    const chips = `<div class="chips">${ucs.map((u) => `<button type="button" data-uc="${esc(u.id)}">${esc(u.id)}</button>`).join("")}</div>`;
    const cards = ucs.map((u) => {
      const gwt = ["given", "when", "then"].filter((k) => u[k]).map((k) => `<dt>${bi({ given: { es: "Dado", en: "Given" }, when: { es: "Cuando", en: "When" }, then: { es: "Entonces", en: "Then" } }[k], k)}</dt><dd>${bi(u[k], `use case ${u.id} ${k}`)}</dd>`).join("");
      const ex = u.example ? `<div>${u.example.input ? `<span class="label">Input</span><pre class="json">${esc(u.example.input)}</pre>` : ""}${u.example.output ? `<span class="label">Output</span><pre class="json">${esc(u.example.output)}</pre>` : ""}</div>` : "";
      return `<article class="scn" id="uc-${esc(u.id)}"><header><span class="sid">${esc(u.id)}</span><h3>${bi(u.title, `use case ${u.id} title`)}</h3><span class="src">${(u.tickets || []).map((t: string) => `<a class="tag link" href="#t-${esc(t)}" data-jump="${esc(t)}">${esc(t)}</a>`).join("")}</span></header>${u.context ? `<p>${bi(u.context, `use case ${u.id} context`)}</p>` : ""}<div class="cols"><div><dl class="gwt">${gwt}</dl></div>${ex}</div></article>`;
    }).join("\n");
    add("use-cases", `<span class="label">${bi({ es: "Casos de uso", en: "Use cases" }, "")}</span>\n${chips}\n${cards}`);
  }
  add("tickets", `<span class="label">${bi({ es: "Tickets", en: "Tickets" }, "")}</span>\n<div class="filters" id="ticket-filters" role="group" aria-label="Filter"></div>\n<div class="tickets" id="ticket-list"></div>`);
  const tv = views.find((v) => v.id === "tickets");
  if (tv) tv.count = tickets.length;
  const uv = views.find((v) => v.id === "use-cases");
  if (uv) uv.count = ucs.length;
  for (const v of views) if (!sections.some((s) => s.startsWith(`<section data-view="${v.id}"`))) warnings.push(`view ${v.id} has no sections`);

  // hero
  const repos = [...new Set(tickets.map((t) => t.repo))];
  const pills = [`<span class="pill acc">${tickets.length} tickets</span>`, ...repos.map((r) => `<span class="pill">${tickets.filter((t) => t.repo === r).length} ${esc(r)}</span>`), ...(F.pills || []).map((p: any, i: number) => `<span class="pill">${bi(p, `pill ${i}`)}</span>`)];
  const hero = `<header class="hero" data-view="${esc(views[0]?.id)}">
  <span class="label">${F.eyebrow ? bi(F.eyebrow, "eyebrow") : ""}${F.date ? ` · ${esc(F.date)}` : ""}</span>
  <h1>${bi(F.title, "title")}</h1>
  ${F.lede ? `<p>${bi(F.lede, "lede", true)}</p>` : ""}
  <div class="meta">${pills.join("")}</div>
</header>`;

  if (warnings.length) for (const w of warnings) console.error("warning: " + w);
  if (errors.length) { for (const e of errors) console.error("error: " + e); process.exit(1); }
  if (check) { console.error(`ok: ${tickets.length} tickets, ${ucs.length} use cases, ${flows.length} flows, ${views.length} views`); return; }

  const data = { slug: F.slug, artifact_url: F.artifact_url || "", views, tickets: tickets.map(({ id, repo, type, est, title, summary, description, acceptance, tests, use_cases, deps, later, tracker }) => ({ id, repo, type, est, title, summary, description, acceptance, tests, use_cases, deps, later, tracker })) };
  const title = isBi(F.title) ? F.title.es : String(F.title);
  const page = readFileSync(join(SKILL, "templates/spec.html"), "utf8")
    .replaceAll("{{LANG}}", F.lang === "en" ? "en" : "es")
    .replace("{{TITLE}}", () => esc(F.page_title || title))
    .replace("{{BRAND}}", () => (isBi(F.title) ? bi(F.title, "title") : esc(title)))
    .replace("{{HERO}}", () => hero)
    .replace("{{SECTIONS}}", () => sections.join("\n\n"))
    .replace("{{FOOTER}}", () => (F.footer ? bi(F.footer, "footer") : `feature: ${esc(F.slug)}`))
    .replace("{{DATA}}", () => json(data));
  const dest = out || join(dir, "spec.html");
  writeFileSync(dest, page);
  console.error(`${dest}  ${(Buffer.byteLength(page) / 1024).toFixed(1)} KB  ${tickets.length} tickets · ${ucs.length} use cases · ${flows.length} flows`);
}

main().catch((e) => { console.error((e as Error).message); process.exit(1); });
