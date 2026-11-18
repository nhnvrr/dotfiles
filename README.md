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

Idempotent. It installs Homebrew and applies the [`Brewfile`](./Brewfile), installs the runtimes pinned in [`mise/config.toml`](./mise/config.toml) and node 24 through nvm, generates an `ed25519` SSH key and registers it with the Keychain, symlinks the files listed below, applies a few macOS defaults (key repeat, Finder, screenshots, the Dock reset to factory defaults) and makes `/bin/zsh` the login shell.

Then, by hand:

1. **Paste the SSH pubkey on GitHub** — already on your clipboard. Add it at <https://github.com/settings/ssh/new> as **both** an authentication and a signing key.
2. `gh auth login`
3. **Set Chrome as the default browser** from its _Make default_ button. Nothing here does it: macOS 27 ignores every scripted route.
4. **Install Rex** from its DMG; it has no cask. The themes, font and shortcuts are already in place when it first opens.
5. **Open Hammerspoon once** and grant it Accessibility in *System Settings > Privacy & Security*; without it no hotkey moves a window.

## The stack

| Layer     | Tool                                                                                   | Config                                   |
| --------- | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| Browser   | Chrome                                                                                 | —                                        |
| Editor    | VS Code, default theme; settings and keybindings linked, extensions in the Brewfile   | [`vscode/`](./vscode)                    |
| Quick edits | vim, no plugins; colours from the terminal palette; `$EDITOR`                  | [`vim/`](./vim)                          |
| Editor (terminal) | nvim — fzf-lua, oil, treesitter, mini (icons, statusline, clue), gitsigns, native LSP + blink.cmp, conform; servers in the Brewfile; [Everforest](https://github.com/sainnhe/everforest) hard dark, the only tool off the `mate` palette, plugins pinned in the lockfile | [`nvim/`](./nvim)                        |
| Terminal  | Ghostty — tabs and splits are its own                                                 | [`ghostty/config`](./ghostty/config)     |
| Agents    | Rex — one session per worktree; font and layout written to its preferences by `install.sh`, shortcuts linked. The app itself is a manual install, no cask | [`rex/`](./rex)                          |
| Windows   | Hammerspoon — cmd+alt+0 zooms every window, cmd+alt+- / = drop one in a pane; cmd+§ cycles windows like cmd+` | [`hammerspoon/`](./hammerspoon)          |
| Dock      | auto-hide, magnification, no recent apps; the app and folder list is rebuilt from scratch by `install.sh`, so anything pinned by hand is dropped on the next run | [`install.sh`](./install.sh)             |
| Shell     | fish (login shell), [bobthefish](https://github.com/oh-my-fish/theme-bobthefish) prompt in the terminal's colours (pinned clone, no plugin manager) with `profile@region` for AWS, the k8s context and a transient `❯` in the scrollback, vi mode; tab opens fish completions in fzf, ctrl-r / ctrl-t / alt-c are fzf. zsh stays configured as the fallback, with the [Starship](https://starship.rs) prompt | [`fish/`](./fish), [`zsh/`](./zsh), [`starship/`](./starship) |
| Database  | TablePlus; `psql`, `redis-cli` in the terminal                                         | —                                        |
| Runtimes  | nvm for node (`.nvmrc` switches on `cd`); mise for everything else                     | [`mise/config.toml`](./mise/config.toml) |
| Questions | `? <question>` — one-off, read-only Claude                                              | [`zsh/functions/ask`](./zsh/functions/ask) |
| Claude Code | one config dir per workspace (`~/Work`, `~/Side`, `~/Orange`), seeded from `claude/base/`; custom status line: model, dir + branch, cost, lines, rate limits | [`claude/`](./claude) |

**Colours.** One palette, `mate`, in [`ghostty/themes/`](./ghostty/themes) — dark and light. The terminal switches on its own, apart from macOS: `mate` toggles it from the shell ([`zsh/functions/mate`](./zsh/functions/mate)), `mate dark` / `mate light` force a side. It writes the theme to the git-ignored `ghostty/mode.local` and reloads Ghostty; the prompt, vim, fzf, tmux and btop follow the terminal's colours (nvim is the exception: always Everforest hard dark, in true colour) — Starship is configured with ANSI colour names only, never hex. The palette lives only in Ghostty: VS Code, Rex and TablePlus use their own default themes.


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
- **The fish AWS segment replaces a bobthefish internal** (`__bobthefish_prompt_aws_vault_profile`, in `fish/config.fish`). After bumping `BOB_REV` in `install.sh`, check that `profile@region` still shows.
- **nvm is bash-only, so fish does not use it to switch.** `fish/config.fish` puts the node from `.nvmrc` (or the default alias) on `$PATH` on every `cd`, straight from `~/.nvm/versions`. `nvm install` works through bash; `nvm use` changes nothing in fish.
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
