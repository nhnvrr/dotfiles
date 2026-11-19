# feature.json

The handoff contract between `feature-spec`, `ticket-start` and `ticket-implement`. Lives at
`~/Documents/tickets/<slug>/feature.json`. Paths inside it are relative to that dir. Working
example: `fixtures/sample/`.

```jsonc
{
  "slug": "order-receipts",                       // kebab-case, also the dir name
  "title": { "es": "…", "en": "…" },              // {es, en} wherever text is shown
  "eyebrow": { "es": "Propuesta · api", "en": "Proposal · api" },
  "lede": { "es": "…", "en": "…" },               // may contain inline HTML (<code>)
  "date": "2026-11-19",
  "lang": "es",                                   // default language of the page
  "artifact_url": "https://claude.ai/…",          // filled after the first publish
  "repos": {
    "api": { "path": "/Users/me/Work/api", "base": "main" }
  },
  "views": [{ "id": "summary", "nav": { "es": "Resumen", "en": "Summary" } }],
  "sections": [{ "view": "summary", "file": "sections/summary.html" }],
  "flows": [{ "id": "receipt", "title": { "es": "…", "en": "…" }, "lede": {…}, "scene": "flows/receipt.json" }],
  "pills": [{ "es": "base: main", "en": "base: main" }],
  "use_cases": [{
    "id": "UC1",
    "title": {…}, "context": {…},                 // context optional
    "given": {…}, "when": {…}, "then": {…},
    "example": { "input": "{ … }", "output": "…" },// optional, shown as code
    "tickets": ["A1"]
  }],
  "tickets": [{
    "id": "A1",                                   // short, stable: <repo letter><n>
    "repo": "api",                                // key of "repos"
    "type": "feature",                            // feature | bug | chore | spike
    "est": "2 pts",                               // optional
    "title": "Publish OrderPaid after payment capture",
    "summary": "One line under the title.",
    "description": ["…"],
    "acceptance": ["…"],                          // required, verifiable
    "tests": ["…"],
    "use_cases": ["UC1"],
    "deps": [],
    "later": false,                               // true = not in this release
    "tracker": { "kind": "markdown|shortcut|linear|…", "id": "sc-123", "url": "…",
                 "branch": "feature/sc-123-…", "file": "/abs/path/A1-….md" }
  }]
}
```

Rules enforced by `compose.ts`: unique ticket and use-case ids, every `deps`, `use_cases` and
`tickets` reference resolves, no dependency cycles, every ticket repo is in `repos`, every
section's view exists, every `{es, en}` field has both languages.

`tracker.branch` is what `ticket-start` checks out. Empty means `<type>/<id>-<title-slug>`.
