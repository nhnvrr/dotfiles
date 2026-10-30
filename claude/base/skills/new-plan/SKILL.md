---
name: new-plan
description: Use this skill whenever the user asks to create a new plan, or before writing any file under `~/.claude/plans/`. Builds a properly-named plan file following the `YYYY-MM-DD-project-module-description.md` convention, with a dated header. Trigger phrases include "create a plan", "make a plan", "plan for X", "necesito un plan", "armá un plan", entering plan mode, or any intent to write a `*.md` file under `~/.claude/plans/`.
---

# new-plan — Plan creation convention

## When to invoke this skill

Trigger this skill (or follow its flow even if not invoked explicitly) in any of these situations:
- The user asks to create a plan ("create a plan", "make a plan for X", "armá un plan", "necesito un plan").
- You are about to enter plan mode (`/plan`, the `ExitPlanMode` workflow).
- You are about to write or create a file under `~/.claude/plans/`.

## Mandatory steps

### 1. Compose the filename

Format: `YYYY-MM-DD-<project>-<module>-<short-description>.md`

All lowercase, kebab-case, no brackets, no colons, no spaces — the names must be greppable and tab-completable without quoting.

**`YYYY-MM-DD`** — today's date, from the session date context.

**`<project>`** — derive it, never ask. In order of preference:
1. `basename "$(git rev-parse --show-toplevel)"` from the working directory.
2. If not a git repo, `basename "$PWD"`.
3. Strip a leading dot: `~/.claude` → `claude`.

Typical values in this setup: `side`, `vesto-workflows`, `dotfiles`, `foundations`, `claude`.

**`<module>`** — the subsystem the plan touches: `goals`, `rebalancer`, `statusline`, `nvim`, `tmux`, `api`, `prisma`. Infer it from the files and directories in play. Only ask if it is genuinely ambiguous, and when you do, ask with a concrete proposal already loaded ("¿`goals` o `kpi`?") rather than an open question.

**`<short-description>`** — 3 to 5 words in kebab-case describing the actual change.

Examples:
- `2026-07-30-side-goals-kpi-con-targets.md`
- `2026-07-30-vesto-workflows-rebalancer-migrar-sdk-beta.md`
- `2026-07-30-dotfiles-nvim-lualine-devicons.md`
- `2026-07-30-claude-config-limpieza-y-mejora.md`

### 2. Mandatory header inside the file

At the start of the plan, **always** include a metadata blockquote:

```markdown
# Plan: <descriptive title>

> **Created:** YYYY-MM-DD
> **Last updated:** YYYY-MM-DD
> **Status:** pending approval

## Context
...
```

Valid statuses (in order of progression):
- `pending approval`
- `approved`
- `in implementation`
- `completed`
- `discarded`

No ticket field. Traceability comes from the date plus the project/module in the filename.

### 3. When editing an existing plan

- Update the **Last updated** line to today's date.
- If the file doesn't follow the filename convention, offer to rename it (use `mv` after exiting plan mode if needed).
- If the file has no header, add one.

## Why

The user needs to locate executed plans in `~/.claude/plans/` by **date** (chronological order) and by **project/module** (which repo and subsystem the work touched). Without this convention, the folder becomes an unordered blob of auto-generated slugs with no traceability — which is exactly what happened before it was reset on 2026-07-30.

## Anti-patterns to avoid

- ❌ Keeping the auto-generated filename from plan mode (e.g. `esta-es-tu-folder-dazzling-bear.md`, `necesito-que-crees-un-snappy-quasar.md`). Plan mode hands you a random slug — always rename it to the convention.
- ❌ Asking the user for `<project>` instead of deriving it from the repo root.
- ❌ Brackets, colons, uppercase or spaces in the filename.
- ❌ Creating the plan without the header.
- ❌ Editing a plan without updating **Last updated**.

## Visual confirmation to the user

After creating the plan, confirm to the user with the full file path. Match the user's language (Spanish or English):

> Plan created: `~/.claude/plans/2026-07-30-side-goals-kpi-con-targets.md`

> Plan creado: `~/.claude/plans/2026-07-30-side-goals-kpi-con-targets.md`
