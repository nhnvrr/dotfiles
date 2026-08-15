# dotfiles

macOS. fish + Starship in Ghostty, herdr for agents, Neovim, VS Code, Kanso ink.

## Install

Needs Apple's command-line tools first — that is the only thing the script does not do for you:

```bash
xcode-select --install

git clone git@github.com:nhnvrr/dotfiles.git ~/Develop/dotfiles
cd ~/Develop/dotfiles
./install.sh              # --skipBrew to only re-link configs
```

Idempotent: re-run it anytime. It installs Homebrew and applies the [`Brewfile`](./Brewfile), installs the runtimes pinned in [`mise/config.toml`](./mise/config.toml), generates an `ed25519` SSH key and registers it with the Keychain, symlinks the files listed below, applies a few macOS defaults (key repeat, Finder extensions, screenshots into `~/Screenshots`), and switches the login shell to fish.

Then, by hand:

1. **Paste the SSH pubkey on GitHub** — already on your clipboard. Add it at <https://github.com/settings/ssh/new> as **both** an authentication and a signing key, or signed commits won't show as Verified.
2. `gh auth login`
3. **Set Chrome as the default browser** — System Settings → Desktop & Dock.
4. **Open Ghostty** — it picks up `ghostty/config`, so the font, the sixteen Kanso slots and option-as-meta are already there. Nothing to set by hand.

## The stack

| Layer | Tool | Config |
|---|---|---|
| Shell | fish | [`fish/config.fish`](./fish/config.fish), [`fish/conf.d/`](./fish/conf.d/) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Ghostty | [`ghostty/config`](./ghostty/config) |
| Agents | herdr — agent state over its socket API, not a shell multiplexer | [`herdr/config.toml`](./herdr/config.toml) |
| Quick questions | `?` → `ask` — one-off question to Claude, read-only, web search when needed | [`fish/config.fish`](./fish/config.fish) |
| Editor | Neovim for fast local code reading; VS Code and Zed alongside | [`nvim/init.lua`](./nvim/init.lua) |
| `$EDITOR` | Neovim | [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) |
| Browser | Chrome — the default handler; Zen installed alongside | — user-level |
| Database | `psql` for scripts, DataGrip for interactive | [`psql/psqlrc`](./psql/psqlrc) |
| Redis | `redis-cli` | — history path in [`00-env.fish`](./fish/conf.d/00-env.fish) |
| HTTP | `curl` via `req`, Bruno for exploratory work | [`fish/config.fish`](./fish/config.fish) |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Fuzzy find | fzf + fd + bat | [`fish/config.fish`](./fish/config.fish) |
| Listings | eza — `ls`, `ll`, `la`, `lt`, with icons and per-file git status | [`eza/theme.yml`](./eza/theme.yml), [`fish/config.fish`](./fish/config.fish) |
| Clipboard | Maccy | [`Brewfile`](./Brewfile) |

