---
name: rex
description: Drive Rex (Superlogical's terminal multiplexer) to run coding agents (Claude Code or Codex) in parallel, one git worktree per Rex session, and to act on other sessions. Use when the user mentions Rex, asks to start a new feature/branch in its own worktree or session, asks to open or run something (logs, tests, a shell) in another session as a new tab or split, or asks to send work to, read, wait on, or clean up another agent's Rex session.
---

# Rex

Rex model: **session** (one per worktree) → **window** (tab) → **block** (one terminal).
Every Rex terminal exports `REX_SESSION`, `REX_BLOCK`, `REX_SERVER` and `REX_BIN_DIR`.
Outside a Rex terminal the CLI is not on PATH; use
`/Applications/Rex Beta.app/Contents/Helpers/Rex Server.app/Contents/MacOS/rex`
(the script below does this on its own). If `REX_SESSION` is unset and that binary is
missing, Rex is not running here: say so and stop.

Codex: the default sandbox blocks the Rex server socket (every `rex` call fails with a
permission error). Run Codex with `--sandbox danger-full-access`, or approve the escalated
command when prompted.

## Start a feature in its own worktree

From any directory inside a git repo:

```bash
~/.agents/skills/rex/scripts/rex-wt new <branch> [--name <session>] [--from <base>] [--prompt "<task>"] [--agent claude|codex|none]
```

- Creates `<repo>/.claude/worktrees/<slug>`. Inside it delegates to `scripts/spexs-tree`
  (base `development`, copies `.env*`, `pnpm install`, generated clients), so it takes minutes.
  Elsewhere it is a plain `git worktree add` off `HEAD`.
- Existing local or `origin/` branches are checked out instead of created.
- The worktree dir and the Rex session share one name: `--name` (slugified) or the branch slugified.
- Opens that Rex session running the agent (`claude` by default, `codex` with `--agent codex`,
  or `$REX_WT_AGENT`) with the prompt if given, and a `shell` block below. `--no-claude`
  is an alias of `--agent none`.
- Prints `{session_id, label, branch, path, main_block, shell_block}` as JSON. Keep the IDs.
- Block targets resolve inside the *current* session: always pair `-b <id>` with `-s <session>`.
- A fresh worktree path triggers Claude's folder-trust dialog (reported as `blocked`); accept it with
  `rex send-key -s <s> -b <main_block> down` then `enter` only if the user agreed.

Only create a worktree when the user asks to start a feature or branch in parallel. Never
switch the current checkout's branch to do it.

Other commands:

```bash
~/.agents/skills/rex/scripts/rex-wt ls                         # repo worktrees + whether a Rex session is live
~/.agents/skills/rex/scripts/rex-wt rm <name|branch> [--branch] --yes # kill session + remove worktree
```

`rm` is destructive: confirm with the user first, then pass `--yes` (it otherwise prompts on stdin).

## Talk to another agent

```bash
rex send -s <session> '<text>'      # does NOT press Enter
rex send-key -s <session> enter
rex capture -s <session> -b <block> --trim --unwrap   # read its screen
rex block ls -s <session> --json           # find block ids (agent block vs shell block)
```

Target the agent block explicitly with `-b <block_id>` once known; `-s` alone hits the focused block.

## Run something in another session (new tab or split)

"In session X, open/run Y" means a *new terminal block in X running Y*, not text typed into
X's agent. Check the session exists first (`rex ls --json`, match `label`, case-insensitive).

```bash
# split next to the CURRENT block: use the script, no flags to work out
~/.agents/skills/rex/scripts/rex-split [right|left|above|below] [--ratio N] [--label L] -- <cmd...>
# e.g. rex-split right --label db -- psql postgresql://user:pass@localhost:5432/dbname

# new tab (window) in another session
rex window new -s <session> <label> -c <cwd> --keep-open -- <cmd...>

# split next to a block in another session
rex run -s <session> --split=right --ratio 40 [-b <block>] -c <cwd> --keep-open -- fish -c '<cmd>'
```

`rex-split` (also on PATH via `~/.local/bin`) defaults to right, 40%, the current
session/block and `$PWD`, and wraps the command in `fish -c`: interactive programs such as
`psql` launched bare by `rex run` exit at once. Default direction when the user does not say
is **right**.

- **Tab vs split**: tab when the user says "tab", "window", "pestaña", or does not say; split when
  they say "split", "al lado", "abajo", or name the block it should sit next to (`-b`, from
  `rex block ls -s <session> --json`).
- **cwd is not inherited**: a new block starts in `$HOME` unless `-c` is given. Read the
  session's directory from the prompt in `rex capture -s <session> --trim --unwrap` of its
  shell block, or ask. Known at the time of writing: `vesto` → `~/work/vesto-workflows`.
- `--keep-open` keeps the block when the command exits so the output can still be read.
- `--focus=false` when the user is working in another session and should not be pulled over.
- `--label` / the window label: short and about the content (`logs`, `tests`, `db`).
- Commands are not shell-parsed: pipes and `&&` go inside `sh -c '...'`.

### Recipe: tail a Lambda's logs in a serverless repo

Function name and stage come from the user; if missing, list candidates from `functions:` in
`serverless.yml` and ask. The log group is `/aws/lambda/<service>-<stage>-<function>`.

```bash
rex window new -s vesto logs -c ~/work/vesto-workflows --keep-open -- \
  aws logs tail /aws/lambda/workflows-<stage>-<function> --follow --format short
```

Add `--since 1h` for history, or `--filter-pattern '<text>'` to narrow it.

## Wait and watch

```bash
rex wait --for 30m <block_id>                         # exits with the child's status
rex events -s <session> --json                        # NDJSON stream, runs until killed
```

Agent state arrives as `block_event` with `name` `program_status_changed`:
`.payload.event.payload.payload.record.state` is `idle | working | blocked | done | error`,
and `.record.msg` carries the prompt or the current tool's description.
Claude Code emits this natively (OSC 7501, `app=claude-code`); no hook is needed. Codex does
not, so for a Codex block poll `rex capture` instead. To wait until a Claude agent needs
attention, stream events and stop at the first `blocked` or `done` for its block.

## Rules

- Always pass `--json` when you will parse output; save IDs, labels can change or collide.
- Exit codes: 1 failure, 2 bad command line, 3 target missing or ambiguous, 4 server unreachable.
- Never `rex kill` a session, `rex block close` a block you did not create, or remove a worktree
  without the user's confirmation.
- Commands given to `rex run`/`split`/`new`/`window new` are not shell-parsed: wrap pipes in `sh -c '...'`.
