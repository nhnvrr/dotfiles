# Codex review · <ID> · <ticket title>

> **Ticket:** <ID> (<tracker url or markdown file>)
> **Feature:** <feature title> (`<slug>`) · <artifact url>
> **Repo:** <repo> · **Branch:** `<branch>` · **Base:** `<base>`
> **Date:** <YYYY-MM-DD> · **Rounds:** <n> · **Model:** <codex model>, effort <effort> · **Reviewer:** Claude (<model>)
> **Verdict:** <clean | open disagreements | needs user>

## Summary

<two or three sentences: what Codex found, what was fixed, what is still open>

## Findings

| id | severity | file:line | Codex finding | Claude verdict | evidence | outcome |
| --- | --- | --- | --- | --- | --- | --- |
| F1 | high | `src/a.ts:42` | <one line> | CONFIRMED | <how it was reproduced> | fixed round 1, Codex resolved |
| F2 | medium | `src/b.ts:7` | <one line> | REJECTED | <file:line / test / invariant> | Codex withdrew |
| F3 | low | `src/c.ts:3` | <one line> | NEEDS-USER | — | waiting for decision |

## Open disagreements

<per finding: Codex's position, Claude's position with evidence. Drop the section if none.>

## Needs your decision

<per finding: the concrete question. Drop the section if none.>

## Checks

```bash
<each command, as run>
```

<the real result of each. Checks not run are listed as not run.>

## Run

- Run dir: `<path>`
- Rex: session `<name>`, tabs `codex-review` and `tests`
