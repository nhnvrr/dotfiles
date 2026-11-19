---
name: ticket-implement
description: Implement one ticket of a feature spec inside its own Rex session - plan first (plan mode), then implement in auto mode with tests running in a Rex tab, then an exhaustive Codex review loop in another Rex tab, with the review written to ~/Documents/code-reviews/codex-review-<ticket>.md and Claude deciding what to apply. Third step of the feature workflow (feature-spec → ticket-start → ticket-implement); ticket-start launches it as "/ticket-implement <slug> <ID>". Also use when the user asks to implement a ticket from ~/Documents/tickets or a Shortcut story end to end with tests and Codex review.
---

# ticket-implement

```
  ticket-implement (top-down)

  1 plan       read ticket + spec + code ──► plan file ──► ExitPlanMode
                                                │ user approves, picks auto mode
  2 implement  edit code ──► ticket-run tests ──┤ until green
                                                ▼
  3 review     ticket-run codex-review ──► triage ──► fix ──► tests ──► reply
                       ▲                                               │
                       └──────────── ≤ 3 rounds, until clean ◄─────────┘
                                                ▼
  4 close      codex-review-<ticket>.md ──► PR title/body/commit ──► ask
```

Arguments: `<slug> <ID>`. Context lives in `~/Documents/tickets/<slug>/` (alias `$FD`):
`feature.json` (contract, see the `feature-spec` skill) and, for markdown tickets, the file
in `tickets[].tracker.file`.

Helpers (both on PATH via `~/.local/bin`):
- `ticket-run <label> [--for <dur>] [--no-wait] -- <cmd…>`: runs the command in tab `<label>`
  of this Rex session (cwd = `$PWD`), tees the output to a log under the git dir, replaces the
  tab it opened last time, prints `{window, block, exit, log}` and exits with the command's
  status. Read the **log file**, not the scrollback. Exit 124 = still running after `--for`.
  The tab does not inherit your environment: pass variables inside the command
  (`ticket-run codex-review -- env CODEX_REVIEW_EFFORT=high codex-review start …`).
- `codex-review`: the script of the `codex-review` skill.

## 1. Plan (the session starts in plan mode)

- Read the ticket: the markdown file, or the story through the tracker's MCP
  (`tracker.kind`). Read `feature.json` for repos, deps and use cases, and the artifact's
  matching sections with `Artifact read` on `artifact_url` when the ticket is not
  self-explanatory.
- Explore the code it touches. Find the repo's real commands for tests, typecheck and lint
  (package.json, Makefile, CI config, CLAUDE.md); never invent them.
- Write the plan through the `new-plan` skill (`<module>` from the code, not the ticket). It
  must contain: context with the ticket link; files to change; a table **use case → test
  case → file**, covering every acceptance criterion; the exact check commands; risks and
  anything out of scope.
- `ExitPlanMode`. The user approves and chooses auto mode in that dialog; Claude cannot switch
  modes itself. If the user asks for changes, update the plan (bump **Last updated**).

## 2. Implement

- Set the plan's status to `in implementation`. Follow the repo's CLAUDE.md and patterns.
- Write the tests from the plan's table first or alongside the code, not after.
- Run checks in the tests tab, narrowest first, full suite at the end:

  ```bash
  ticket-run tests -- pnpm vitest run src/receipts     # example; use the repo's commands
  ticket-run tests -- sh -c 'pnpm typecheck && pnpm lint'
  ```

  Long suites: `run_in_background: true` on the Bash call, then read the log.
- Never commit. Never run destructive git commands.

## 3. Review with Codex (loop)

Follow the `codex-review` skill for triage and replies; these are the differences:

```bash
RUN="$(git rev-parse --absolute-git-dir)/codex-review/<ID>-$(date +%Y%m%d-%H%M%S)"
ticket-run codex-review -- codex-review start --base <base> --run-dir "$RUN" \
  --focus "Ticket <ID>: <title>. Acceptance: <criteria>. Use cases: <ids and one line each>."
```

- Launch it with `run_in_background: true` (effort `max` takes long) and wait for the
  notification. The tab shows Codex's progress live.
- Base: `repos[repo].base` from `feature.json`, as `origin/<base>` when it exists.
- Triage every finding of `$RUN/round-<n>.json`: CONFIRMED (reproduced), REJECTED (with
  `file:line`, a test run or the invariant that prevents it), NEEDS-USER (the question).
  Codex is a peer, not an authority: apply only what is confirmed. When unsure, it is not
  REJECTED.
- Fix the confirmed ones, re-run the checks with `ticket-run tests`, then reply in the same
  tab:

  ```bash
  ticket-run codex-review -- codex-review reply "$RUN" <scratchpad>/reply-<n>.md
  ```

- Stop when the verdict is clean, after 3 rounds, or when only disagreements remain after
  Codex answered them once.

## 4. Close

1. Write `~/Documents/code-reviews/codex-review-<ID>-<title-slug>.md` from
   `templates/codex-review.md` (create the dir if missing). One row per finding with what
   actually happened; checks with their real output; unrun checks marked as not run.
2. Update the ticket: markdown `Status:` → `in review`, acceptance boxes checked only when
   verified. Never move a Shortcut story. Plan status → `completed`.
3. Reply with: what changed, checks and results, the review file path, open NEEDS-USER items,
   then the PR title, PR body and commit command exactly as CLAUDE.md specifies.
4. Ask the two questions CLAUDE.md requires, separately: commit? push and open the PR?
   Do neither without a yes. On yes to the PR, open it with `gh` with that title and body.
