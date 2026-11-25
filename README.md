# dotfiles

macOS. Chrome, Ghostty, fish, zsh, vim, nvim, VS Code, TablePlus. Nothing else is configured here.

## Install

Any Apple Silicon Mac (M1 or later), from a fresh account:

```bash
curl -fsSL https://raw.githubusercontent.com/nhnvrr/dotfiles/main/bootstrap.sh | bash
```

[`bootstrap.sh`](./bootstrap.sh) installs the Command Line Tools, clones over HTTPS into `~/Develop/dotfiles`, runs `install.sh` and then points `origin` at SSH. Already cloned:

```bash
./install.sh              # --skipBrew to only re-link configs
./check.sh                # validates configs and symlinks without changing anything
```

Idempotent. It installs Homebrew and applies the [`Brewfile`](./Brewfile), installs the runtimes pinned in [`mise/config.toml`](./mise/config.toml) and node 24 through nvm, generates an `ed25519` SSH key and registers it with the Keychain, symlinks the files listed below, applies a few macOS defaults (key repeat, Finder, screenshots, reduced transparency, tinted glass and Low Power Mode, the Dock reset to factory defaults) and makes fish the login shell.

Then, by hand:

1. **Paste the SSH pubkey on GitHub** — already on your clipboard. Add it at <https://github.com/settings/ssh/new> as **both** an authentication and a signing key.
2. `gh auth login`
3. **Set Chrome as the default browser** from its _Make default_ button. Nothing here does it: macOS 27 ignores every scripted route.
4. **Install Rex** from its DMG; it has no cask. The themes, font and shortcuts are already in place when it first opens.
5. **Open Hammerspoon once** and grant it Accessibility in *System Settings > Privacy & Security*; without it cmd+§ does nothing.
6. **Reduce Transparency**, only if `install.sh` printed `skipped Reduce Transparency`: turn it on in *System Settings > Accessibility > Display*. macOS blocks that write unless the terminal has Full Disk Access.
7. **Open Tailscale and log in** from its menu bar icon; the login cannot be scripted without an auth key.

## The stack

