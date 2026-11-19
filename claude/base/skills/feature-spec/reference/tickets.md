# Ticket export

Asked after every publish, and on `/feature-spec tickets <slug>`. Whatever the destination,
`feature.json` ends up with a `tracker` on every ticket, then compose + republish.

## Markdown files

```bash
bun $FS/scripts/tickets-md.ts $FD          # existing files are kept; --force rewrites them
```

Writes `$FD/<ID>-<title-slug>.md` (header, context, description, use cases with
given/when/then, tests, acceptance checkboxes) and sets `tracker: {kind: "markdown", file}`.
These files are what `ticket-implement` reads and updates (`Status:` line).

## Shortcut

Only where the Shortcut MCP is configured (the `~/Work` workspace). If the
`mcp__shortcut__*` tools are missing or fail to connect, say so and offer markdown instead.

Follow the `shortcut-story` skill for fields, constants and the description template, with
these batch rules:

- Resolve user, active iteration and open epics once. Ask the epic **once** for the whole
  feature (offer "create a new epic named <title.en>" as an option), together with any other
  open question.
- Create stories in dependency order, so blockers exist first; pass
  `story_links: [{ subject_story_id: <blocker>, verb: "blocks" }]` for each dep.
- Description: Context = summary; Done when = acceptance; add `## Use cases` and `## Tests`
  sections; link the artifact as an external link.
- After each create, `stories-get-by-id` for `app_url` and `suggested_branch_name`; store them
  in `tracker` (`kind: "shortcut"`, `id: "sc-<n>"`).
- Never open a story in a started state.

## Other tracker (Linear, Jira, ClickUp, …)

Use its MCP only if it is connected and authenticated; otherwise report that it needs
authentication (the user runs the auth) and offer markdown meanwhile. Same batch rules: one
round of questions, create in dependency order, link deps, store id/url/branch in `tracker`.
