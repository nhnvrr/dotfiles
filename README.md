# dotfiles

macOS dotfiles and bootstrap script for terminal, editor, and shell setup.

## Prerequisites

You need Apple's command-line developer tools (provides `git`, `make`, `clang`, etc.) before running `install.sh`:

```bash
xcode-select --install
```

That's the only thing the script does **not** do for you.

## Quick start

```bash
git clone git@github.com:nhnvrr/dotfiles.git ~/Develop/dotfiles
cd ~/Develop/dotfiles
./install.sh
```

The script is idempotent — re-run it anytime to bring a machine back in sync. Run with `--skipBrew` to only re-link config files (skip Homebrew + tool installation):

```bash
./install.sh --skipBrew
```

## What `install.sh` does

- Installs Homebrew (if missing) and applies [`Brewfile`](./Brewfile) via `brew bundle`
- Installs mise-managed runtimes pinned in [`mise/config.toml`](./mise/config.toml) (Node, Bun, Go, AWS CLI, Terraform)
- Symlinks [`git/gitconfig`](./git/gitconfig) to `~/.gitconfig`, plus the global ignore and the allowed-signers file it references
- Generates an `ed25519` SSH key if missing, registers it with the macOS Keychain via `~/.ssh/config`, and copies the pubkey to the clipboard for GitHub
- Symlinks all config files into `$HOME` (see [Managed files](#managed-files))
- Applies a small set of macOS defaults (fast key-repeat, no press-and-hold, Finder show extensions, screenshots into `~/Screenshots`). The Dock is deliberately left alone — it's a visual preference, set it from System Settings
- Switches the login shell to Homebrew's `fish` (uses `dscl` to read the real login shell, not `$SHELL`), registering it in `/etc/shells` first if needed. If `fish` isn't installed yet — `--skipBrew` on a fresh machine — it says so and leaves the login shell alone rather than pointing it at a binary that doesn't exist
- Removes the stale `~/.zshrc` / `~/.zprofile` symlinks left by the previous zsh setup (only if they point into this repo) along with its `~/.cache/zsh/init.zsh`, plus the dangling `~/.zshenv` / `~/.bashrc` / `~/.bash_profile` / `~/.profile` links into a `/nix/store` that no longer exists

The `link_file` helper backs up any pre-existing regular file at the destination to `<dst>.bak.<timestamp>` before replacing it with a symlink — your hand-edited configs won't disappear silently.

## First run on a fresh Mac

After `install.sh` exits cleanly:

1. **Paste the SSH pubkey on GitHub** — it's already on your clipboard. Add it at <https://github.com/settings/ssh/new> as both an authentication key AND a signing key (so your signed commits show up as Verified).
2. **Authenticate the GitHub CLI:** `gh auth login` (script reminds you if not authenticated).
3. **Grant Accessibility permission to Hammerspoon** on first launch (System Settings → Privacy & Security → Accessibility). Required for window management hotkeys.
4. **Set Helium as the default browser** — System Settings → Desktop & Dock → Default web browser. macOS exposes no supported `defaults write` for the `http`/`https` handler; scripting it would mean adding `duti` for a one-time click.
5. **Open Alacritty.** Nothing to set up: font, size and the Alt key come from [`alacritty/alacritty.toml`](./alacritty/alacritty.toml), which is already symlinked, and the login shell is fish by then. The sixteen ANSI slots do **not** live in that file — `install.sh` runs `theme` at the end, which deploys one of the six palettes to the `theme.toml` it imports, gruvbox dark on a machine that has none yet. Switch with `theme one light` or `theme toggle`; see the Theme row below. It opens edge to edge — that is `startup_mode`, not something macOS remembered.

Note: the script prompts for your password once, for `chsh`.

## Tooling

| Layer | Tool | Config file |
|---|---|---|
| Shell | fish (Homebrew's, `/opt/homebrew/bin/fish`) | [`fish/config.fish`](./fish/config.fish), [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Alacritty, replacing Ghostty — which replaced Terminal.app, which had replaced Ghostty. What ended the cycle was herdr becoming the only multiplexer: that leaves the emulator one job, and Ghostty's tabs, splits, quick terminal and shell integration were all things nothing used any more. **It is not the faster of the two** — both are GPU and Ghostty wins on features. What Alacritty buys is that it doesn't compete: it has no splits, its tabs are vestigial, and every one of its macOS defaults is a `Command` binding, so herdr keeps `ctrl+b` and fish keeps its `ctrl+<letter>` without negotiating. `TERM=alacritty` is missing from the system terminfo exactly like `xterm-ghostty` was, but here `install.sh` needs no step at all: the cask declares `~/.terminfo/61/alacritty` as one of its own artifacts, so `brew bundle` symlinks it out of the bundle. **What it cost**, all three worth knowing before you hit them: there is no shell integration, so `TERM` surviving `sudo` rests on the sudoers keeping `HOME` rather than on the terminal re-exporting `TERMINFO`; there is no `adjust-icon-height`, so Nerd Font icons draw at native size and read slightly small against the text; and the bell is a visual flash only — no Dock attention, no title marker — which is why `[ui.toast]` in herdr matters more now | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) |
| Agents | herdr — a second multiplexer, which needs justifying next to tmux. tmux multiplexes *shells* and knows nothing about what runs in them; herdr reads semantic state off the agent CLIs over a socket API, so the sidebar says which agent is waiting on input and which is still working. That is the thing tmux cannot do, and it is the only reason it's here. It used to run **inside** a tmux pane; it now runs on its own. The prefix is `ctrl+q`, and the reasoning changed with it: the `ctrl+b` default was originally out because it is tmux's, but with nvim living in herdr panes rather than tmux ones it is also nvim's page-up, which is worse to lose than the insert-mode completion prefix `ctrl+x` had cost. `ctrl+q` is the one `ctrl+<letter>` fish leaves unbound — `stty -ixon` already freed it from flow control — and in nvim it is only an alias of `CTRL-V`. Being neither tmux's nor nvim's, it also survives being nested, where a `ctrl+b` prefix would need pressing twice. What the nesting bought was a single owner of sessions, CWD and `AWS_PROFILE`; that routing now falls back to `$HERDR_WORKSPACE_ID` when `$TMUX` is absent, so both layouts work — see `__ctx` in [`fish/config.fish`](./fish/config.fish). `remote_image_paste` is left at the stock `ctrl+v`: it only binds under `herdr --remote`, so fish keeps the key locally. Not started as a `brew services` daemon: launched on demand, so nothing survives a reboot that you didn't ask to | [`herdr/config.toml`](./herdr/config.toml) |
| Editor | **Neovim**, the daily driver — see the row below for what it can do. It is also still `$EDITOR`, so commits and `git rebase -i` open it | [`nvim/`](./nvim) |
| Remote work | VS Code (`e` = `code --new-window`), kept for exactly one job: Remote-SSH, the AWS Toolkit and SSM sessions against EC2. That is the piece the terminal setup genuinely doesn't cover, and it's why the cask is still declared. It's also what Hammerspoon's `cmd+alt+1` pairs with Helium. Its config is user-level, not versioned here | — |
| Neovim | Built for **TypeScript, Rust and Go**, the three languages this machine actually runs. It stopped being one file: the config is modules under `nvim/lua/config/`, namespaced because bare names collide — Lua preloads `debug`, so `require("debug")` returns the stdlib table and silently never loads your file. Still no `nvim-lspconfig`; the servers are `vim.lsp.config` written out, with `'*'` seeding blink's capabilities into all of them. **Servers**: `vtsls` (TS/JS), `gopls`, `eslint` and `jsonls` (both out of `vscode-langservers-extracted`), `yamlls`, and rust-analyzer — the last one owned by `rustaceanvim` and deliberately *not* in `vim.lsp.enable`, since doing both starts two clients on one buffer. TypeScript highlighting belongs exclusively to Tree-sitter: vtsls' semantic-token layer is disabled because it repainted an already-coloured buffer only after loading the whole project; this does not disable types, completion, navigation, diagnostics or inlay hints. **Completion** is `blink.cmp`, pinned to a `1.*` tag rather than `main` because its Rust fuzzy matcher ships as a prebuilt binary on tagged releases only; track main and it quietly falls back to the slower Lua one. **Formatting** is `conform.nvim` — prettier for the JS/JSON/YAML side with `require_cwd = true`, so it *skips* rather than reformatting repos that never asked for it; `rustfmt` for Rust; and for Go, gopls itself (already `gofumpt = true`) plus a `source.organizeImports` code action on save, which is the half gopls doesn't do and the reason no `goimports` binary is needed. eslint fixes on save through a **synchronous** `eslint.applyAllFixes` — the async `code_action` path returns before the edits land and the buffer gets written unfixed. **Debugging** is `nvim-dap` on an adjacent Ctrl row (`C-8` continue, `C-9` over, `C-0` into, `C-S-0` out): `dlv` for Go from the Brewfile, `codelldb` for Rust which rustaceanvim finds on its own, and `js-debug` for Node — where a `.ts` entrypoint runs directly, because Node 24 strips types natively. Those last two are the only reason `mason.nvim` is here; every language server still comes from the Brewfile. **JSON and YAML** get their schemas from `SchemaStore.nvim`, with yamlls' own store switched off so the two don't fight over the same file, and `keyOrdering = false` because it defaults to flagging every key that isn't alphabetical — which is every `serverless.yml` ever written. Navigation still splits in two: LSP crosses files (`gd`, `gD`, plus Neovim's own `grr` `gri` `grn` `gra` `grt`), treesitter moves inside the open one (`]f` `[f`, `]c` `[c`, `vaf`/`vif`). Inlay hints are on wherever a server offers them, `<leader>li` toggles | [`nvim/`](./nvim) |
| Browser | Helium — Chromium with the Google service dependencies stripped out, replacing Chrome. Nothing about it is versioned and nothing can be: its settings live in a Chromium `Preferences` JSON that the browser rewrites on quit, which is the same failure mode that killed the Terminal.app profile. It is also the app Hammerspoon tiles against, so its bundle ID `net.imput.helium` is load-bearing in [`hammerspoon/init.lua`](./hammerspoon/init.lua) — and being a Chromium, it still refuses to go narrower than its own minimum width, which is why the tiler measures instead of assuming | — |
| Database | `psql` is what scripts use and the fallback that's always there; `pgcli` is the interactive one — schema-aware completion of table and column names, syntax highlighting, and an editable multi-line buffer, none of which `psql` has. It does **not** read `~/.psqlrc`, so the five shortcuts are duplicated as named queries (`\n` lists them, `\n conns` runs one). TablePlus as the visual complement | [`psql/psqlrc`](./psql/psqlrc), [`pgcli/config`](./pgcli/config) |
| Redis | Same split one layer down: `redis-cli` for scripts, `iredis` for interactive work — completion, highlighting, a multi-line buffer. `redis-cli` is not the interactive one for a reason that is worth writing down: its entire config surface is `~/.redisclirc`, which accepts exactly two directives, `:set hints` and `:set nohints`. There is nothing there to version, so its one tunable setting — where the history goes — is an env var in `conf.d/00-env.fish` instead. `iredis` runs with `shell = False`: left on, anything it doesn't recognise as a Redis command gets handed to the shell, so a typo executes instead of erroring. `decode = utf-8` makes values come back as text, at the cost of genuinely binary values printing as mojibake | [`redis/iredisrc`](./redis/iredisrc) |
| HTTP | `curl` via the `req` function; Bruno for exploratory work | [`fish/config.fish`](./fish/config.fish) |
| Git | versioned config, SSH-signed commits | [`git/gitconfig`](./git/gitconfig) |
| Window mgmt | Hammerspoon — `cmd+alt+1/2/3` tile an app pair at 70/30 and hide everything else, `R` mirrors the split, `F` zooms. It never sleeps a fixed interval: it waits on the condition, because Electron applies `AXSize` and `AXPosition` separately and macOS ignores `setSize` in native fullscreen. Widths are measured, not assumed — the narrow app is placed first and the wide one gets whatever the other's minimum left over. `cmd+\`` show/hides Alacritty — bound globally, so it costs `cmd+\`` its cycle-windows in every other app. **Alacritty is the one app exempt from the launch watcher**, which otherwise reframes every app that opens: it starts in `SimpleFullscreen`, which is bigger than that frame, so the watcher would shrink it a moment after it appeared. `cmd+alt+2` still tiles it, and that is meant to take it out of fullscreen — `cmd+ctrl+f` inside the window puts it back | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |
| Runtime mgr | mise — global versions plus per-project `.nvmrc` | [`mise/config.toml`](./mise/config.toml) |
| Font | MonaspiceAr Nerd Font Mono at size 18 — Monaspace Argon, one font, not a pair. The Nerd Font build carries the Monaspace glyphs *and* every icon, so there is no fallback font to keep in sync and a fresh machine gets the real thing straight from `brew bundle`. It has to be the **Nerd Fonts** patch (cask `font-monaspice-nerd-font`, family prefix `Monaspice`), not GitHub's own `font-monaspace-nf` build: the latter ships no Mono variant, which is the one thing the icon columns need. The `font-feature = -liga, -dlig, -calt` line Ghostty needed is **gone and not replaced**: Alacritty has no font-feature setting because it does no shaping at all, so `calt` — Monaspace's texture healing, which reflows glyph widths mid-line and drifts eza's icon columns, and which `-liga` alone never covered — simply cannot fire. What did need porting is `adjust-cell-height = 6%`, whose equivalent is `font.offset.y`; at this size the cell is 22 logical pixels, so it is `1` | cask `font-monaspice-nerd-font` |
| Theme | **Three families, two halves each**, switched by `theme` — a fish function with two axes: `theme gruvbox` changes family and keeps the mode, `theme light` changes mode and keeps the family, `theme toggle` flips the mode, `theme one dark` sets both, and bare `theme` prints what is live. The families are Solarized (Schoonover), Gruvbox (morhetz) and One (Atom), and the six palettes live in [`alacritty/themes/`](./alacritty/themes) as `<family>-<mode>.toml`. Nord was here before all of them and is gone: it was the only pair whose light half nobody publishes, so it was the only one I had to invent. **The live state is not stored anywhere of its own** — it is the `# theme:` and `# mode:` markers in the deployed `theme.toml`, so there is no second copy to drift. **The sixteen slots are upstream's, unedited**, including the accents that measure under 4.5:1: this is a switch between real palettes, not six variations on one. Measured, body text then worst accent — solarized 4.75/3.25 dark and 4.13/2.93 light, gruvbox 10.75/2.69 and 10.22/3.33, one 6.57/4.38 and 10.86/3.06. Two conclusions worth keeping: **solarized light is the weakest of the six** (4.13:1 body text, under AA, and green/yellow/cyan all near 2.95:1 — it is real Solarized, whose eight accents are the same hexes in both halves, which is the palette's selling point and exactly why they cannot clear 4.5:1 against both ends), and gruvbox and one both hold body text above 10:1 in either mode, which is what to reach for in hard daylight. **Two things per file are not upstream, because they are structural rather than cosmetic.** First, **slot 8**, the one slot with two jobs: dim text (comments in fish and `bat`, autosuggestion, starship, fzf's `info` and `border`) *and* a background (fzf's `bg+`, fish's selection, pgcli's selected row). No palette publishes a value chosen for both, and taken literally several break outright — Solarized's own bright black is `base03`, which **is** the background, 1.00:1. Each file seeds it from the family's own grey and, where that grey fails, walks lightness to the crossover of the two roles holding hue and saturation: solarized `base00` serves both halves unmodified (3.37:1 and 4.13:1), gruvbox light's `gray` too (3.24/4.02), and the other four are moved, landing between 3.26 and 3.92:1 either way. Second, **the four chrome tables** — Alacritty's own UI reads none of the sixteen slots and paints the search bar, hint labels and footer in a stock base16 without `[colors.search]`, `[colors.hints]` and `[colors.footer_bar]`. The block stays the family's own accent and the readable one of the pair goes on top, which lands on a dark tone for the light halves and a light one for the dark ones; a few mid-tone accents cannot reach 4.5:1 against either end and are commented as such where they sit. **The colours are in the imported file and never in [`alacritty/alacritty.toml`](./alacritty/alacritty.toml)**, which is the trap worth naming twice: imports load first and the importing file loads last, and the last one wins, so a single colour table left behind silently overrides all six and the switch looks like it does nothing. `theme.toml` is a copy rather than a symlink for two reasons — the watcher does not fire reliably on a repointed link, and a link into the repo would have every switch writing in the working tree. **What follows the sixteen slots for free**, because nothing in them hardcodes a hex: starship, eza, fzf, pgcli's `[colors]`, `bat` via `BAT_THEME=ansi` and delta via `syntax-theme = ansi`. Four things need a hand, each for a different reason. **btop** keeps its own hex, so its theme is *generated*: [`btop/themes/template.theme`](./btop/themes/template.theme) carries the design once and `theme` substitutes the slots of whichever palette is live into `~/.config/btop/themes/current.theme`, the bare name `btop.conf` asks for. One template instead of six near-copies, since the mapping is fixed and only the hexes move; `theme` fails loudly if a placeholder survives, because an unresolved one makes btop fall back to its own theme silently, which reads as "the switch did nothing". btop ships themes for all three families and **none are used**, for the same reason its bundled `nord` was rejected: all eight of its meters share one blue-to-white ramp, so temperature, load, memory and network paint identically — the per-meter ramps are the whole point, and anything meaning "more is worse" ends on red while the merely informational meters stay flat. **pgcli**'s `syntax_style` is a pygments style name resolved inside Python rather than a path, so there is no symlink to repoint and the deployed config is a derived copy — the cost is that editing [`pgcli/config`](./pgcli/config) needs a `theme` run to land. pygments ships five of the six (`solarized-dark`, `solarized-light`, `gruvbox-dark`, `gruvbox-light`, `one-dark`); **`one-light` does not exist**, and its slot uses `default`, the most legible light style measured against One Light's background at 4.14:1 on its worst token against 3.90 for `sas` and 3.41 for `perldoc`. It is a substitute and is commented as one. **herdr** ships native themes for all three families and both halves of each, which are more faithful than deriving its chrome from the sixteen slots would be, so [`herdr/config.toml`](./herdr/config.toml) names one outright and `theme` rewrites that `name` on every switch, then calls `herdr server reload-config`, which applies without restarting anything; it is the second derived copy for the same reason as pgcli. **`auto_switch` is deliberately off**, which is the opposite of how this started and worth writing down: it has herdr pick the half by asking the terminal for its background, the same mechanism nvim uses, and it did not follow — so the half had to be changed by hand in herdr's UI, and *that* is the part that bites. Changing it there makes herdr write its choice back into the config as `name` and set `auto_switch = false` itself, after which the `dark_name`/`light_name` pair it had been choosing between is ignored and herdr is pinned for good, immune to the switch. Writing the resolved name outright has nothing to detect and nothing to lose a race with; and because the deployed file is regenerated from the repo on every switch rather than patched in place, anything herdr persisted there is discarded rather than fought with. `[ui] accent` is the ANSI name `cyan` rather than a hex, which is herdr's own default for that key and serves all six. **nvim** needs one plugin per family, because none carries all three: `maxmx03/solarized.nvim`, `ellisonleao/gruvbox.nvim` and `olimorris/onedarkpro.nvim`. The **mode** needs no telling — Neovim's TUI asks the terminal for its background on startup and sets `'background'` itself (`:h 'background'`), which is what makes the terminal the single source of truth and is the thing an earlier hardcoded `vim.o.background = "dark"` was quietly defeating. The **family** cannot be detected that way, so it is read from the `# theme:` marker in the deployed theme. The colorscheme is re-picked on **two** hooks, not one: `OptionSet` does not fire during startup at all (`:h OptionSet`), which is precisely when the terminal's reply usually lands, so `VimEnter` covers that window, and the apply is keyed on family-and-mode rather than on `g:colors_name` — solarized and gruvbox use one colorscheme name for both halves, so comparing names alone would skip the reload that actually repaints. Transparency is on in all three so the terminal's background shows through and nvim never paints one; each plugin names that option differently, which is the only reason those three setup blocks cannot be collapsed. Bold is off, and the `ColorScheme` autocmd that repaints NeoTree reads **generic** group names (`Directory`, `Normal`, `Comment`) rather than any theme's own — which is what has let it survive every colorscheme change here untouched, including this one. lualine's theme is built per family and mode rather than left on its `"auto"`, because the loop that strips the bold out of the mode block needs a real table; it is rebuilt on `ColorScheme`, re-passing the whole config and not just `options`, since `setup()` merges with lualine's defaults and options alone would wipe the sections. That leaves exactly one hold-out: `iredis`, which has no colour section at all and paints from pygments' default — a light-background style, so it is the one thing in the stack that reads better in the light halves. GUI editors keep their own user-level theme | [`alacritty/themes/`](./alacritty/themes), [`fish/functions/theme.fish`](./fish/functions/theme.fish) |
| History | fish's native history (`~/.local/share/fish/fish_history`), searched with fzf on ↓ — the arrow walks the history while there is something below and opens fzf once there is not, seeded with whatever is on the line. Ctrl-R is fish's own history pager | [`fish/config.fish`](./fish/config.fish) |
| Fuzzy find | fzf on ↓ (history), Ctrl-T (files, `bat` preview), Alt-C (directories) and `**<TAB>` (completion). zoxide also shells out to it for `zi` | [`fish/config.fish`](./fish/config.fish) |
| Listings | eza with icons — `ls`, `ll`, `la`, `lt`, themed by ANSI name (folders cyan, metadata grey, git matching the prompt). Needs the Nerd Font's **Mono** (NFM) variant, where a glyph is exactly one cell wide; the Propo variant drifts the columns. `EZA_CONFIG_DIR` is mandatory: on macOS eza reads `~/Library/Application Support/eza` and ignores `XDG_CONFIG_HOME` | [`eza/theme.yml`](./eza/theme.yml), [`fish/config.fish`](./fish/config.fish) |

`fish/config.fish` notes:
- Defines `dev` / `work` / `side` aliases that focus (or create) a fixed herdr workspace with a fixed CWD. They focus **by label, not by number** — workspace numbers shift as workspaces are closed, and the label is the routing key `__ctx` reads back.
- Resolves the enclosing context once, in `__ctx`: the herdr workspace label, read back over the socket API from `$HERDR_WORKSPACE_ID`. Both `AWS_PROFILE` and the `claude` wrapper route off it. Outside herdr it returns empty, which is the `personal` path.
- Always exports an explicit `AWS_PROFILE` — `work` in the `work` context, `personal` everywhere else. `~/.aws/config` has no `[default]` profile, so leaving it unset means every `aws` command fails with `NoCredentials`; setting it always also means Starship's `aws` module always draws, which is how you see which account you're pointed at.
- Provides `req` — curl with sane flags, piping the response through `jq` when it parses as JSON. There is deliberately no `~/.curlrc`: that file is read by *every* curl invocation, including the Homebrew installer's and any third-party script's.
- Wraps `claude` so that `CLAUDE_CONFIG_DIR=~/.claude-work` is used in the `work` context, letting two Claude Code subscriptions stay logged in side-by-side.
- Feeds Starship two env vars from a single `fish_prompt` event handler, both builtins-only so the prompt pays no forks: `STARSHIP_DOCKER_CTX` (read out of `~/.docker/config.json` — `docker context inspect` is 126ms of Go CLI startup to print what's already on disk) and `STARSHIP_PNPM` (walks up from `$PWD` to `$HOME` looking for `pnpm-lock.yaml`).
- Binds everything custom inside `fish_user_key_bindings`, fzf's `Ctrl-T`/`Alt-C` included. fish re-applies the preset bindings whenever `$fish_key_bindings` changes and calls that function afterwards, so anything bound outside it is silently dropped.
- Ships its own `completions/aws.fish` instead of registering `aws_completer` from `config.fish`. `complete -c aws` *adds* a source, so the old rule merged with the `aws.fish` fish 4 compiles into its binary and kept offering services awscli dropped years ago. Only the first match in `$fish_complete_path` is autoloaded, so a file in `~/.config/fish/completions` is what actually replaces it. Shadowing that table costs its live `s3://` bucket and key completion, so those helpers are ported into the file. `aws_completer` emits bare names, so the descriptions are joined in from the botocore models bundled with awscli — keyed on the name with dashes and case dropped, because botocore's own `xform_name` turns `ListHITs` into `list-hi-ts` and not the `list-hits` the CLI takes. jq over those models is ~600ms for a big service and ~1s for the full service list, so both tables are cached under `~/.cache/fish/aws-completions/` and rebuilt when the model directory outdates them, which an awscli upgrade guarantees.
- Uses **hybrid emacs + vi** bindings (`fish_hybrid_key_bindings`) — emacs keys with vi mode on Esc. The other direction needs a long escape timeout, which delays every `Alt-<key>` too, because the terminal sends those as `ESC`+key (Alacritty's `option_as_alt = "Both"`).
- Caches `zoxide init` / `fzf --fish` / `starship init` into `~/.cache/fish/init.fish`, regenerated when `config.fish` or any Homebrew binary changes. mise is deliberately **not** cached — nor activated at all: Homebrew ships `vendor_conf.d/mise-activate.fish` and fish sources it on its own. Doing it twice costs ~20ms per shell.
- Turns on Starship's `enable_transience`, so an executed prompt collapses to a bare `❯` plus the clock.

`fish/conf.d/00-env.fish` is separate from `config.fish` for one reason: **ordering**. fish sources every `conf.d` snippet — vendor ones included — sorted by name, and `config.fish` only after all of them. mise's snippet prepends its installs to whatever `$PATH` it finds, so the repo's `$PATH` has to be set before it (`00-` sorts before `mise-`) or a stray `~/.bun/bin` shadows the mise-pinned runtime. It's the same ordering the old `zprofile` → `zshrc` pair had.

### Why fish

It was already the shell here twice; what sank it the last time was **Tide**, whose config lives in universal variables that can't be versioned — `install.sh` had to seed them and `config.fish` had to shadow them with `set -g`. Pairing fish with Starship instead makes that whole class of problem disappear: `starship/starship.toml` is the same file zsh used, unchanged.

What zsh needed hand-rolled, fish has natively: `abbr` (~20 lines of ZLE), hybrid bindings, per-mode cursors, prefix history search, `$CMD_DURATION`, autosuggestions and syntax highlighting (two Homebrew formulae fewer), plus `compinit` disappearing entirely. What it costs is one Homebrew formula and a `chsh` — a login shell that lives outside `/bin`, so `/bin/zsh` is still the fallback if a brew upgrade ever breaks it.

Startup is ~40ms per shell warm (measured end-to-end with `/usr/bin/time -p /opt/homebrew/bin/fish -l -i -c exit`, not with a profiler that skips process spawn), against zsh's ~60ms warm on the same box. The first shell after a config change pays ~200ms to rebuild the init cache, once.

| Cost | Fix |
|---|---|
| `eval "$(brew shellenv)"` — 2 forks, ~20ms | inlined as constants in `conf.d/00-env.fish` |
| `zoxide`/`fzf`/`starship` init — ~12ms | cached in `~/.cache/fish/init.fish` |
| `mise activate` — ~17ms | unavoidable; fish's vendor snippet does it once, and we don't repeat it |

The prompt itself costs ~40-50ms per keypress in a large repo, because fish evaluates `fish_prompt` and `fish_right_prompt` separately and each spawns `starship`. Dropping the right prompt would halve it.

## Homebrew packages

All formulae, casks, and fonts are declared in [`Brewfile`](./Brewfile). To inspect or update:

```bash
brew bundle check --file=./Brewfile     # report what's missing
brew bundle --file=./Brewfile           # install missing items
brew bundle cleanup --file=./Brewfile   # uninstall what's not in the Brewfile
```

## Managed files

These are symlinked from the repo into `$HOME`:

| Repo path | Destination |
|---|---|
| `alacritty/alacritty.toml` | `~/.config/alacritty/alacritty.toml` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `fish/conf.d/00-env.fish` | `~/.config/fish/conf.d/00-env.fish` |
| `fish/completions/aws.fish` | `~/.config/fish/completions/aws.fish` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `eza/theme.yml` | `~/.config/eza/theme.yml` |
| `nvim/` (whole directory) | `~/.config/nvim` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `pgcli/config` | `~/.config/pgcli/config` |
| `redis/iredisrc` | `~/.iredisrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Only herdr's `config.toml` is in that table, not its directory: herdr keeps its sockets, logs, `session.json` and installed plugins alongside it in `~/.config/herdr/`, and none of that is config.

The Neovim config is symlinked as a **directory**, not file by file, so a new module under `nvim/lua/config/` needs no `install.sh` change and edits inside `~/.config/nvim` land directly in the repo. One consequence is deliberate: `vim.pack` writes `nvim-pack-lock.json` there, so plugin revisions get versioned and `:PackUpdate` leaves the repo dirty — the same trade as `~/.gitconfig` being a symlink.

Because `~/.gitconfig` is a symlink, any `git config --global …` you run writes straight into `git/gitconfig` in this repo. That's deliberate — the change gets versioned instead of drifting in `$HOME` — but it does mean the repo shows as dirty after you touch git config.

`~/.config/fish/functions` and `fish_variables` are deliberately **not** versioned: fish writes into them itself. `completions/` holds one symlinked file, `aws.fish`, because shadowing fish's built-in table is the only way to replace it — everything else fish drops in there stays local state.

## What is NOT managed

- **Database credentials** — `~/.pgpass` holds them so `psql` doesn't prompt. It is a secrets file and is **never** versioned. `pgcli` runs with `keyring = False` so it reads the same file instead of caching passwords into the macOS Keychain on its own. Create it by hand, one connection per line, and lock it down or Postgres refuses to read it:

  ```
  hostname:port:database:username:password     # * works as a wildcard
  chmod 600 ~/.pgpass
  ```

- **VS Code** — config (`settings.json`, keybindings, theme) is user-level and not versioned here; Settings Sync lives elsewhere.
- **`~/.aws/config`** — this repo is public, and while account IDs and SSO instance URLs are not credentials, they are reconnaissance material. [`aws/config.example`](./aws/config.example) is the sanitised template; copy it, fill in the placeholders, and leave the result in `$HOME`. It deliberately defines no `[default]` profile: without one, every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. That is also why the behaviour settings (`AWS_PAGER`, retries) are env vars in `fish/conf.d/00-env.fish` rather than a `[default]` section — writing them there would create the very profile whose absence is the safety net.

- **Helium** — its settings live in a Chromium `Preferences` JSON that the browser rewrites on quit, so it can't be a symlink into the repo, exactly like the Terminal.app plist before it. Only the cask is declared.
- **`~/.claude/`** (and the optional `~/.claude-work/`) — Claude Code config is user-level state, not versioned. Bootstrap a work account with `CLAUDE_CONFIG_DIR=~/.claude-work claude` then `/login`.

## Notes

- Supports macOS only.
- The script prompts for your password once, for `chsh` (switching the login shell).
- `~/.cache/fish/init.fish` is generated state, not config. Delete it and the next shell rebuilds it.
- Rollback: the zsh setup is still in git history — `git show b71d626:zsh/zshrc` and `git show b71d626:zsh/zprofile`, plus `chsh -s /bin/zsh`.
- Designed to be safe to rerun: every step either no-ops or moves existing state aside before replacing it.