| Layer     | Tool                                                                                   | Config                                   |
| --------- | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| Browser   | Chrome                                                                                 | —                                        |
| Editor    | VS Code, default theme; settings and keybindings linked, extensions in the Brewfile   | [`vscode/`](./vscode)                    |
| Quick edits | vim, no plugins; colours from the terminal palette; `$EDITOR`                  | [`vim/`](./vim)                          |
| Editor (terminal) | nvim — fzf-lua, nvim-tree, treesitter, mini (icons, statusline, clue), gitsigns, native LSP + blink.cmp, conform; servers in the Brewfile; Mate through `vim/colors/mate.vim` (shared with vim, ANSI slots only), plugins pinned in the lockfile | [`nvim/`](./nvim)                        |
| Terminal  | Ghostty — tabs and splits are its own                                                 | [`ghostty/config`](./ghostty/config)     |
| Agents    | Rex — one session per worktree; Mate themes ([`rex/themes.json`](./rex/themes.json)), font and layout written to its preferences by `install.sh`, shortcuts linked. The app itself is a manual install, no cask | [`rex/`](./rex)                          |
| Dock      | always visible, no magnification, no recent apps; the app and folder list is rebuilt from scratch by `install.sh`, so anything pinned by hand is dropped on the next run | [`install.sh`](./install.sh)             |
| Windows   | Hammerspoon — cmd+§ and cmd+` cycle the front app's windows on either keyboard | [`hammerspoon/`](./hammerspoon)          |
| Shell     | fish (login shell and terminal), [bobthefish](https://github.com/oh-my-fish/theme-bobthefish) prompt in the terminal's colours (pinned clone, no plugin manager) on one line, with the k8s context and a transient `❯` in the scrollback, vi mode; `awsp` prints the AWS profile and region; tab opens fish completions in fzf, ctrl-r / ctrl-t / alt-c are fzf | [`fish/`](./fish) |
| Shell (also) | zsh stays configured as the fallback, with the [Starship](https://starship.rs) prompt | [`zsh/`](./zsh), [`starship/`](./starship) |
| Database  | TablePlus; `psql`, `pgcli` (vi mode, mate colours), `redis-cli` in the terminal        | [`pgcli/config`](./pgcli/config)         |
| Runtimes  | nvm for node (`.nvmrc` switches on `cd`); mise for everything else                     | [`mise/config.toml`](./mise/config.toml) |
| Questions | `? <question>` — one-off, read-only Claude                                              | [`zsh/functions/ask`](./zsh/functions/ask) |
| Claude Code | one config dir per workspace (`~/Work`, `~/Side`, `~/Orange`), seeded from `claude/base/`; custom status line: model, dir + branch, cost, lines, rate limits | [`claude/`](./claude) |

**Colours.** One palette, Mate 🧉, in [`ghostty/themes/`](./ghostty/themes) — dark and light. The terminal switches on its own, apart from macOS: `mate` toggles it from the shell ([`zsh/functions/mate`](./zsh/functions/mate)), `mate dark` / `mate light` force a side. It writes the theme to the git-ignored `ghostty/mode.local` and reloads Ghostty; every terminal app follows the terminal's colours — the prompts, vim, nvim, fzf, tmux, btop, bat, lazygit, pgcli and the Claude Code status line are configured with ANSI slots only, never hex. pgcli is the one that needs two files: its menu surface and dim differ per mode, so a `pgcli` shell function passes `--pgclirc config-light` when Ghostty is on Mate light. The palette lives only in Ghostty: Rex is the exception: it has no ANSI-slot mode, so `rex/themes.json` carries its own copy of both palettes. VS Code and TablePlus use their own default themes.


## Managed files

| Repo                 | Destination                      |
| -------------------- | -------------------------------- |
| `zsh/zshenv`         | `~/.zshenv`                      |
| `zsh/zshrc`          | `~/.zshrc`                       |
| `zsh/functions/`     | `~/.config/zsh/functions`        |
| `starship/starship.toml` | `~/.config/starship.toml`    |
| `ghostty/`           | `~/.config/ghostty`              |
| `vscode/settings.json` | `~/Library/Application Support/Code/User/settings.json` |
| `vscode/keybindings.json` | `~/Library/Application Support/Code/User/keybindings.json` |
| `mise/config.toml`   | `~/.config/mise/config.toml`     |
| `btop/btop.conf`     | `~/.config/btop/btop.conf`       |
| `gh/config.yml`      | `~/.config/gh/config.yml`        |
| `claude/base/statusline.sh` | `~/.claude/statusline.sh`  |
| `pgcli/config`, `pgcli/config-light` | `~/.config/pgcli/` (files, not the dir) |
| `lazygit/config.yml` | `~/.config/lazygit/config.yml`   |

`link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` first.

## Claude Code workspaces

Claude Code only reads skills, plugins, MCP servers and `settings.json` from
`~/.claude` and from the repo it is started in, never from a parent folder,
so a tool meant for every repo under `~/Work` would have to be repeated in
each one, and a global one cannot be switched off per folder. Instead each
workspace gets its own config dir, and `zshrc` exports `CLAUDE_CONFIG_DIR`
to it on `cd`:

| `$PWD` under | `CLAUDE_CONFIG_DIR`     |
| ------------ | ----------------------- |
| `~/Work`     | `~/Work/.claude-config` |
| `~/Side`     | `~/Side/.claude-config` |
| `~/Orange`   | `~/Orange/.claude-config` |
| anywhere else | unset, so `~/.claude`  |

A workspace that does not exist on a machine is skipped. To set one up:

```bash
claude/workspace-init.sh ~/Orange
cd ~/Orange && claude    # then /login and /status
```

It copies [`claude/base/`](./claude/base) (the generic rules, `new-plan`,
`pr`, `codex`, `herdr`, `rex`, the status line) and never overwrites what is
already there. Everything workspace-specific (its `CLAUDE.md` context, MCP
servers, plugins, extra skills) is added by hand inside `.claude-config/`
and stays out of this repo: it is public. Each config dir needs its own
`/login` once, and sessions do not carry across workspaces.

Processes started by Rex do not run the shell hooks, so `rex-wt` sets
`CLAUDE_CONFIG_DIR` itself when the worktree is inside a workspace.

### Feature workflow

Three skills take a feature from spec to reviewed code, one Rex session per
ticket:

| Skill | Runs in | Does |
| ----- | ------- | ---- |
| `feature-spec` | any session | ES/EN spec artifact (sections, ASCII and animated isometric flows, use cases, tickets) plus `~/Documents/tickets/<slug>/feature.json`; exports tickets to markdown, Shortcut or another tracker |
| `ticket-start` | the spec session | `rex-wt new --plan`: worktree and Rex session named after the ticket, Claude in plan mode on `/ticket-implement` |
| `ticket-implement` | the ticket session | plan, implement in auto mode, tests in a `tests` tab, `codex-review` loop in a `codex-review` tab, report in `~/Documents/code-reviews/` |

These, `codex-review` and `rex` are symlinked from `claude/base/skills/` into
`~/.claude/skills/` and each workspace's `skills/`, and their scripts
(`rex-wt`, `rex-split`, `ticket-run`, `codex-review`) into `~/.local/bin`.

**Not managed:** Chrome and TablePlus keep settings the apps rewrite. `~/.aws/config` and `~/.pgpass` hold secrets and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Key repeat

`install.sh` sets these; this is the by-hand version for any Mac. Both numbers
are in units of 15 ms and are the lowest the sliders in System Settings go;
anything smaller has to be written here. Log out and back in before they apply.

```bash
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # holding a key repeats it instead of opening the accent popup
defaults write NSGlobalDomain InitialKeyRepeat -int 15               # 225 ms before the first repeat
defaults write NSGlobalDomain KeyRepeat -int 2                       # 30 ms between repeats
```

## Traps

- **Git is not managed here.** `~/.gitconfig`, `~/.config/git/ignore` and `allowed_signers` are per-machine files, written by hand. Same caveat for VS Code: a setting changed in the UI edits `vscode/settings.json`, and Settings Sync, if left on, syncs that same file.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** Deleting a line is how you uninstall.
- **`.zshrc` has a load order.** The cursor-shape widgets go before `starship init` (it wraps them), `mise activate` goes after the PATH is final (it prepends), `fzf-tab` goes after `compinit` and before `zsh-autosuggestions`, and `zsh-syntax-highlighting` goes last of all (it only highlights widgets that already exist).
- **nvm is loaded lazily.** `zshenv` puts the `default` node on `$PATH` by reading `~/.nvm/alias/default`; `nvm.sh` itself (about 60 ms) is sourced the first time `nvm`, `node`, `npm` or `npx` run, or on `cd` into a directory with a `.nvmrc`. Non-interactive shells only ever see the default version.
- **The fish git segment replaces bobthefish internals** (`__bobthefish_prompt_git`, `__bobthefish_git_project_dir`, in `fish/config.fish`). After bumping `BOB_REV` in `install.sh`, check that the prompt still renders.
- **nvm is bash-only, so fish does not use it to switch.** `fish/config.fish` puts the node from `.nvmrc` (or the default alias) on `$PATH` on every `cd`, straight from `~/.nvm/versions`. `nvm install` works through bash; `nvm use` changes nothing in fish.
- **fish is not a POSIX shell.** It is the login shell, so anything that runs `$SHELL -c '…'` gets fish syntax. `&&`, `$(…)` and `VAR=x cmd` work; heredocs, `[[ ]]` and `if …; then … fi` do not. `ssh this-mac '…'` is the usual case; run `zsh -c` explicitly when a script needs sh syntax.
- **mise runs as shims in fish, not as a hook.** `fish/conf.d/mise-activate.fish` shadows Homebrew's activation, which ran `mise hook-env` on every prompt. Versions still switch per directory through the shims; `[env]` sections in a `mise.toml` are not loaded in fish.
- **node is not a mise tool**, and `.nvmrc` is excluded from `idiomatic_version_file_enable_tools`. Listing it again would put mise's node ahead of nvm's.
- **`~/.aws/config` has no `[default]` profile on purpose.** `AWS_PROFILE` follows the directory: `work` under `~/Work`, `personal` everywhere else, re-evaluated on every `cd`.
- **The font's family is `IoskeleyMonoTerm Nerd Font Mono`**, not its filename. The Brewfile installs the `font-ioskeley-mono-term-nerd-font` cask; the plain `font-ioskeley-mono` cask has no Term cut. A family CoreText cannot find falls back to Menlo silently.
- **btop rewrites `btop.conf` on exit** unless `save_config_on_exit = false`, which is why that line is there.
- **`psql` reads `psqlrc` non-interactively too.** Scripts should use `psql -X`.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```
