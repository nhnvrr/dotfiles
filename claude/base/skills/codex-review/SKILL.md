---
name: codex-review
description: Exhaustive review of code Claude Code wrote, done by Codex on its strongest model (gpt-5.6-sol, effort max), with Claude verifying every finding, fixing the confirmed ones and arguing the rest with Codex in the same thread until the review converges. Use when the user asks for a "perfect", "exhaustive" or "deep" review by Codex, "que codex revise lo que hiciste", "revisión con codex hasta que quede limpio", or a Claude-vs-Codex review loop. For a one-off Codex call without the loop, use the codex skill instead.
---

# codex-review

Loop: **Codex reviews → Claude verifies → Claude fixes → Codex re-reviews and answers**, all in
one Codex thread so it remembers its findings and Claude's arguments.

```
start ─► round-1.json ─► triage ─► fix + checks ─► reply ─► round-n.json ─┐
                           ▲                                               │
                           └────────── until clean or 3 rounds ◄───────────┘
```

Script: `~/.claude/skills/codex-review/scripts/codex-review` (alias below: `$CR`).

## 1. Start

From the repo or worktree holding the changes:

```bash
$CR start [--base <ref>] [--focus "<what the user is worried about>"]
```

- Base defaults to `origin/development`, else `origin/HEAD`, else `main`. The review covers
  committed, staged, unstaged and untracked changes since the merge-base.
- It prints the run dir (inside the git dir, never tracked). Keep it.
- Effort `max` takes long: **run it with `run_in_background: true`** and wait for the
  completion notification. Never poll, never kill it early: Codex writes only at the end and an
  early kill leaves nothing.
- Non-zero exit or empty output: stop and report `stderr.log`. Do not retry blindly.

## 2. Triage every finding (no exceptions)

Read `round-<n>.json` (from round 2 on, also its `response_to_claude`). For each finding with status `new` or `still_open`, open the code and
classify it:

| Verdict | Meaning | Required evidence |
| --- | --- | --- |
| CONFIRMED | Real defect | You reproduced the failure path by reading or running the code |
| REJECTED | Codex is wrong | file:line, a test run, docs, or the invariant that prevents it |
| NEEDS-USER | Product or scope decision | The concrete question for the user |

Codex is a peer, not an authority. Do not accept a finding because Codex said it, and do not
reject one without evidence. If unsure, it is CONFIRMED or NEEDS-USER, never REJECTED.

## 3. Fix

Fix every CONFIRMED finding following the repo's own rules (CLAUDE.md, existing patterns). Then
run the repo's typecheck, lint and the tests of the touched packages. A fix that breaks a check
is not a fix. Never commit.

## 4. Reply

Write the message to a file in the scratchpad and resume:

```bash
$CR reply <run-dir> <message-file>      # also background for effort max
```

Message shape (identify yourself with your real model name):

```
Claude (<model>) here. Round <n> response.
Fixed: F1 (<what changed, file:line>), F3 (...)
Disagree: F2, because <evidence>. Please re-check and withdraw or explain.
Needs user: F4, <question>, not changed yet.
Checks: <commands> -> <real result>
```

## 5. Stop when

- `verdict` is `clean` and no finding is `new` or `still_open`, or
- 3 rounds are done, or
- only disagreements remain after Codex answered them once: stop arguing and give both
  positions to the user.

## 6. Report to the user

One table, most severe first, with what actually happened to each finding:

| id | severity | file:line | finding | outcome |
| --- | --- | --- | --- | --- |
| F1 | high | `a.ts:42` | ... | fixed in round 1, Codex resolved |
| F2 | medium | `b.ts:7` | ... | rejected, Codex withdrew |
| F4 | low | `c.ts:3` | ... | needs your decision: ... |

Then: rounds run, checks run with their real output, open disagreements, NEEDS-USER questions,
and the run dir path. Unrun checks are reported as unrun.

## Notes

- Override model or effort only when the user asks: `CODEX_REVIEW_MODEL=… CODEX_REVIEW_EFFORT=…`.
  Ceilings are in the `codex` skill.
- `gpt-5.4-mini` is rejected on a ChatGPT account.
- Codex reads the user's global instructions too. The script forbids PR text and commit messages
  in its output. Ignore any that slip through anyway.
