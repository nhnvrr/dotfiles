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
- Switches the login shell to `/bin/zsh` (uses `dscl` to read the real login shell, not `$SHELL`). macOS ships `/bin/zsh` already registered in `/etc/shells`, so the `sudo` branch normally never runs
- Removes the stale `~/.config/fish/config.fish` symlink left by the previous fish + Tide setup (only if it points into this repo), plus the dangling `~/.zshenv` / `~/.bashrc` / `~/.bash_profile` / `~/.profile` links into a `/nix/store` that no longer exists

The `link_file` helper backs up any pre-existing regular file at the destination to `<dst>.bak.<timestamp>` before replacing it with a symlink — your hand-edited configs won't disappear silently.

## First run on a fresh Mac

After `install.sh` exits cleanly:

1. **Paste the SSH pubkey on GitHub** — it's already on your clipboard. Add it at <https://github.com/settings/ssh/new> as both an authentication key AND a signing key (so your signed commits show up as Verified).
2. **Authenticate the GitHub CLI:** `gh auth login` (script reminds you if not authenticated).
3. **Grant Accessibility permission to Hammerspoon** on first launch (System Settings → Privacy & Security → Accessibility). Required for window management hotkeys.
4. **Open Ghostty** (not Terminal.app) — it picks up `ghostty/config`, the Nord Wave theme, the fonts, and zsh as the login shell.

Note: the script prompts for your password once, for `chsh`.

## Tooling

