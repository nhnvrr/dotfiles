# dotfiles

macOS. zsh + Starship in Alacritty, Hammerspoon for window tiling, herdr for agents, Neovim, VS Code, GitHub Dark Dimmed.

## Install

Needs Apple's command-line tools first — that is the only thing the script does not do for you:

```bash
xcode-select --install

git clone git@github.com:nhnvrr/dotfiles.git ~/Develop/dotfiles
cd ~/Develop/dotfiles
./install.sh              # --skipBrew to only re-link configs
```

Idempotent: re-run it anytime. It installs Homebrew and applies the [`Brewfile`](./Brewfile), installs the runtimes pinned in [`mise/config.toml`](./mise/config.toml), generates an `ed25519` SSH key and registers it with the Keychain, symlinks the files listed below, applies a few macOS defaults (key repeat, Finder extensions, screenshots into `~/Screenshots`), and switches the login shell to zsh.

Then, by hand:

1. **Paste the SSH pubkey on GitHub** — already on your clipboard. Add it at <https://github.com/settings/ssh/new> as **both** an authentication and a signing key, or signed commits won't show as Verified.
2. `gh auth login`
3. **Set Chrome as the default browser** — System Settings → Desktop & Dock.
4. **Launch Alacritty once** — font, palette and Option-as-Meta all come from `alacritty/alacritty.toml`, so there is nothing to click. The first long command asks for notification permission (the bell); allow it.

## The stack

| Layer | Tool | Config |
|---|---|---|
| Shell | zsh — macOS's own `/bin/zsh`, no framework | [`zsh/zshrc`](./zsh/zshrc), [`zsh/zshenv`](./zsh/zshenv) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Alacritty | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) |
| Agents | herdr — agent state over its socket API, not a shell multiplexer | [`herdr/config.toml`](./herdr/config.toml) |
| Quick questions | `?` → `ask` — one-off question to Claude, read-only, web search when needed | [`zsh/zshrc`](./zsh/zshrc) |
| Editor | Neovim for fast local code reading; VS Code alongside | [`nvim/init.lua`](./nvim/init.lua) |
| `$EDITOR` | Neovim | [`zsh/zshenv`](./zsh/zshenv) |
| Browser | Chrome — the only one, and the default handler | — user-level |
| Database | `psql` for scripts, DataGrip and TablePlus for interactive | [`psql/psqlrc`](./psql/psqlrc) |
| Redis | `redis-cli` | — history path in [`zsh/zshenv`](./zsh/zshenv) |
| HTTP | `curl` via `req`, Bruno for exploratory work | [`zsh/zshrc`](./zsh/zshrc) |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Fuzzy find | fzf + fd + bat | [`zsh/zshrc`](./zsh/zshrc) |
| Listings | eza — `ls`, `ll`, `la`, `lt`, with icons and per-file git status | [`eza/theme.yml`](./eza/theme.yml), [`zsh/zshrc`](./zsh/zshrc) |
| Clipboard | Maccy | [`Brewfile`](./Brewfile) |
| Window tiling | Hammerspoon — right pane Chrome, left pane on `cmd+alt+1/2/3` | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |

