---
name: codex
description: Use when the user asks to run Codex (codex exec, codex review, codex resume, "pasale esto a codex", "que lo mire codex") to analyse, review, refactor or edit code with OpenAI's CLI. Also use when a second opinion from a non-Claude model is explicitly wanted.
---

# codex — delegating to Codex CLI

Verified against `codex-cli 0.147.0`. Flags drift between releases: if a command exits
non-zero on an unknown flag, check `codex exec --help` before working around it.

## Model and reasoning effort — do not ask

`~/.codex/config.toml` already sets `model` and `model_reasoning_effort`. Omit `-m` and
`--config model_reasoning_effort` and both are inherited. Ask with `AskUserQuestion` only when
the user names a different model or effort, or when the task is trivial enough that dropping to
a cheaper tier is worth a question.

| Model | Supported efforts |
| --- | --- |
| `gpt-5.6-sol` | low · medium · high · xhigh · max · **ultra** |
| `gpt-5.6-terra` | low · medium · high · xhigh · max · **ultra** |
| `gpt-5.6-luna` | low · medium · high · xhigh · max |
| `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini` | low · medium · high · xhigh |

`ultra` is maximum reasoning **with automatic task delegation** — slowest and most expensive,
reserve it for the hardest jobs. If the requested effort exceeds the model's ceiling, fall back
to that model's highest supported effort and say so.

Override syntax when it is actually requested:
`-m <MODEL> --config model_reasoning_effort="<effort>"`

## Sandbox

Default to `read-only`. There is no `--full-auto` in this version.

| Case | Command |
| --- | --- |
| Analysis / review, no writes | `codex exec --sandbox read-only "…"` |
| Apply local edits | `codex exec --sandbox workspace-write "…"` |
| Needs network or broad access | `codex exec --sandbox danger-full-access "…"` |
| Auto-route approval escalations | add `--approve-for-me` |
| Another directory | `-C <DIR>`, plus `--add-dir <DIR>` for extra writable roots |
| Outside a git repo | `--skip-git-repo-check` |

Ask permission with `AskUserQuestion` before `--sandbox danger-full-access` or
`--dangerously-bypass-approvals-and-sandbox`, every time.

Never instruct Codex to commit. `workspace-write` leaves changes in the working tree for the
user to review.

## Capturing output

`-o <FILE>` writes the agent's last message to a file — read it back instead of scraping the
stream. Append `2>/dev/null` to drop reasoning noise on stderr; show stderr only when debugging
or when the user asks for thinking tokens. `--json` emits JSONL events, for parsing only.

```bash
codex exec --sandbox read-only -o /tmp/codex-last.md "prompt" </dev/null 2>/dev/null
```

## stdin

`codex exec` appends piped stdin to the positional prompt. If stdin is neither a TTY nor closed
— background tasks, hooks, scripts — it blocks forever. Append `</dev/null` whenever the call
is not made from an interactive shell. Symptom of getting this wrong: zero bytes of stdout,
zero CPU, process hangs indefinitely.

## Reviewing a diff

`codex exec review` is a subcommand, not a prompt to hand-build. Use it whenever the request is
"have Codex look at the changes".

**A target selector and a prompt cannot be combined** — `--uncommitted`, `--base` and `--commit`
are mutually exclusive with each other *and* with the positional `[PROMPT]`. Pick one form:

```bash
codex exec review --uncommitted        # staged + unstaged + untracked, default instructions
codex exec review --base main          # against a branch
codex exec review --commit <SHA>       # a single commit
codex exec review "custom instructions"  # free-form; Codex picks the target itself
```

If the user wants both a specific target and custom instructions, use the free-form prompt and
name the target inside it, or fall back to `codex exec` with the diff supplied in the prompt.

`review` takes a narrower flag set than `exec`: `-m`, `-c/--config`, `-o`, `--json`, `--title`,
`--ephemeral`, `--skip-git-repo-check`. There is **no** `--sandbox`, `-C/--cd`, `--add-dir` or
`--approve-for-me` — it runs from the current repo and does not need a sandbox choice.

## Resuming

```bash
codex exec resume --last "follow-up prompt"
```

The prompt is positional — no `echo |` needed. The session inherits its original model, effort
and sandbox; `-c/--config` is accepted if something must change. `--all` disables cwd filtering.
After a run finishes, tell the user the session can be resumed.

## Timeouts

Codex emits **no intermediate output** — it writes only on completion. A process killed early
leaves the output file silently empty, with no error. Prefer running synchronously; the
conversation waits for the result anyway. If backgrounding, size the timeout by effort:

| Effort | Timeout |
| --- | --- |
| `low` | 150s |
| `medium` | 300s |
| `high` | 600s |
| `xhigh` | 1200s |
| `max` / `ultra` | 1800s |

## Judging what Codex returns

Codex is a colleague, not an authority — different training cutoff, different blind spots.

- Trust your own knowledge when confident, and push back directly when Codex is wrong.
- Verify disagreements against WebSearch or docs before accepting them, especially on model
  names, recent library versions, and API changes.
- To argue a point, resume the session and identify yourself as Claude using your actual current
  model name, framing it as a discussion between peers rather than a correction.
- On genuine ambiguity, lay out both positions and let the user decide.

## Errors

Stop and report on any non-zero exit, starting with `codex --version`. Do not retry without
direction. Summarise warnings and partial results, then ask how to adjust.