Neovim has no plugin manager and exactly one plugin — [`kanso.nvim`](https://github.com/webhooked/kanso.nvim), the colorscheme, added through Neovim 0.12's own `vim.pack`. Its native LSP client provides automatic completion and diagnostics for TypeScript, Go, Rust, Bash, YAML and JSON; `Tab`/`Shift-Tab` select, `Enter` accepts, and `Ctrl-Space` triggers completion manually. Every write runs exactly one formatter: Prettier for TypeScript/YAML/JSON, gofumpt for Go, rustfmt for Rust, and shfmt for Bash. `Space-f` formats without writing and `gd` jumps to a definition.

Keys split by modifier: Ghostty takes `cmd`, fish takes bare `ctrl`, and inside a herdr pane `ctrl+b` is the prefix before any of it.

Typing `?` and a space expands to `ask ""` with the cursor between the quotes — a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. The abbreviation exists so the question lands inside quotes; typed bare, `? why is 5 > 3` would be a redirection and fish would write a file named `3`.

## Theme

**Kanso ink, dark only.** The sixteen ANSI slots live in [`ghostty/config`](./ghostty/config), so that file is the single source of truth and everything downstream follows it for free — nothing here hardcodes a hex.

Neovim is the only thing downstream that carries a palette of its own, and it carries the same one. Everything else resolves through the slots: `bat` and delta run `syntax-theme = ansi`, starship and fish style by ANSI name, `psql` writes the raw SGR slots, and herdr uses its built-in `terminal` theme, which draws its chrome from the same sixteen. Edit one `palette` line and all of those move together.

Every value is upstream's, transcribed byte for byte from the theme's own [`extras/ghostty/kanso-ink`](https://github.com/webhooked/kanso.nvim/tree/main/extras/ghostty) — no hand port and nothing recalculated. Neovim runs the same variant through `kanso.nvim` rather than inheriting the slots, because a colorscheme addresses far more groups than sixteen; both sides come from one upstream, so they agree. Body text lands at 10.73:1.

Two slots do not clear the 3:1 floor. Both are upstream's own values, kept rather than corrected so this stays a transcription:

- **Slot 0 `#14171d`** is the background exactly, so it is invisible as a surface (1.00:1). Nothing in this stack paints it, so it costs nothing today.
- **Slot 8 `#5C6066`** is 2.84:1. It is the one slot doing two jobs — dim text (fish and bat comments, autosuggestion, starship, fzf's info and border) *and* a background (fzf's `bg+`, fish's selection) — so it is the one worth watching. Stepping it toward slot 15 is the fix if it reads too faint.

## Managed files

| Repo | Destination |
|---|---|
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `fish/conf.d/00-env.fish` | `~/.config/fish/conf.d/00-env.fish` |
| `fish/conf.d/10-colors.fish` | `~/.config/fish/conf.d/10-colors.fish` |
| `fish/completions/aws.fish` | `~/.config/fish/completions/aws.fish` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `eza/theme.yml` | `~/.config/eza/theme.yml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files only, no directory symlinks. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

**Not managed, and why not:** Chrome keeps its settings in a file the app rewrites on quit, so it cannot be a symlink. VS Code, Zed and `~/.claude/` are user-level state. `~/.aws/config` and `~/.pgpass` hold reconnaissance material and secrets, and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

The things that will bite you, and nothing else:

- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. That is deliberate — the change gets versioned instead of drifting.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** The Brewfile is the source of truth; an app you want to keep has to be declared, Chrome included.
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` and the `claude` config dir both follow **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **`00-env.fish` must keep its `00-` prefix.** conf.d is sourced sorted by name and mise's vendor snippet prepends to whatever `$PATH` it finds; run after it and a stray `~/.bun/bin` shadows the mise-pinned runtime.
- **Everything custom must be bound inside `fish_user_key_bindings`**, fzf's `Ctrl-T`/`Alt-C` included — fish re-applies the preset bindings on any `$fish_key_bindings` change and anything bound outside is dropped.
- **`down` is a four-way branch, not a plain fzf binding.** `fzf-history-down` has to check search mode, the pager and the cursor line before opening the widget — bind `down` straight to `fzf-history-widget` and Tab-completion arrow navigation and multi-line editing both stop working.
- **Neovim formatting is strict and runs before every write.** A missing formatter or invalid source aborts the write; `:noautocmd write` is the deliberate escape hatch.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **`font-monaspice-nerd-font`, not `font-monaspace-nf`.** GitHub's own build ships no Mono variant, which is the one the icon columns need. A family Ghostty cannot find falls back silently to JetBrains Mono — `ghostty +show-face --string=…` is what tells you.
- **`TERM` is `xterm-ghostty`, and no remote host ships that entry.** `shell-integration-features` carries `ssh-terminfo`, so the first ssh installs it there with `infocmp`/`tic`, and `ssh-env` downgrades to `xterm-256color` when the remote has no `tic`. Drop either one and `clear`, `less` and `nvim` break over ssh. `ghostty +ssh-cache` lists the hosts already done.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```

## Notes

- macOS only. Prompts for your password once, for `chsh`.
- `~/.cache/fish/init.fish` is generated state — delete it and the next shell rebuilds it (~200ms, once).
- Shell startup is ~40ms warm, measured end-to-end with `/usr/bin/time -p /opt/homebrew/bin/fish -l -i -c exit`.
