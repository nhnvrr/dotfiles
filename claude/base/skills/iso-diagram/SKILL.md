---
name: iso-diagram
description: Build isometric architecture/infra diagrams (Isoflow look, AWS/GCP/Azure/Kubernetes icons) with animation - data packets travelling along connections, step-by-step walkthroughs with captions, pulsing nodes, zoom/pan, optional free 3D rotation - and publish them as an Artifact or embed them in one. Use when the user asks for an isometric, 3D, animated or Isoflow-style diagram, an architecture/infra/request-flow diagram meant for an artifact or a page, or "un diagrama en un artifact". Do NOT use for explanations answered in the terminal - those stay as ASCII box-drawing per CLAUDE.md.
---

# iso-diagram

One JSON scene, two renderers, one compose script:

```
scene.json ──► compose.ts ──► page.html (or --snippet) ──► Artifact
                  │
                  ├─ validates the scene (ids, edges, steps, icons)
                  ├─ inlines iso-core.js + iso-svg.js | iso-three.js
                  └─ inlines only the icons the scene uses (~30-60 KB total)
```

Skill dir: `~/.claude/skills/iso-diagram` (alias below: `$ISO`).

## 1. Pick the renderer

| Use `svg` (default) | Use `three` |
| --- | --- |
| Static or lightly animated diagram | User asks for 3D, rotation, "que se pueda girar" |
| Up to ~25 nodes | Walkthrough with many steps and packets |
| Must be crisp when printed / screenshotted | Wants depth: plinths, real camera |
| No WebGL needed, ~40 KB | Loads three@0.170.0 from jsdelivr (allowed CDN) |

Both read the same scene, so switching is `--renderer three`.

## 2. Find icons

The icons come from `@isoflow/isopacks@0.0.10`, extracted into
`~/.cache/iso-diagram/isopacks-0.0.10/` by `bun $ISO/scripts/icons.ts` (run automatically by
compose on first use; verified against the npm sha512, the package code is never executed).

```bash
grep -i 'lambda\|queue' ~/.cache/iso-diagram/isopacks-0.0.10/catalog.tsv
```

Ids are used as-is (`aws-rds`, `k8s-pod`, `gcp-cloud-run`, `azure-...`, `server`). Details and the
common ones: `reference/icons.md`. Unknown ids are a warning and render as a plain block.

## 3. Write the scene

Full format: `reference/scene-schema.md`. Working examples: `examples/*.json`. Layout rules that
keep diagrams readable:

- Flow runs left→right along **+x** (screen right-down); parallel replicas stack along **+y**.
- Leave one empty tile between nodes; labels sit under each tile.
- Route edges so they never cross another node's tile (`xy`, `yx`, `straight`). Check by tracing
  tile coordinates, not by eye.
- `groups` (VPC, cluster, namespace) are rectangles `from` top-left tile `to` bottom-right tile.
- Tones are Mate Dark tokens only: `accent blue aqua green yellow gray`; `red` only for errors.
- Animation must explain something: packets on the request path, `steps` for a sequence. Not on
  every edge.

## 4. Compose and publish

```bash
bun $ISO/scripts/compose.ts scene.json --out <scratchpad>/diagram.html --lang es
bun $ISO/scripts/compose.ts scene.json --snippet --out <scratchpad>/part.html
```

Errors exit 1 with one line per problem; fix the scene, never the output HTML. Then:

- **Standalone diagram**: load `artifact-design` (and the Mate Dark artifacts skill), publish the
  composed page with `icon: "terminal"`. The page already carries the Mate Dark tokens, fonts,
  `<title>`, and phone-width layout.
- **Inside a bigger artifact** (explainer, dashboard): use `--snippet` and paste it where the
  diagram goes. Several snippets can live on one page; each mounts on its own id. The renderer
  injects its own scoped CSS and reads the page's `--accent`, `--surface`, ... tokens.

## 5. Check before handing over

Screenshot it headless (WebGL via SwiftShader works):

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --use-angle=swiftshader --enable-unsafe-swiftshader --hide-scrollbars \
  --window-size=1200,900 --virtual-time-budget=5000 \
  --user-data-dir=<scratchpad>/chrome --screenshot=<scratchpad>/d.png file://<scratchpad>/diagram.html
```

Read the PNG: no edge through a node, no label collisions, groups enclose what they should. To
check a later step, set `"startStep": N` in a copy of the scene.

## Gotchas

- `steps` are cumulative: `show` adds, `hide` removes; edges appear once both ends are visible.
  `active` (nodes or edge ids `from->to`) highlights only in that step and runs packets on it.
- Edges with `packets` animate when the current step has no `active`, or always with
  `"packets": {"always": true}`.
- Only `isoflow` icons are isometric drawings; cloud/k8s icons are flat and get laid on a plinth.
- `prefers-reduced-motion` disables packets, pulses and fades in both renderers.
- Mouse wheel scrolls the page; zoom is ctrl/cmd + wheel or the buttons. In 3D mode left-drag
  rotates, right-drag or shift-drag pans.
