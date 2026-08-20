# dotfiles

macOS. zsh + Starship in Ghostty, Hammerspoon for window tiling, herdr for agents, Neovim, VS Code, Jellybeans.

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
4. **Launch Ghostty once** — font, palette and Option-as-Alt all come from [`ghostty/config`](./ghostty/config), so there is nothing to click. The first long command asks for notification permission (the bell); allow it.

## The stack

| Layer | Tool | Config |
|---|---|---|
| Shell | zsh — macOS's own `/bin/zsh`, no framework | [`zsh/zshrc`](./zsh/zshrc), [`zsh/zshenv`](./zsh/zshenv) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Ghostty | [`ghostty/config`](./ghostty/config) |
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

Neovim has no plugin manager: the handful of plugins it does use — the [`jellybeans.nvim`](https://github.com/wtfox/jellybeans.nvim) colorscheme, neo-tree and Telescope with their dependencies — are added through Neovim 0.12's own `vim.pack`. `Space-f` then `f`/`g`/`b`/`h`/`r`/`d` opens Telescope on files, a project-wide grep, buffers, help tags, recent files and diagnostics, and `Space-/` searches the current buffer; `telescope-fzf-native` is compiled on install so the matching ranks the same way as the shell's `Ctrl-T`. Its native LSP client provides automatic completion and diagnostics for TypeScript, Go, Rust, Bash, YAML and JSON; `Tab`/`Shift-Tab` select, `Enter` accepts, and `Ctrl-Space` triggers completion manually. Every write runs exactly one formatter: Prettier for TypeScript/YAML/JSON, gofumpt for Go, rustfmt for Rust, and shfmt for Bash. `Space-f` formats without writing and `gd` jumps to a definition.

Keys split by modifier: Ghostty takes `cmd`, zsh takes bare `ctrl`, and inside a herdr pane `ctrl+b` is the prefix before any of it.

The window title is pinned to `🧉` and never changes. Ghostty ignores the title escape sequence outright rather than overriding it once, so the titlebar stops echoing whatever process is in the foreground — information that is already on screen in herdr's sidebar and in lualine. It only affects the window title: herdr owns the ptys inside its panes and still parses those sequences itself. The one cost is the 🔔 that `bell-features = title` prepends when a long command finishes; the system notification and the Dock bounce in that same list are untouched.

Typing `?` and a space expands to `ask ""` with the cursor between the quotes — a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. The abbreviation exists so the question lands inside quotes; typed bare, `? why is 5 > 3` would be a redirection and zsh would write a file named `3`.

## Theme

**Jellybeans, dark only.** [`ghostty/config`](./ghostty/config) carries the palette slot by slot, so the terminal owns the sixteen slots and everything downstream follows them for free — nothing else here hardcodes a hex. Dark grey at `#242424`, warm off-white text at `#e8e8d3`, which is 12.50:1.

The background is the one value that does *not* come from jellybeans, which paints `#151515`. Near-black is a mirror in a lit room — in daylight the screen reflects you back more than it shows text. `#242424` is about 2.3× the luminance, enough to kill the reflection, and every slot still clears the 3:1 floor.

Neovim is the only thing downstream that carries a palette of its own, and it carries the same one. Everything else resolves through the slots: `bat` and delta run `syntax-theme = ansi`, starship styles by ANSI name and zsh-syntax-highlighting by ANSI slot number, `psql` writes the raw SGR slots, and herdr uses its built-in `terminal` theme, which draws its chrome from the same sixteen. A bundled-theme update moves all of those together.

The sixteen values in `ghostty/config` are [`jellybeans.nvim`](https://github.com/wtfox/jellybeans.nvim)'s own `extras/ghostty` theme, and Neovim runs the same colorscheme through the plugin itself — so the two agree by construction rather than by hand. Neovim does not inherit the terminal slots because a colorscheme addresses far more groups than sixteen.

Two slots are changed from upstream, both for the same reason: they are *darker* than their non-bright counterparts and land below the 3:1 floor.

| Slot | Upstream | Ratio | Here | Ratio |
|---|---|---|---|---|
| 9 `brred` | `#902020` | 2.10:1 | `#e06060` | 5.23:1 |
| 13 `brmagenta` | `#700089` | 1.78:1 | `#d8ccf5` | 12.07:1 |

The same colour appears once more inside Neovim: jellybeans' `old_brick` is that same `#902020` and is what paints neo-tree's deleted and conflict markers, so `nvim/init.lua` relights it through `on_colors` to the identical `#e06060`. One value, one reason, both places.

With that, **every slot this stack actually paints clears 3:1** — the tightest is slot 1 at 3.57:1. Slot 0 stays at `#151515`: it is ANSI black, drawn by programs that ask for black, and now that the background is no longer the same value it stays visible against it. Slot 8 (`#888888`) is the one that used to cost something under the previous theme — comments, autosuggestions, completion descriptions and starship's time all use it — and it sits at 4.38:1 rather than under the floor.

`selection-background` tracks the background rather than being fixed: `#404040` read as a selection against `#151515` at 1.76:1 and would have fallen to 1.50:1 here, so it moved to `#4a4a4a` and is back at 1.75:1.

The one deliberate exception is inside Neovim and not in the sixteen: the indent markers, Telescope's borders and `Pmenu` all sit at `#3e3e3e` (1.45:1). They are structure, not text.

That value is not jellybeans' own. Neovim runs `transparent = true`, so the terminal background shows through and the colorscheme's near-background greys — the selected row, Telescope's prompt fill, the borders — were all picked as a distance above `#151515` and end up *darker* than `#242424`, inverting instead of shifting. `nvim/init.lua` relights the four of them through `on_colors` to the values that reproduce their original ratios. Holding the ratio is the point; the hex is not.

`background-opacity` is `0.97` and no lower: any opacity pulls every ratio above down by whatever shows through, and the blur is what keeps that predictable instead of dependent on the window behind.

## Managed files

| Repo | Destination |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/completions/_aws` | `~/.config/zsh/completions/_aws` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ghostty/config` | `~/.config/ghostty/config` |
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
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` follows **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`. Claude does not: the terminal always runs the personal account, and the work one is only ever used from the web.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **`$PATH` is assembled twice, on purpose.** `.zshenv` runs before `/etc/zprofile`, which calls `path_helper` and pushes `/usr/bin` back in front of everything — so `zshrc` calls `__path_setup` again. `typeset -U path` is what makes the second call reorder instead of duplicate. Delete either half and a system runtime shadows the mise-pinned one.
- **`zsh-syntax-highlighting` is sourced on the last line of `zshrc`, and has to be.** It wraps the widgets that exist when it loads; `fzf-history-down` and fzf's own widgets are defined just above it. Move the `source` up and they stop being highlighted.
- **`down` is not bound straight to `fzf-history-widget`.** `fzf-history-down` checks whether the cursor still has lines below it first — bind the widget directly and multi-line editing loses its cursor movement.
- **Homebrew ships no zsh auto-activation for mise.** fish got one from `vendor_conf.d`; zsh needs the explicit `eval "$(mise activate zsh)"` in `zshrc`. Drop it and every runtime falls back to whatever is on `$PATH`.
- **`down` is a four-way branch, not a plain fzf binding.** `fzf-history-down` has to check search mode, the pager and the cursor line before opening the widget — bind `down` straight to `fzf-history-widget` and Tab-completion arrow navigation and multi-line editing both stop working.
- **Neovim formatting is strict and runs before every write.** A missing formatter or invalid source aborts the write; `:noautocmd write` is the deliberate escape hatch.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **`font-jetbrains-mono-nerd-font`, not `font-jetbrains-mono`.** The plain cask carries no Nerd Font glyphs, which is what the eza icon column and starship need. The cask installs three families whose names differ by one word — `Mono`, `Propo` and `NL` — and only `JetBrainsMono Nerd Font Mono` keeps the icon column aligned. `ghostty/config` names it in full, and a family Ghostty cannot find falls back silently — `ll` showing boxes instead of icons is what tells you the name was wrong.
- **`shell-integration-features` carries `ssh-env,ssh-terminfo`, and they are not optional.** Ghostty sets `TERM=xterm-ghostty`, an entry almost no remote host has; without those two the variable travels over ssh and breaks `clear`, `less` and nvim there.
- **The bell is a notification now, not a Dock bounce.** `bell-features = system,attention,title` is what turns the `\a` from `zsh/zshrc` into one. macOS asks for notification permission the first time — deny it and long commands finish silently. Verified against Ghostty 1.3.1 with `ghostty +validate-config`; an older build that does not know the key ignores it and only logs a warning, and the bell then does nothing.
- **lualine's mode section is transparent, and that needs the colour moved.** jellybeans paints it as near-black text on a coloured chip; `nvim/init.lua` drops every section background to `NONE`, and dropping the chip alone would leave `#000000` on `#242424`. The chip's colour is promoted to the text colour instead, so each mode still reads as its own — blue, green, amber, lilac.
- **Neovim forces `termguicolors` instead of autodetecting.** Ghostty exports `COLORTERM=truecolor` and honours 24-bit colour, but that variable does not survive every ssh — forcing it keeps the colourscheme instead of dropping to sixteen slots silently.

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
