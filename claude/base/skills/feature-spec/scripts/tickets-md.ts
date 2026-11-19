#!/usr/bin/env bun
// feature.json -> one markdown file per ticket next to it: <ID>-<title-slug>.md
//
//   bun tickets-md.ts <feature-dir|feature.json> [--force]
//
// Existing files are kept unless --force (they may hold edits). Prints one path per ticket.
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

const argv = process.argv.slice(2);
const force = argv.includes("--force");
const input = argv.find((a) => !a.startsWith("--"));
if (!input) { console.error("usage: tickets-md.ts <feature-dir|feature.json> [--force]"); process.exit(2); }
const file = input.endsWith(".json") ? resolve(input) : join(resolve(input), "feature.json");
const dir = dirname(file);
const F = JSON.parse(readFileSync(file, "utf8"));
const en = (v: any) => (v && typeof v === "object" && "en" in v ? v.en : v ?? "");
export const slugify = (s: string) => s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 48).replace(/-+$/, "");
const ucs = new Map<string, any>((F.use_cases || []).map((u: any) => [u.id, u]));
const list = (a?: string[], box = false) => (a || []).map((x) => `- ${box ? "[ ] " : ""}${x}`).join("\n");

for (const t of F.tickets || []) {
  const path = join(dir, `${t.id}-${slugify(t.title)}.md`);
  t.file = path;
  if (existsSync(path) && !force) { console.log(`${path}  (kept)`); continue; }
  const repo = F.repos?.[t.repo] || {};
  const uc = (t.use_cases || []).map((id: string) => {
    const u = ucs.get(id);
    if (!u) return `- ${id}`;
    const gwt = ["given", "when", "then"].filter((k) => u[k]).map((k) => `  - ${k[0].toUpperCase() + k.slice(1)} ${en(u[k])}`).join("\n");
    return `- **${id} · ${en(u.title)}**\n${gwt}`;
  }).join("\n");
  const md = [
    `# ${t.id} · ${t.title}`, "",
    `> **Feature:** ${en(F.title)} (\`${F.slug}\`)`,
    `> **Repo:** ${t.repo}${repo.path ? ` (\`${repo.path}\`, base \`${repo.base || "main"}\`)` : ""}`,
    `> **Type:** ${t.type}${t.est ? ` · **Estimate:** ${t.est}` : ""}${t.later ? " · **Release:** later" : ""}`,
    `> **Depends on:** ${(t.deps || []).join(", ") || "none"}`,
    `> **Status:** to do`,
    ...(F.artifact_url ? [`> **Spec:** ${F.artifact_url}#tickets`] : []),
    "",
    ...(t.summary ? ["## Context", "", t.summary, ""] : []),
    "## Description", "", list(t.description), "",
    ...(uc ? ["## Use cases", "", uc, ""] : []),
    ...((t.tests || []).length ? ["## Tests", "", list(t.tests), ""] : []),
    "## Acceptance criteria", "", list(t.acceptance, true), "",
  ].join("\n");
  writeFileSync(path, md);
  console.log(path);
}
// Record where each ticket lives so ticket-start / ticket-implement can find it.
for (const t of F.tickets || []) t.tracker = t.tracker?.kind && t.tracker.kind !== "markdown" ? t.tracker : { kind: "markdown", id: t.id, url: "", file: t.file, branch: t.tracker?.branch || "" };
for (const t of F.tickets || []) delete t.file;
writeFileSync(file, JSON.stringify(F, null, 2) + "\n");
