#!/usr/bin/env bun
// Extracts the @isoflow/isopacks icons into a local cache without executing the package's code.
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const VERSION = "0.0.10";
const TARBALL = `https://registry.npmjs.org/@isoflow/isopacks/-/isopacks-${VERSION}.tgz`;
const INTEGRITY = "sha512-pR5vj2A83mPBCxgswD+tE8+/ftXmesv5Qy6sgNAuYxiyDw7Dng1zA1QnRKgxdvgsGH9qTDwak+53KzJuHeVTNg==";
const COLLECTIONS = ["isoflow", "aws", "gcp", "azure", "kubernetes"];
export const CACHE = join(process.env.XDG_CACHE_HOME || join(homedir(), ".cache"), "iso-diagram", `isopacks-${VERSION}`);
export const ICONS_JSON = join(CACHE, "icons.json");
export const CATALOG = join(CACHE, "catalog.tsv");

export type Icon = { c: string; url: string; iso: boolean; w: number; h: number };

const ENTRY = /\{id:"([^"]+)",name:"[^"]*",url:"(data:image\/svg\+xml;base64,[A-Za-z0-9+/=]+)",isIsometric:!([01])\}/g;

function size(svg: string): [number, number] {
  const head = svg.slice(0, 2000);
  const vb = head.match(/viewBox\s*=\s*["']\s*[-\d.]+[\s,]+[-\d.]+[\s,]+([\d.]+)[\s,]+([\d.]+)/i);
  if (vb) return [parseFloat(vb[1]), parseFloat(vb[2])];
  const w = head.match(/<svg[^>]*\swidth\s*=\s*["']([\d.]+)/i);
  const h = head.match(/<svg[^>]*\sheight\s*=\s*["']([\d.]+)/i);
  if (w && h) return [parseFloat(w[1]), parseFloat(h[1])];
  return [1, 1];
}

export async function ensureIcons(force = false): Promise<Record<string, Icon>> {
  if (!force && existsSync(ICONS_JSON)) return JSON.parse(readFileSync(ICONS_JSON, "utf8"));

  const dl = join(CACHE, "download");
  rmSync(dl, { recursive: true, force: true });
  mkdirSync(dl, { recursive: true });
  const res = await fetch(TARBALL);
  if (!res.ok) throw new Error(`download failed: ${res.status} ${TARBALL}`);
  const buf = Buffer.from(await res.arrayBuffer());
  const got = "sha512-" + createHash("sha512").update(buf).digest("base64");
  if (got !== INTEGRITY) throw new Error(`integrity mismatch for ${TARBALL}`);
  const tgz = join(dl, "pkg.tgz");
  writeFileSync(tgz, buf);
  const tar = Bun.spawnSync(["tar", "xzf", tgz, "-C", dl]);
  if (tar.exitCode !== 0) throw new Error("tar failed: " + tar.stderr.toString());

  const icons: Record<string, Icon> = {};
  const rows: string[] = ["id\tcollection\tkind"];
  for (const c of COLLECTIONS) {
    const src = readFileSync(join(dl, "package", "dist", `${c}.js`), "utf8");
    let n = 0;
    for (const m of src.matchAll(ENTRY)) {
      const [, id, url, iso] = m;
      if (id.startsWith("_")) continue;
      const svg = Buffer.from(url.slice(url.indexOf(",") + 1), "base64").toString("utf8");
      const [w, h] = size(svg);
      icons[id] = { c, url, iso: iso === "0", w, h };
      rows.push(`${id}\t${c}\t${iso === "0" ? "iso" : "flat"}`);
      n++;
    }
    console.error(`  ${c.padEnd(11)} ${n} icons`);
  }
  writeFileSync(ICONS_JSON, JSON.stringify(icons));
  writeFileSync(CATALOG, rows.join("\n") + "\n");
  rmSync(dl, { recursive: true, force: true });
  console.error(`cache: ${CACHE}`);
  return icons;
}

if (import.meta.main) {
  const icons = await ensureIcons(process.argv.includes("--force"));
  console.error(`${Object.keys(icons).length} icons, catalog: ${CATALOG}`);
}
