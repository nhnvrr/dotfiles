# Global instructions

## Commits

**Never commit.** Not in any repo, not in any project, not even after finishing a unit of work. Leave the changes in the working tree and report what was modified. The user commits when they want to.

No `git add`, `git push`, `git reset` either, or anything that moves the index or the history, unless explicitly and specifically asked for.

### Closing a finished task

Every time a task is finished — and always at the end of implementing a plan — close the reply with three things, ready to copy, in this order:

**1. The PR title on its own line**, prefixed `Title:`, so it can go straight into GitHub's title field.

**2. The PR body**, inside a fence opened and closed with **four backticks** and tagged `markdown` — bodies routinely contain a fenced block of their own, and a three-backtick outer fence gets terminated by the first inner one.

The body repeats the title as an `# H1` first line, then a blank line, then a **structured document**: `##` headings, and lists, tables or fenced code the moment the content is actually a list, a mapping or a command. Default skeleton:

- `## Problem` — the symptom and the cause behind it. Why anyone should merge this.
- `## What changed` — behaviour after the merge, at the level a reviewer cares about.
- `## Verification` — the commands in a fenced block, the real result underneath.
- `## Follow-up` — only when a human has to do something after the merge (open a ticket, run a migration, flip a flag). Drop the heading when there is nothing to do.

Adapt the skeleton when the change genuinely has a different shape; never pad it with empty sections to fill it out. Prose still carries the reasoning inside each section — the headings are for scanning, not an excuse for fragments. English, no emoji, no checkbox theatre, no "Generated with" trailer.

**Verification is reported honestly.** Say which tests ran and what came out. Tests that were not run are never described as passing, and a step that could not be checked is stated as unchecked. This is the rule worth breaking the reply over.

**3. The commit message**, as a ready-to-paste command in its own `bash` code block, on a single line:

```bash
git commit -m"type(module): one sentence in English"
```

Exactly that shape: `-m` glued to the quote, the whole message inside it. No body, no `Co-Authored-By`, no trailers, nothing after the closing quote.

`module` is short and lowercase, taken from the repo's own log — the domain that **owns** the code, not the file path, not the ticket, not the symptom.

#### Title and commit message are different lines

They are two artefacts for two readers, and writing one and reusing it wastes the title.

| | |
| --- | --- |
| **PR title** | What someone scanning a list of open PRs reads. Sentence case, no `type(module):` prefix, no trailing period, under ~72 characters. Names the **outcome** — the state of the world after the merge. |
| **Commit** | What survives in `git log --oneline` forever. Conventional shape, lowercase after the colon. Names the **change** — the thing a reviewer checks against the diff. |

Neither carries ticket ids, branch names, or "fix bug" / "small fixes". If the honest title needs an "and", the branch has two logical changes — say so instead of smuggling both into one line.

The command form is for copying, **not** a licence to run it: the rule above still holds. Never execute `git commit` — hand over the block and let the user paste it. The PR is opened by hand too.

Do not emit the body twice — once inside the fence and once again rendered as reply prose. One fenced copy is the deliverable.

## Explanations and drawings

When I ask for an explanation **or a drawing**, **answer with a diagram**: hand-typed Unicode box-drawing inside a code block. It is the default format, not something to be asked for each time.

No mermaid, no images. Mermaid has no layout engine of its own — `@mermaid-js/mermaid-cli` declares `puppeteer` as a peerDependency, so rendering it means a headless Chromium — and the result could not be shown inline anyway: Terminal.app implements no image protocol at all, neither Sixel nor iTerm2's nor kitty's. ASCII works in every terminal and over ssh, with nothing to install.

Asking for mermaid by name is not an exception: it is exactly the case this rule covers. Offer ASCII, say why in one line, and confirm. Mermaid source goes out only when the stated destination is a README, a doc, or GitHub, where something renders it — and there it goes in addition to the ASCII, not instead of it.

Stroke convention, since there is no color inside the block: solid `─ │ ┌ ┐ └ ┘ ├ ┤ ┬ ┴` for the path that works, double-dash `╌ ╎` for what is broken or missing, and a legend at the foot when both appear together. Alignment is manual: each glyph is one cell and the columns are counted. Max ~78 columns so it does not wrap in a narrow window or a split pane.

**Legibility is part of the answer, not a finishing touch.** A diagram that is hard to read is a worse explanation than the prose it replaced, so spend the effort:

- **Alignment is the whole game.** Columns must line up exactly — count cells, do not eyeball. Never put an emoji or any double-width glyph inside the block: it silently shifts every column below it.
- **Give it air.** A header line naming what is drawn, and space around the glyphs. Cramped beats nothing, but only just; a node every other line reads far better than a wall.
- **One direction per diagram**, top-down or left-to-right, never both in the same drawing.
- **Keep labels short enough that the boxes do not burst.** Detail goes on an annotation line beside the box or in the legend, never by widening the box.
- **If it does not fit in ~78 columns, split it into two diagrams** instead of shrinking the labels. Two readable drawings beat one dense one.
- **Annotate with real values** when there are any — the concrete number next to the arrow (`amount = max(0, 0 − 231) ──► 0`) is what makes the drawing an argument instead of a decoration.

Only exception: when there is no structure to draw —a definition, two numbers to compare, a yes/no— use a table or prose, and say in one line why there is no diagram. Forcing boxes around a sentence gives a worse explanation, not a better one.

## Code comments

Code comments are **always in English**, in every project and every language, regardless of the language of the conversation. This applies to comments that get edited or moved, not just new ones: if you touch a line with a comment in another language, it ends up in English.

Keep them minimal: keep the comment that prevents breaking something (a trap, an order that matters, an API that lies). History and rationale go in the commit message, not inline.

## Plans

**Writing anything into `~/.claude/plans/` is itself the trigger for the `new-plan` skill.** It is not optional, and it does not wait for me to decide the task looks plan-shaped.

The skill owns the details. Two rules restated here because they are the ones that get violated:

- **Never keep the filename plan mode hands you.** It is a slug generated from my first sentence —`como-puedo-hacer-para-declarative-frost.md`— and says nothing about the contents, which makes the folder unbrowsable a week later. The name is `YYYY-MM-DD-<project>-<module>-<short-description>.md`, lowercase kebab-case, with `<project>` derived from `basename "$(git rev-parse --show-toplevel)"` and never asked.
- **The header blockquote is mandatory** —**Created**, **Last updated**, **Status**— because that, not the filename, is what gets listed.

### Closing a plan

Hand over the full path of the plan file as the last line, before `ExitPlanMode`. When a plan is edited, bump **Last updated** to today's date.