Neovim has no plugin manager: the handful of plugins it does use — the [`github-nvim-theme`](https://github.com/projekt0n/github-nvim-theme) colorscheme, neo-tree and fzf-lua with their dependencies — are added through Neovim 0.12's own `vim.pack`. Its native LSP client provides automatic completion and diagnostics for TypeScript, Go, Rust, Bash, YAML and JSON; `Tab`/`Shift-Tab` select, `Enter` accepts, and `Ctrl-Space` triggers completion manually. Every write runs exactly one formatter: Prettier for TypeScript/YAML/JSON, gofumpt for Go, rustfmt for Rust, and shfmt for Bash. `Space-f` formats without writing and `gd` jumps to a definition.

Keys split by modifier: Alacritty takes `cmd`, zsh takes bare `ctrl`, and inside a herdr pane `ctrl+b` is the prefix before any of it.

Typing `?` and a space expands to `ask ""` with the cursor between the quotes — a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. The abbreviation exists so the question lands inside quotes; typed bare, `? why is 5 > 3` would be a redirection and zsh would write a file named `3`.

## Theme

**GitHub Dark Dimmed, dark only.** `alacritty/alacritty.toml` carries the palette, so the terminal owns the sixteen slots and everything downstream follows them for free — nothing here hardcodes a hex. Under Terminal.app the same sixteen lived in `com.apple.Terminal.plist`, which the app rewrites on quit and which therefore could never be a symlink; moving to Alacritty is what brought them into the repo.

Neovim is the only thing downstream that carries a palette of its own, and it carries the same one. Everything else resolves through the slots: `bat` and delta run `syntax-theme = ansi`, starship styles by ANSI name and zsh-syntax-highlighting by ANSI slot number, `psql` writes the raw SGR slots, and herdr uses its built-in `terminal` theme, which draws its chrome from the same sixteen. A bundled-theme update moves all of those together.

`alacritty.toml` paints the GitHub Dark Dimmed variant, while Neovim runs the same variant through [`github-nvim-theme`](https://github.com/projekt0n/github-nvim-theme)'s `github_dark_dimmed`. Neovim does not inherit the terminal slots because a colorscheme addresses far more groups than sixteen; the two applications still agree on `#22272e`, and body text (`#adbac7`) lands at 7.60:1.

Two of the sixteen ANSI slots do not clear the 3:1 floor against `#22272e`, and unlike the previous theme one of them is painted:

| Slot | | Ratio | Painted by |
|---|---|---|---|
| 0 | `#545d68` black | 2.25:1 | nothing in this stack |
| 8 | `#636e7b` brblack | 2.90:1 | comments, autosuggestions, completion descriptions, starship's time |

Slot 8 is the one that costs something. `zsh/zshrc` uses `fg=8` for `comment` and for `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`, and starship styles its time and username modules `bright-black` — all of that now sits just under the floor at 2.90:1. It is deliberately low-salience text, so this is a known trade rather than an oversight; raising it means moving those to slot 7 (`#909dab`, 5.44:1) and losing the visual separation that makes an autosuggestion read as *not yet typed*.

Any window opacity in the profile pulls every ratio above down slightly, by whatever shows through; the blur is what keeps that predictable instead of dependent on the window behind.

## Managed files

| Repo | Destination |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/completions/_aws` | `~/.config/zsh/completions/_aws` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `eza/theme.yml` | `~/.config/eza/theme.yml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files only, no directory symlinks. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

**Not managed, and why not:** Chrome keeps its settings in a file the app rewrites on quit, so it cannot be a symlink. VS Code and `~/.claude/` are user-level state. `~/.aws/config` and `~/.pgpass` hold reconnaissance material and secrets, and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

The things that will bite you, and nothing else:

- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. That is deliberate — the change gets versioned instead of drifting.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** The Brewfile is the source of truth; an app you want to keep has to be declared, Chrome included.
- **Hammerspoon and Maccy both need Accessibility permission**, granted by hand on first launch. Without it Hammerspoon's placements silently no-op — `init.lua` raises an alert when it detects the permission missing, which is the only reason you find out.
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` and the `claude` config dir both follow **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **`$PATH` is assembled twice, on purpose.** `.zshenv` runs before `/etc/zprofile`, which calls `path_helper` and pushes `/usr/bin` back in front of everything — so `zshrc` calls `__path_setup` again. `typeset -U path` is what makes the second call reorder instead of duplicate. Delete either half and a system runtime shadows the mise-pinned one.
- **`zsh-syntax-highlighting` is sourced on the last line of `zshrc`, and has to be.** It wraps the widgets that exist when it loads; `fzf-history-down` and fzf's own widgets are defined just above it. Move the `source` up and they stop being highlighted.
- **`down` is not bound straight to `fzf-history-widget`.** `fzf-history-down` checks whether the cursor still has lines below it first — bind the widget directly and multi-line editing loses its cursor movement.
- **Homebrew ships no zsh auto-activation for mise.** fish got one from `vendor_conf.d`; zsh needs the explicit `eval "$(mise activate zsh)"` in `zshrc`. Drop it and every runtime falls back to whatever is on `$PATH`.
- **`down` is a four-way branch, not a plain fzf binding.** `fzf-history-down` has to check search mode, the pager and the cursor line before opening the widget — bind `down` straight to `fzf-history-widget` and Tab-completion arrow navigation and multi-line editing both stop working.
- **Neovim formatting is strict and runs before every write.** A missing formatter or invalid source aborts the write; `:noautocmd write` is the deliberate escape hatch.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **`font-jetbrains-mono-nerd-font`, not `font-jetbrains-mono`.** The plain cask carries no Nerd Font glyphs, which is what the eza icon column and starship need. The cask installs three families whose names differ by one word — `Mono`, `Propo` and `NL` — and only `JetBrainsMono Nerd Font Mono` keeps the icon column aligned. `alacritty.toml` names it in full as `JetBrainsMono Nerd Font Mono`, and a family it cannot find falls back silently — `ll` showing boxes instead of icons is what tells you the name was wrong.
- **Alacritty sets `TERM=xterm-256color`, not its own `alacritty`.** The cask does install the `alacritty` terminfo, into `~/.terminfo` symlinked inside the app bundle, so it resolves locally — but `TERM` travels over ssh and almost no remote host has the entry, which breaks `clear`, `less` and nvim there. The price is that `xterm-256color` does not advertise `Smulx`, so undercurl renders as a plain underline. Drop the `[env]` block to get it back.
- **The `alacritty` cask is deprecated in Homebrew and disabled on 2026-09-01** — it fails the macOS Gatekeeper check. After that date `brew bundle` will skip it and the app has to come from the [GitHub release](https://github.com/alacritty/alacritty/releases) or `cargo install alacritty`.
- **`install.sh` strips the quarantine attribute off `Alacritty.app`.** Homebrew removed `--no-quarantine` from `brew install --cask`, and a Brewfile `args: { no_quarantine: true }` now fails outright with `invalid option`. Without the `xattr -dr` every launch is a right-click → Open.
- **The bell is a notification now, not a Dock bounce.** Terminal.app bounced the Dock for free; Alacritty needs the `[bell]` block, which shells out to `osascript`. macOS asks for notification permission the first time — deny it and long commands finish silently in the background.
- **Neovim forces `termguicolors` instead of autodetecting.** Alacritty exports `COLORTERM=truecolor` and honours 24-bit colour, but that variable does not survive every ssh — forcing it keeps the colourscheme instead of dropping to sixteen slots silently.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```

## Notes

- macOS only. Prompts for your password once, for `chsh`.
- `~/.cache/zsh/` is generated state — `init.zsh`, the compinit dump and the aws description tables. Delete it and the next shell rebuilds all of it.
- Shell startup is ~60ms warm, measured end-to-end with `/usr/bin/time -p /bin/zsh -l -i -c exit`. fish did the same in ~40ms; the difference is `compinit` plus the two plugins, and it is the price of the move.
