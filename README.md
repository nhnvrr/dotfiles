# dotfiles

macOS. zsh + Starship in Alacritty, Hammerspoon for window tiling, herdr for agents, Neovim, VS Code, Kanso Ink.

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
3. **Set Helium as the default browser** — System Settings → Desktop & Dock.
4. **Launch Alacritty once** — font, palette, window mode and `option_as_alt` all come from [`alacritty/alacritty.toml`](./alacritty/alacritty.toml), so there is nothing to click. It opens covering the whole screen, menu bar included, with no titlebar.

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
| Browser | Helium — the default handler. Chrome stays installed for the Claude in Chrome extension, which only ships through the Chrome Web Store | — user-level |
| Database | `psql` for scripts, a GUI client for interactive | [`psql/psqlrc`](./psql/psqlrc) |
| Redis | `redis-cli` | — history path in [`zsh/zshenv`](./zsh/zshenv) |
| HTTP | `curl` via `req`; Postman and Bruno for exploratory work | [`zsh/zshrc`](./zsh/zshrc) |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Fuzzy find | fzf + fd + bat | [`zsh/zshrc`](./zsh/zshrc) |
| Listings | eza — `ls`, `ll`, `la`, `lt`, with icons and per-file git status | [`eza/theme.yml`](./eza/theme.yml), [`zsh/zshrc`](./zsh/zshrc) |
| Monitoring | btop — `color_theme = "TTY"`, so it follows the terminal's sixteen slots | [`btop/btop.conf`](./btop/btop.conf) |
| Clipboard | Maccy | [`Brewfile`](./Brewfile) |
| Window tiling | Hammerspoon — right pane the browser, left pane on `cmd+alt+1/2/3` | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |

Neovim has no plugin manager: the handful of plugins it does use — the [`kanso.nvim`](https://github.com/webhooked/kanso.nvim) colorscheme, neo-tree and Telescope with their dependencies — are added through Neovim 0.12's own `vim.pack`. `Space-f` then `f`/`g`/`b`/`h`/`r`/`d` opens Telescope on files, a project-wide grep, buffers, help tags, recent files and diagnostics, and `Space-/` searches the current buffer; `telescope-fzf-native` is compiled on install so the matching ranks the same way as the shell's `Ctrl-T`. Its native LSP client provides automatic completion and diagnostics for TypeScript, Go, Rust, Bash, YAML and JSON; `Tab`/`Shift-Tab` select, `Enter` accepts, and `Ctrl-Space` triggers completion manually. Every write runs exactly one formatter: Prettier for TypeScript/YAML/JSON, gofumpt for Go, rustfmt for Rust, and shfmt for Bash. `Space-f` formats without writing and `gd` jumps to a definition. `Space-sv` and `Space-sh` split the window, `Ctrl-hjkl` moves between splits, and each language adds its own: `Space-co`/`cm`/`cu` for TypeScript imports, `Space-cc`/`ck`/`ct`/`cr` for cargo, and `Space-cp`/`cm`/`cs` to pretty-print, minify or sort a JSON buffer through `jq`.

The rest of the editing layer is builtin and costs nothing at startup: `inccommand = "split"` previews `:s` live against every line it would touch, `Esc` clears the search highlight, `Ctrl-d`/`Ctrl-u`/`n`/`N` centre on landing, `J`/`K` move a visual selection and reindent it, `<`/`>` keep the selection, `p` over a selection pastes without clobbering the register, `Shift-h`/`Shift-l` walk buffers, `Ctrl-<arrows>` resize splits, a yank flashes, and a reopened file lands where it was left.

Keys split by modifier: Alacritty takes `cmd`, zsh takes bare `ctrl`, and inside a herdr pane `ctrl+b` is the prefix before any of it.

Typing `?` and a space expands to `ask ""` with the cursor between the quotes — a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. The abbreviation exists so the question lands inside quotes; typed bare, `? why is 5 > 3` would be a redirection and zsh would write a file named `3`.

## Theme

**[Kanso Ink](https://github.com/webhooked/kanso.nvim).** [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) carries the palette slot by slot, so the terminal owns the sixteen slots and everything downstream follows them for free: `bat` and delta run `syntax-theme = ansi`, starship styles by ANSI name, zsh-syntax-highlighting by ANSI slot number, `psql` writes the raw SGR slots, `eza` styles by ANSI name, and `btop` runs `color_theme = "TTY"`. None of them carries a colour of its own.

Two things restate the palette as hex, and both have to. Neovim runs [`kanso.nvim`](https://github.com/webhooked/kanso.nvim) because a colorscheme addresses far more groups than sixteen; herdr's theme tokens accept no ANSI reference, so [`herdr/config.toml`](./herdr/config.toml) writes them out under `[theme.custom]`, using the theme's own `bg0`–`bg4` ramp for its surfaces.

**The palette is verbatim, and that is the reason it is here.** The two themes this replaced both repeat the normal colours in the bright half, which collapses three distinctions [`zsh/zshrc`](./zsh/zshrc) draws on — `command` against `reserved-word`, `default` against `--option`, `redirection` against `commandseparator` — and each needed eight slots relit by hand to survive. Kanso Ink gives all sixteen genuinely different values, so nothing is hand-tuned.

Neovim needs no override either. The theme's `bg0` is `#14171d`, exactly what the terminal paints, so with `transparent = true` the surfaces it defines as a distance above the background land where they were designed to. Its `Comment` sits at 4.10:1, above the floor, where the previous two themes both needed lifting.

| | Ratio on `#14171d` |
|---|---|
| body text `#C5C9C7` | 10.73:1 |
| tightest slot — red `#c4746e` | 5.19:1 |
| slot 8 `#A4A7A4` (comments, autosuggestions, dim text) | 7.39:1 |
| selection `#393B44`, text on top | 1.61:1 / 6.67:1 |

The one thing to know: `black` is the background itself, so a program that explicitly asks for ANSI black draws invisibly. That is upstream's choice, kept here; swapping slot 0 for `#1f1f26` is a one-line change if it ever bites.

**Alacritty's cask is deprecated.** Homebrew flagged it in August 2026 for failing the macOS Gatekeeper check and disables it on 2026-09-01. An installed copy keeps working; a fresh machine after that date needs `cargo install alacritty` or the signed build from the project's releases.


## Managed files

| Repo | Destination |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/completions/_aws` | `~/.config/zsh/completions/_aws` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `eza/theme.yml` | `~/.config/eza/theme.yml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `herdr/sounds/done.mp3` | `~/.config/herdr/sounds/done.mp3` |
| `herdr/sounds/request.mp3` | `~/.config/herdr/sounds/request.mp3` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files, with one exception: `~/.config/nvim` is a directory symlink, because the config is `init.lua` plus `lua/config/*.lua` and `require` only resolves those through the runtimepath. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

**Not managed, and why not:** Helium and Chrome both keep their settings in a file the app rewrites on quit, so neither can be a symlink. VS Code and `~/.claude/` are user-level state. `~/.aws/config` and `~/.pgpass` hold reconnaissance material and secrets, and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

The things that will bite you, and nothing else:

- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. That is deliberate — the change gets versioned instead of drifting.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** The Brewfile is the source of truth; an app you want to keep has to be declared — Chrome included, which is no longer the default browser but is still needed.
- **Hammerspoon and Maccy both need Accessibility permission**, granted by hand on first launch. Without it Hammerspoon's placements silently no-op — `init.lua` raises an alert when it detects the permission missing, which is the only reason you find out.
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` follows **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`. Claude does not: the terminal always runs the personal account, and the work one is only ever used from the web.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **`$PATH` is assembled twice, on purpose.** `.zshenv` runs before `/etc/zprofile`, which calls `path_helper` and pushes `/usr/bin` back in front of everything — so `zshrc` calls `__path_setup` again. `typeset -U path` is what makes the second call reorder instead of duplicate. Delete either half and a system runtime shadows the mise-pinned one.
- **`zsh-syntax-highlighting` is sourced on the last line of `zshrc`, and has to be.** It wraps the widgets that exist when it loads, and fzf's own widgets come from the init cache sourced just above it. Move the `source` up and they stop being highlighted.
- **Homebrew ships no zsh auto-activation for mise.** fish got one from `vendor_conf.d`; zsh needs the explicit `eval "$(mise activate zsh)"` in `zshrc`. Drop it and every runtime falls back to whatever is on `$PATH`.
- **The history popup is `Ctrl-R` and nothing else.** Both arrows are bound to `up-line-or-beginning-search` / `down-line-or-beginning-search`, so with a partial command typed they walk only the entries starting with it, and inside a multi-line buffer they still move the cursor between lines. Each arrow is bound twice — `^[[A` is normal mode and `^[OA` application cursor mode, and which one the terminal sends depends on what the last program left it in.
- **Neovim formatting is strict and runs before every write.** A missing formatter or invalid source aborts the write; `:noautocmd write` is the deliberate escape hatch.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **`font-jetbrains-mono-nerd-font`, not `font-jetbrains-mono`.** The plain cask carries no Nerd Font glyphs, which is what the eza icon column and starship need. The cask installs three families whose names differ by one word — `Mono`, `Propo` and `NL` — and only the Mono build keeps the icon column aligned. **The family name is `JetBrainsMono NFM`** — not `JetBrainsMono Nerd Font Mono`, which is what the Nerd Fonts docs and the cask's filenames suggest and what nothing on macOS registers. Check it with `system_profiler SPFontsDataType`; a family CoreText cannot find falls back to Menlo silently, and `ll` showing boxes instead of icons is what tells you the name was wrong.
- **A command taking longer than ten seconds flashes the window.** `_notify_end` in `zshrc` prints a `\a` and `[bell]` turns it into a flash. It is deliberately not a macOS notification: giving `[bell]` a `command` that shells out to `osascript` would reach you behind other windows, at the cost of a popup on every long command — carrying Script Editor's icon, since `osascript` is what posts it.
- **`decorations` and `startup_mode` are read at launch only.** `live_config_reload` picks up colours, font and padding live, but not those two — edit either and Alacritty has to be relaunched before anything changes.
- **`SimpleFullscreen`, not `Fullscreen`.** Native macOS fullscreen covers the menu bar but moves the window to a Space of its own, where `hammerspoon/init.lua` can no longer tile it — `cmd+alt+2` would have nothing to place it beside. `Maximized` keeps the window ordinary but stops below the menu bar. `SimpleFullscreen` is the only mode that does both.
- **`decorations = "none"` removes the drag area too.** `buttonless` only drops the three traffic lights and keeps the titlebar strip with the window title in it. With `none` there is nothing to grab, which is affordable only because the window opens fullscreen and Hammerspoon moves it.
- **`env.TERM` is `xterm-256color`, not `alacritty`.** The entry resolves locally, but `TERM` travels over ssh and almost no remote host has it, which breaks `clear`, `less` and nvim there. The cost is undercurl degrading to a plain underline; truecolor is unaffected, since that is read from `COLORTERM`.
- **lualine's mode section is transparent, and that needs the colour moved.** The theme paints it as near-black text on a coloured chip; `nvim/init.lua` drops every section background to `NONE`, and dropping the chip alone would leave near-black text on the terminal background. The chip's colour is promoted to the text colour instead, so each mode still reads as its own.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```

**The Alacritty cask is on borrowed time.** Homebrew deprecated it in August 2026 for failing the macOS Gatekeeper check and disables it on 2026-09-01. An installed copy keeps working and updating itself; a machine set up after that date will not get one from `brew bundle` and needs `cargo install alacritty` or the signed build from the project's own releases.

## Notes

- macOS only. Prompts for your password once, for `chsh`.
- `~/.cache/zsh/` is generated state — `init.zsh`, the compinit dump and the aws description tables. Delete it and the next shell rebuilds all of it.
- Neovim starts in ~18ms, measured with `nvim --headless --startuptime`. There is no plugin manager and no lazy-loading: the builtin plugins this profile never reaches (netrw above all, since neo-tree replaces it) are switched off at the top of `init.lua`, before `$VIMRUNTIME` is sourced, and the ergonomics layer is entirely builtin, so it costs nothing measurable.
- Shell startup is ~70ms warm, measured end-to-end with `/usr/bin/time -p /bin/zsh -l -i -c exit`. fish did the same in ~40ms; the difference is `compinit` plus the two plugins, and it is the price of the move.