| Layer | Tool | Config file |
|---|---|---|
| Shell | zsh (macOS's `/bin/zsh`) | [`zsh/zshrc`](./zsh/zshrc), [`zsh/zprofile`](./zsh/zprofile) |
| Prompt | Starship | [`starship/starship.toml`](./starship/starship.toml) |
| Terminal | Ghostty | [`ghostty/config`](./ghostty/config) |
| Multiplexer | tmux | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Editor | VS Code (`e` = `code --new-window`) — it's what handles the EC2 work: Remote-SSH, AWS Toolkit and SSM sessions. It's also what Hammerspoon's `cmd+alt+1` layout pairs with Chrome. Its config is user-level, not versioned here | — |
| `$EDITOR` | Neovim — commits, `git rebase -i`, the shell's Ctrl-O, and quick edits. One file, no LSP and no completion; the plugins are the theme, neo-tree and telescope with the fzf-native C sorter (`<leader>f` files, `<leader>g` grep, `<leader>b` buffers, `<leader>e` tree) | [`nvim/init.lua`](./nvim/init.lua) |
| Database | `psql` is what scripts use and the fallback that's always there; `pgcli` is the interactive one — schema-aware completion of table and column names, syntax highlighting, and an editable multi-line buffer, none of which `psql` has. It does **not** read `~/.psqlrc`, so the five shortcuts are duplicated as named queries (`\n` lists them, `\n conns` runs one). TablePlus as the visual complement | [`psql/psqlrc`](./psql/psqlrc), [`pgcli/config`](./pgcli/config) |
| HTTP | `curl` via the `req` function; Bruno for exploratory work | [`zsh/zshrc`](./zsh/zshrc) |
| Git | versioned config, SSH-signed commits | [`git/gitconfig`](./git/gitconfig) |
| Window mgmt | Hammerspoon — `cmd+alt+1/2/3` tile an app pair at 70/30 and hide everything else, `R` mirrors the split, `F` zooms. It never sleeps a fixed interval: it waits on the condition, because Electron applies `AXSize` and `AXPosition` separately and macOS ignores `setSize` in native fullscreen. Widths are measured, not assumed — the narrow app is placed first and the wide one gets whatever the other's minimum left over. Plus Raycast (launcher, clipboard, simple windows) | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |
| Runtime mgr | mise — global versions plus per-project `.nvmrc` | [`mise/config.toml`](./mise/config.toml) |
| Font | GeistMono Nerd Font Mono at size 18 — one font, not a pair. The Nerd Font build carries Vercel's Geist Mono glyphs *and* every icon, so there is no fallback `font-family` line to keep in sync and a fresh machine gets the real thing straight from `brew bundle`. Ligatures are off (`font-feature = -calt, -liga, -dlig`) | [`ghostty/config`](./ghostty/config), cask `font-geist-mono-nerd-font` |
| Theme | Nord Wave (dark-only), one of Ghostty's bundled themes, with `background` forced to pure black instead of its `#212121` — that override and the `208` one have to sit **below** the `theme` line to win. nvim runs `nordic.nvim` (transparent, so only its Nord syntax colours land on top). Starship, eza, `bat` and tmux all resolve colours through the terminal's ANSI slots, so changing the Ghostty theme moves everything at once. GUI editors keep their own user-level theme | [`ghostty/config`](./ghostty/config) |
| History | zsh's native history, searched with fzf on Ctrl-R | [`zsh/zshrc`](./zsh/zshrc) |
| Fuzzy find | fzf on Ctrl-R (history), Ctrl-T (files, `bat` preview), Alt-C (directories) and `**<TAB>` (completion). zoxide also shells out to it for `zi` | [`zsh/zshrc`](./zsh/zshrc) |
| Listings | eza with icons — `ls`, `ll`, `la`, `lt`, themed by ANSI name (folders cyan, metadata grey, git matching the prompt). Needs the Nerd Font's **Mono** (NFM) variant, where a glyph is exactly one cell wide; the Propo variant drifts the columns. `EZA_CONFIG_DIR` is mandatory: on macOS eza reads `~/Library/Application Support/eza` and ignores `XDG_CONFIG_HOME` | [`eza/theme.yml`](./eza/theme.yml), [`zsh/zshrc`](./zsh/zshrc) |

`zsh/zshrc` notes:
- Defines `dev` / `work` / `side` aliases that spawn (or switch to) a named tmux session with a fixed CWD.
- Defines `vault` to jump to the directory containing the Obsidian vaults in iCloud Drive.
- Always exports an explicit `AWS_PROFILE` — `work` inside the `work` tmux session, `personal` everywhere else. `~/.aws/config` has no `[default]` profile, so leaving it unset means every `aws` command fails with `NoCredentials`; setting it always also means Starship's `aws` module always draws, which is how you see which account you're pointed at.
- Provides `req` — curl with sane flags, piping the response through `jq` when it parses as JSON. There is deliberately no `~/.curlrc`: that file is read by *every* curl invocation, including the Homebrew installer's and any third-party script's.
- Wraps `claude` so that `CLAUDE_CONFIG_DIR=~/.claude-work` is used in the `work` session, letting two Claude Code subscriptions stay logged in side-by-side.
- Implements fish-style **abbreviations** for the git shortcuts (`gc`, `gco`, `ga`, `gb`, `gd`) in ~20 lines of ZLE: they expand in place on space or enter, so you see the real command before running it and the history stores the expanded form. They only fire in command position, so `echo gd` stays literal.
- Uses **hybrid emacs + vi** bindings — `bindkey -v` with the emacs keys added back to `viins`, so Esc enters command mode with `KEYTIMEOUT=1`. The other direction (`bindkey -e` plus Esc bound to `vi-cmd-mode`) needs a high `KEYTIMEOUT`, which delays every Esc *and* every `Alt-<key>`, because the terminal sends those as `ESC`+key (`macos-option-as-alt = true`).
- Caches `zoxide init` / `fzf --zsh` / `starship init` into `~/.cache/zsh/init.zsh`, regenerated when `.zshrc` or any Homebrew binary changes. mise is deliberately **not** cached: `mise activate zsh` interpolates the current `$PATH` into its output, so a cached copy would pin one shell's PATH onto every later shell.
- Forces Starship's `precmd` hook to run first. mise's hook does `eval "$(mise hook-env)"` without preserving `$?`, which would otherwise leave the exit-status module permanently reading 0.

### Why zsh

It's macOS's own shell: no formula to install, no login-shell registration, nothing to drift. Everything fish gave natively has a direct equivalent — autosuggestions and syntax highlighting are two Homebrew plugins, prefix history search is `up-line-or-beginning-search`, and `$CMD_DURATION` becomes a `preexec`/`precmd` pair over `$EPOCHREALTIME` (a variable, not a fork). What it does **not** have is `abbr`, hybrid key bindings, or per-mode cursors, so those are hand-rolled above.

Startup is ~80ms per shell (60ms warm, measured end-to-end with `/usr/bin/time -p /bin/zsh -l -i -c exit`, not with a profiler that skips process spawn), and every tmux pane opens one. Where that goes, and what was done about it:

| Cost | Fix |
|---|---|
| `eval "$(brew shellenv)"` — 2 forks, ~20ms | inlined as constants in `zprofile`; the base PATH already comes from `/etc/zprofile` |
| `compinit` rebuilding the dump — ~150ms | rebuilt at most once a day, `compinit -C` otherwise (~7ms) |
| `zoxide`/`fzf`/`starship` init — ~13ms | cached, see above |
| `mise activate` — ~17ms | unavoidable, and fish paid it too |

The prompt itself costs ~40-50ms per keypress in a large repo, because zsh evaluates `PROMPT` and `RPROMPT` separately and each spawns `starship`. Dropping the right prompt would halve it.

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
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/zprofile` | `~/.zprofile` |
| `starship/starship.toml` | `~/.config/starship.toml` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `ghostty/themes` | `~/.config/ghostty/themes` |
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

There is deliberately no `~/.zshenv`: zsh reads that file in *every* process, scripts included, and nothing here needs to be.

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
- `~/.cache/zsh/init.zsh` is generated state, not config. Delete it and the next shell rebuilds it.
- Rollback: the fish + Tide setup is still in git history — `git show HEAD~1:fish/config.fish`.
- Designed to be safe to rerun: every step either no-ops or moves existing state aside before replacing it.
