---
name: feature-spec
description: Turn a feature idea into a bilingual (ES/EN) spec artifact with sections, ASCII and animated isometric flow diagrams, use cases and a ticket grid, then export the tickets as markdown files, Shortcut stories or another tracker. First step of the feature workflow (feature-spec → ticket-start → ticket-implement). Use when the user asks to "armar el artifact de la feature", "spec de la feature", "propuesta con tickets", "planear una feature con tickets", or runs /feature-spec. `/feature-spec tickets <slug>` re-runs only the ticket export.
---

# feature-spec

```
  feature-spec (top-down)

  explore repos ──► scope questions ──► ~/Documents/tickets/<slug>/
                                           ├─ feature.json      contract
                                           ├─ sections/*.html   ES/EN prose
                                           └─ flows/*.json      iso scenes
                                                 │
                                   compose.ts ───┘──► spec.html ──► Artifact
                                                                      │
                          ask: markdown | Shortcut | other MCP ◄──────┘
                                                 │
                          tracker ids back into feature.json, republish
```

Skill dir: `${CLAUDE_CONFIG_DIR:-~/.claude}/skills/feature-spec` (alias `$FS`).
Feature dir: `~/Documents/tickets/<slug>/` (alias `$FD`). It lives outside every repo and is
never committed. The full contract is in `reference/feature-json.md`; read it before writing.

## 1. Understand the feature

- Explore every repo the feature touches (Explore agents in parallel, one per repo). Collect
  what exists today, with `file:line`, real numbers and real payloads. A spec built on guesses
  is worse than none.
- One round of `AskUserQuestion` for the decisions that are genuinely the user's (scope, v1 vs
  later, behaviour choices). Fold everything into that round.

## 2. Write the feature dir

- `feature.json`: slug, title/lede/eyebrow as `{es, en}`, repos with absolute path and base
  branch, views, sections, flows, use cases, tickets. Ticket text is **English only**.
- `sections/<view>.html`: one fragment per view, built from the template's components
  (`.issues`, `.decisions`, `.tablewrap`, `.risk`, `.note`, `pre.diagram`, `.twocol`,
  `figure.shot` for screenshots or images). Every user-visible string goes in a pair:
  `<span lang="es">…</span><span lang="en">…</span>` (or `<div lang>` / `<p lang>` for blocks).
  Code, ids and numbers stay outside the pairs.
- ASCII diagrams in `pre.diagram` follow the CLAUDE.md stroke rules (solid for what works, `╌ ╎`
  for what is broken or missing, max ~78 columns, real values on the arrows). The labels inside
  are not translated; the caption above them is.
- `flows/<id>.json`: one iso-diagram scene per flow or use case worth animating. Follow the
  `iso-diagram` skill (layout, icons, `steps` with captions, `autoplay`). Any string in the scene
  may be `{es, en}`; compose renders each language separately. Place a flow inside a section
  with `<!-- flow:<id> -->`; unplaced flows go to an automatic "Flows" view.
- Images: put files in `$FD/assets/` and reference them with `figure.shot`; they are published
  as supporting files (step 3).

Typical views: Summary · Today · Proposal · Flows · Use cases · Decisions · Risks · Tickets.
Drop the ones with nothing real to say. Use cases and Tickets are generated from
`feature.json`; the tickets view can also carry a fragment with the dependency diagram.

Ticket rules:
- Title ~50 chars, first words identify the change (it becomes the branch name).
- `acceptance` is verifiable; `tests` names the tests that prove it; `use_cases` links back.
- `deps` only for real blockers. Release-later tickets get `"later": true`.

## 3. Compose and publish

```bash
bun $FS/scripts/compose.ts $FD --check      # validation only
bun $FS/scripts/compose.ts $FD              # writes $FD/spec.html
```

Errors exit 1, one per line: fix the inputs, never `spec.html`. Warnings about unpaired
`lang` blocks mean a string will not switch language: fix them too.

Load `artifact-design` and the Mate Dark artifacts skill, then publish `$FD/spec.html` with
`icon: "terminal"` (plus `files` for `assets/*`). Save the returned URL as `artifact_url` in
`feature.json`, compose again and republish to the same path, so the copied tickets carry the
link. Check it before handing over: screenshot `?lang=es` and `?lang=en` headless (iso-diagram
skill, step 5); headless Chrome has a 500 px minimum window, so check phone width through a
390 px iframe.

## 4. Ticket destination

Ask with `AskUserQuestion`, every time: **Markdown files** · **Shortcut** · **Other tracker**.
Details per destination: `reference/tickets.md`. Then compose and republish so ticket cards
link to the tracker.

## 5. Hand over

Artifact link, feature dir, the ticket list with where each one lives, and the next step:

```
/ticket-start <slug> <ID>        # one Rex session + worktree per ticket
```

Suggest starting with the tickets that have no `deps`.
