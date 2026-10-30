---
description: Draft the PR title, body and commit message for the current branch
argument-hint: [base-branch]
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git merge-base:*), Bash(git branch:*), Bash(git rev-parse:*), Bash(gh repo view:*), Bash(gh pr list:*), Bash(ls:*)
---

Draft the PR for the branch that is checked out right now.

## Already-resolved context

- Repo root: !`git rev-parse --show-toplevel`
- Current branch: !`git rev-parse --abbrev-ref HEAD`
- Repo default branch: !`gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo "(no gh remote)"`
- Base branches of recent merged PRs: !`gh pr list --state merged --limit 10 --json baseRefName -q '.[].baseRefName' 2>/dev/null | sort | uniq -c | sort -rn`
- Recent merged PR titles: !`gh pr list --state merged --limit 12 --json title -q '.[].title' 2>/dev/null`
- Working tree: !`git status --short`
- Commits on this branch: !`git log --oneline -15`
- Plans on disk: !`ls -t ~/.claude/plans/ 2>/dev/null | head -15`

Argument given (may be empty): $ARGUMENTS

## Pick the base branch

If `$ARGUMENTS` names a branch, that is the base — no further reasoning.

Otherwise start from the repo default branch and check where this branch actually
diverged, with `git merge-base HEAD origin/<default>` and `git log --oneline
<merge-base>..origin/<default>`. If the merge-base is at or near the default's tip,
propose the default. If the default has moved far past it, or the merge-base sits on
another remote branch, propose that other branch instead and say in one line why.
State the chosen base explicitly — never leave it implicit.

## Gather what changed

Read the real diff against the chosen base: `git diff --stat <base>...HEAD` first, then
the full `git diff <base>...HEAD` for the parts that matter. Include uncommitted work if
`git status` shows any — say so if the branch has none committed yet.

If one of the plans listed above covers this work — match it by project and module, then
confirm by reading the file — read it. It carries the *why*, the decisions already taken,
and the risks left open, and those are the parts a diff cannot tell you. Do not invent a
link to a plan that does not clearly match.

## Output

Three blocks, in this order, and nothing else. No preamble, no summary of what you did.

**1. The PR title on its own line**, prefixed `Title:`, outside any fence. GitHub keeps the
title in a field of its own, so it gets handed over on its own — ready to select and paste
without dragging the body along.

**2. The PR body, inside a fenced block tagged `markdown`.** It has to be pasteable into the
GitHub body field in one selection, so hand it over as literal source — never as prose
rendered into the reply. First line is the title again as an `# H1`, then a blank line, then
the body. The repetition is deliberate: the plain line above feeds the title field, the H1
gives the body a heading when the whole thing is pasted into a description, a doc, or a
ticket.

Open and close that block with **four backticks**, not three. Bodies routinely contain a
fenced code block of their own — a repro command, an ASCII diagram — and a three-backtick
outer fence gets terminated by the first inner one.

The body is a **structured Markdown document**, not a wall of paragraphs. Use `##` headings,
and reach for lists, tables and fenced code the moment the content is actually a list, a
mapping or a command. Default skeleton:

- `## Problem` — why this is being merged. The symptom and its cause, not the file list.
- `## What changed` — behaviour after the merge. Bullets when there is more than one thing.
- `## Verification` — the command in a fenced block, the result underneath.
- `## Follow-up` — only when a human has to do something after the merge (resolve an issue,
  run a migration, flip a flag). Drop the heading when there is nothing to do.

Adapt the skeleton when the change genuinely has a different shape; do not pad it with empty
sections to fill it out. Prose still carries the reasoning inside each section — the headings
are for scanning, not an excuse for fragments.

No emoji, no checkbox theatre, no "Generated with" trailer.

**Report verification honestly.** Say which tests were run and what came out. Tests you did
not run are never described as passing — say they were not run. A step from the plan you could
not check is stated as unchecked. This is the rule worth breaking the reply over.

**3. The commit message**, as a ready-to-paste command in its own `bash` block, on a single
line:

```bash
git commit -m"type(module): one sentence in English"
```

Exactly that shape: `-m` glued to the quote, the whole message inside it. No body, no
`Co-Authored-By`, no trailers, nothing after the closing quote. Take `module` from the repo's
own `git log`, not from the file path.

### The title line

**The PR title is not the commit message.** They are two different artefacts for two
different readers, and writing one and reusing it wastes the PR title.

The **PR title** is what someone scanning a list of open PRs reads. Plain sentence, sentence
case, no `type(module):` prefix, no trailing period, under ~72 characters. It names the
**outcome** — the state of the world after the merge — because that is what tells a reviewer
whether this PR is theirs to look at. Match whatever the repo's own merged PR titles look
like; check them with `gh pr list --state merged --limit 15 --json title`.

The **commit message** is what survives in `git log --oneline` forever. Conventional shape,
`type(module): what changed`, lowercase after the colon. It names the **change** — the thing a
reviewer can check against the diff.

Same branch, two lines, deliberately different:

| | |
| --- | --- |
| PR title | `Group state machine failures into one Sentry issue across stages` |
| Commit | `fix(sentry): drop the stage suffix from state machine failure issue titles` |

`module` names the thing that **owns the code** — the domain, service or component — taken
from the repo's own log. Not the file path, not the bug's name, not the ticket. If the log
shows `withdraw`, `stex`, `bond-redemption`, then a module like `state-machine-failure` (the
name of the *symptom*) is the wrong shape; the owner is what goes in the parentheses.

Neither line carries ticket ids, branch names, or "fix bug" / "small fixes". If the honest
title needs an "and" in it, the branch has two logical changes — say so rather than smuggling
both into one line.

### The shape, in full

Title: Plain sentence naming the outcome

````markdown
# Plain sentence naming the outcome

## Problem

The symptom, and the cause behind it. One or two paragraphs — why anyone
should merge this.

## What changed

Behaviour after the merge, at the level a reviewer cares about:

- the first thing that is now true
- the second, if there is one

## Verification

```bash
npm test -- path/to/the.spec.ts
```

What came out, honestly — and what was not run.

## Follow-up

Only if a human has to do something after the merge.
````

```bash
git commit -m"fix(module): what changed"
```

Note the two lines differ on purpose — see **The title line** above. If the branch carries
more than one logical change, say so in one line and give the commit message for the dominant
one, rather than inventing a fake single narrative.

## Do not

Do not run `git add`, `git commit`, `git push`, or `gh pr create`. Hand over the blocks and
stop. The user runs them.

Do not emit the PR body twice — once inside the fence and once again rendered as reply prose.
One fenced copy is the deliverable; the second is noise that doubles the length of the reply.
