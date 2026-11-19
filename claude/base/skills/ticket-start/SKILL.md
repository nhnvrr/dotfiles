---
name: ticket-start
description: Open a ticket from a feature spec in its own Rex session and git worktree, named after the ticket, with a fresh Claude Code started in plan mode on /ticket-implement. Second step of the feature workflow (feature-spec → ticket-start → ticket-implement). Use when the user says "arrancá el ticket X", "empezá A1", "abrí una sesión para el ticket", "start ticket", or runs /ticket-start <slug> <ID>.
---

# ticket-start

```
  ticket-start (left to right)

  feature.json ──► repo + branch ──► rex-wt new --plan ──► Rex session <name>
                                                             ├─ claude (plan mode)
                                                             │   /ticket-implement
                                                             └─ shell (below)
```

Arguments: `<slug> <ID> [<ID>…]`. Without a slug, list `~/Documents/tickets/*/feature.json`
and ask. Without an ID, show the tickets that are not started and whose `deps` are done, and
ask.

## Steps

1. Read `~/Documents/tickets/<slug>/feature.json`. For the ticket take `repo` →
   `repos[repo].path` and `.base`, and `tracker`.
2. Warn (do not block) when a `deps` ticket has no merged branch yet: the new branch starts
   from `base` and will not contain that work. Offer `--from <dep branch>` instead.
3. Names:
   - branch: `tracker.branch` (Shortcut's `suggested_branch_name`) or
     `<type>/<id>-<title-slug>` with the id lowercased.
   - session and worktree: `<tracker id or ID>-<first 4 words of the title>`, e.g.
     `sc-10945-render-receipt-pdf-and` or `w1-render-receipt-pdf-and`.
4. From the repo path:

   ```bash
   cd <repo path> && rex-wt new <branch> --name <name> --from <base> --plan \
     --prompt "/ticket-implement <slug> <ID>"
   ```

   `rex-wt` lives in `~/.local/bin` (source: the `rex` skill's `scripts/`). It creates
   `<repo>/.claude/worktrees/<name>` (or delegates to `scripts/spexs-tree` when the repo has
   one, which takes minutes), opens the Rex session with Claude in plan mode and a shell
   below, and passes the workspace's `CLAUDE_CONFIG_DIR` (Rex does not run the shell hooks).
   Run it with `run_in_background: true` when the repo uses `spexs-tree`.
5. Write `tracker.branch` and `tracker.session` back into `feature.json`. For markdown
   tickets set the file's `Status:` line to `in progress`. Never move a Shortcut story.
6. Report session id, name, worktree path and the two block ids. If the new Claude shows the
   folder-trust dialog (`rex capture` shows it, or its state is `blocked`), tell the user;
   accept it with `rex send-key` only if they say so.

Several IDs: one `rex-wt` call each, independent tickets in parallel. `rex new` never takes
focus, so the user picks the session from Rex.

Do not start implementing anything here. The new session owns the ticket from now on.
