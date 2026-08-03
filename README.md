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
4. **Open Ghostty** (not Terminal.app) — it picks up `ghostty/config`, the Ghostty Default Style Dark theme, the fonts, and fish as the login shell.

Note: the script prompts for your password once, for `chsh`.

## Tooling

| Layer | Tool | Config file |
|---|---|---|
| Shell | fish (Homebrew's, `/opt/homebrew/bin/fish`) | [`fish/config.fish`](./fish/config.fish), [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Ghostty | [`ghostty/config`](./ghostty/config) |
| Multiplexer | tmux — no plugins, solid green bar, nothing bold and no inverted blocks cutting it up. The hierarchy is `dim`: inactive windows, the separator and the right side are faint, the active window carries a `•` at full strength. Dimming rather than tinting is what makes it survive a theme change — there's no tone to pick that has to keep working against the bar. A bell turns the whole bar yellow and lifts the window that rang out of the dim, `#F`'s `!` naming it; `window-status-bell-style` is forced to `default` because tmux's own default there is `reverse`, which would put back exactly the block this design removes. The prefix underlines the session name, a zoomed pane flags `Z`, and the active pane border is green | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Editor | VS Code (`e` = `code --new-window`) — it's what handles the EC2 work: Remote-SSH, AWS Toolkit and SSM sessions. It's also what Hammerspoon's `cmd+alt+1` layout pairs with Chrome. Its config is user-level, not versioned here | — |
| `$EDITOR` | Neovim — commits, `git rebase -i`, the shell's Ctrl-O, and quick edits. One file, no completion; the plugins are the theme, neo-tree, telescope with the fzf-native C sorter (`<leader>ff` files, `<leader>fs` grep, `<leader>fb` buffers, `<leader>e` tree), treesitter and LSP. Navigation splits in two: LSP crosses files (`gd` definition, `gD` the same where the server has no declaration to give, plus Neovim 0.11's own `grr` `gri` `grn` `gra` `grt`), treesitter moves inside the open one (`]f` `[f` functions, `]c` `[c` classes, `vaf` / `vif` to select). LSP is `vim.lsp.config` written out rather than nvim-lspconfig — two servers is not worth a repo — and attaches by filetype, so a commit message loads none of it and startup there costs 3.7ms more than before it existed | [`nvim/init.lua`](./nvim/init.lua) |
| Database | `psql` is what scripts use and the fallback that's always there; `pgcli` is the interactive one — schema-aware completion of table and column names, syntax highlighting, and an editable multi-line buffer, none of which `psql` has. It does **not** read `~/.psqlrc`, so the five shortcuts are duplicated as named queries (`\n` lists them, `\n conns` runs one). TablePlus as the visual complement | [`psql/psqlrc`](./psql/psqlrc), [`pgcli/config`](./pgcli/config) |
| HTTP | `curl` via the `req` function; Bruno for exploratory work | [`fish/config.fish`](./fish/config.fish) |
| Git | versioned config, SSH-signed commits | [`git/gitconfig`](./git/gitconfig) |
| Window mgmt | Hammerspoon — `cmd+alt+1/2/3` tile an app pair at 70/30 and hide everything else, `R` mirrors the split, `F` zooms. It never sleeps a fixed interval: it waits on the condition, because Electron applies `AXSize` and `AXPosition` separately and macOS ignores `setSize` in native fullscreen. Widths are measured, not assumed — the narrow app is placed first and the wide one gets whatever the other's minimum left over. Plus Raycast (launcher, clipboard, simple windows) | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |
| Runtime mgr | mise — global versions plus per-project `.nvmrc` | [`mise/config.toml`](./mise/config.toml) |
| Font | MonaspiceAr Nerd Font Mono at size 18 — Monaspace Argon, one font, not a pair. The Nerd Font build carries the Monaspace glyphs *and* every icon, so there is no fallback `font-family` line to keep in sync and a fresh machine gets the real thing straight from `brew bundle`. It has to be the **Nerd Fonts** patch (cask `font-monaspice-nerd-font`, family prefix `Monaspice`), not GitHub's own `font-monaspace-nf` build: the latter ships no Mono variant, which is the one thing the icon columns need. Ligatures are off, but `calt` is left **on** — in Monaspace that tag is not ligatures, it's texture healing (substitutions to `.left`/`.right` glyph variants that nudge a glyph inside its own cell without changing cell width). The ligatures are in `liga` and `ss01`-`ss10`, hence `font-feature = -liga, -dlig` | [`ghostty/config`](./ghostty/config), cask `font-monaspice-nerd-font` |
| Theme | Ghostty's own `Ghostty Default Style Dark` — background `#282c34`, foreground `#ffffff`. It's what Ghostty ships as its built-in default, but the `theme` line names it explicitly so the config says what it renders and doesn't drift if that built-in ever changes. One theme, not a `light:`/`dark:` pair: nvim and pgcli are pinned to dark, so following the macOS appearance left the stack half light and half dark. The background is the theme's own and there are no `palette` overrides left: everything that needs a colour asks for it by ANSI name, so the theme is the single source of truth. It runs slightly translucent (`background-opacity = 0.92`) with `background-blur = 20` — the blur is what keeps text readable over a busy desktop. `background-opacity-cells` stays at its default `false`, so only the theme background goes through: anything painting its own cell background (the tmux status bar, selections, nvim's cursorline) stays solid. nvim runs `morhetz/gruvbox` with `g:gruvbox_bold = 0` — emptied rather than toggled, since the theme interpolates that into every group it builds, so it has to be set before the colorscheme loads. It's Vimscript: no `setup()`, no palette table and no transparency option, so the neo-tree and telescope overrides read gruvbox's own `Gruvbox*` groups instead of hardcoding hex, and clear the backgrounds by hand — float included, so telescope and neo-tree don't draw a lighter rectangle inside the terminal. All of it hangs off a `ColorScheme` autocmd so a reload doesn't undo it. Of 913 highlight groups exactly one keeps bold, `@markup.strong`, where the bold is the meaning. Starship, eza, `bat`, delta, fzf, pgcli and tmux all resolve colours through the terminal's ANSI slots, so changing the Ghostty theme moves everything at once. GUI editors keep their own user-level theme | [`ghostty/config`](./ghostty/config) |
| History | fish's native history (`~/.local/share/fish/fish_history`), searched with fzf on ↓ — the arrow walks the history while there is something below and opens fzf once there is not, seeded with whatever is on the line. Ctrl-R is fish's own history pager | [`fish/config.fish`](./fish/config.fish) |
| Fuzzy find | fzf on ↓ (history), Ctrl-T (files, `bat` preview), Alt-C (directories) and `**<TAB>` (completion). zoxide also shells out to it for `zi` | [`fish/config.fish`](./fish/config.fish) |
| Listings | eza with icons — `ls`, `ll`, `la`, `lt`, themed by ANSI name (folders cyan, metadata grey, git matching the prompt). Needs the Nerd Font's **Mono** (NFM) variant, where a glyph is exactly one cell wide; the Propo variant drifts the columns. `EZA_CONFIG_DIR` is mandatory: on macOS eza reads `~/Library/Application Support/eza` and ignores `XDG_CONFIG_HOME` | [`eza/theme.yml`](./eza/theme.yml), [`fish/config.fish`](./fish/config.fish) |

`fish/config.fish` notes:
- Defines `dev` / `work` / `side` aliases that spawn (or switch to) a named tmux session with a fixed CWD.
- Defines `vault` to jump to the directory containing the Obsidian vaults in iCloud Drive.
- Always exports an explicit `AWS_PROFILE` — `work` inside the `work` tmux session, `personal` everywhere else. `~/.aws/config` has no `[default]` profile, so leaving it unset means every `aws` command fails with `NoCredentials`; setting it always also means Starship's `aws` module always draws, which is how you see which account you're pointed at.
- Provides `req` — curl with sane flags, piping the response through `jq` when it parses as JSON. There is deliberately no `~/.curlrc`: that file is read by *every* curl invocation, including the Homebrew installer's and any third-party script's.
- Wraps `claude` so that `CLAUDE_CONFIG_DIR=~/.claude-work` is used in the `work` session, letting two Claude Code subscriptions stay logged in side-by-side.
- Feeds Starship two env vars from a single `fish_prompt` event handler, both builtins-only so the prompt pays no forks: `STARSHIP_DOCKER_CTX` (read out of `~/.docker/config.json` — `docker context inspect` is 126ms of Go CLI startup to print what's already on disk) and `STARSHIP_PNPM` (walks up from `$PWD` to `$HOME` looking for `pnpm-lock.yaml`).
- Binds everything custom inside `fish_user_key_bindings`, fzf's `Ctrl-T`/`Alt-C` included. fish re-applies the preset bindings whenever `$fish_key_bindings` changes and calls that function afterwards, so anything bound outside it is silently dropped.
- Ships its own `completions/aws.fish` instead of registering `aws_completer` from `config.fish`. `complete -c aws` *adds* a source, so the old rule merged with the `aws.fish` fish 4 compiles into its binary and kept offering services awscli dropped years ago. Only the first match in `$fish_complete_path` is autoloaded, so a file in `~/.config/fish/completions` is what actually replaces it. Shadowing that table costs its live `s3://` bucket and key completion, so those helpers are ported into the file. `aws_completer` emits bare names, so the descriptions are joined in from the botocore models bundled with awscli — keyed on the name with dashes and case dropped, because botocore's own `xform_name` turns `ListHITs` into `list-hi-ts` and not the `list-hits` the CLI takes. jq over those models is ~600ms for a big service and ~1s for the full service list, so both tables are cached under `~/.cache/fish/aws-completions/` and rebuilt when the model directory outdates them, which an awscli upgrade guarantees.
- Uses **hybrid emacs + vi** bindings (`fish_hybrid_key_bindings`) — emacs keys with vi mode on Esc. The other direction needs a long escape timeout, which delays every `Alt-<key>` too, because the terminal sends those as `ESC`+key (`macos-option-as-alt = true`).
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
| `fish/config.fish` | `~/.config/fish/config.fish` |
| `fish/conf.d/00-env.fish` | `~/.config/fish/conf.d/00-env.fish` |
| `fish/completions/aws.fish` | `~/.config/fish/completions/aws.fish` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `tmux/tmux.conf` | `~/.tmux.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `eza/theme.yml` | `~/.config/eza/theme.yml` |
| `nvim/init.lua` | `~/.config/nvim/init.lua` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `psql/psqlrc` | `~/.psqlrc` |
| `pgcli/config` | `~/.config/pgcli/config` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

The Neovim config is symlinked, so edits inside `~/.config/nvim` are reflected directly in the repo.

Because `~/.gitconfig` is a symlink, any `git config --global …` you run writes straight into `git/gitconfig` in this repo. That's deliberate — the change gets versioned instead of drifting in `$HOME` — but it does mean the repo shows as dirty after you touch git config.

`~/.config/fish/functions` and `fish_variables` are deliberately **not** versioned: fish writes into them itself. `completions/` holds one symlinked file, `aws.fish`, because shadowing fish's built-in table is the only way to replace it — everything else fish drops in there stays local state.

## What is NOT managed

- **Database credentials** — `~/.pgpass` holds them so `psql` doesn't prompt. It is a secrets file and is **never** versioned. `pgcli` runs with `keyring = False` so it reads the same file instead of caching passwords into the macOS Keychain on its own. Create it by hand, one connection per line, and lock it down or Postgres refuses to read it:

  ```
  hostname:port:database:username:password     # * works as a wildcard
  chmod 600 ~/.pgpass
  ```

- **VS Code** — config (`settings.json`, keybindings, theme) is user-level and not versioned here; Settings Sync lives elsewhere.
- **`~/.aws/config`** — keep your own AWS profiles where you want them; the repo only sets `AWS_PROFILE` based on tmux session.
- **`~/.claude/`** (and the optional `~/.claude-work/`) — Claude Code config is user-level state, not versioned. Bootstrap a work account with `CLAUDE_CONFIG_DIR=~/.claude-work claude` then `/login`.

## Notes

- Supports macOS only.
- The script prompts for your password once, for `chsh` (switching the login shell).
- `~/.cache/fish/init.fish` is generated state, not config. Delete it and the next shell rebuilds it.
- Rollback: the zsh setup is still in git history — `git show b71d626:zsh/zshrc` and `git show b71d626:zsh/zprofile`, plus `chsh -s /bin/zsh`.
- Designed to be safe to rerun: every step either no-ops or moves existing state aside before replacing it.
