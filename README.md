# dotfiles

macOS. Chrome, Zed, Ghostty, fish, TablePlus. Nothing else is configured here.

## Install

Needs Apple's command-line tools first:

```bash
xcode-select --install

git clone git@github.com:nhnvrr/dotfiles.git ~/Develop/dotfiles
cd ~/Develop/dotfiles
./install.sh              # --skipBrew to only re-link configs
```

Idempotent. It installs Homebrew and applies the [`Brewfile`](./Brewfile), installs the runtimes pinned in [`mise/config.toml`](./mise/config.toml), generates an `ed25519` SSH key and registers it with the Keychain, symlinks the files listed below, applies a few macOS defaults, adds Homebrew's fish to `/etc/shells` (one `sudo`) and makes it the login shell.

Then, by hand:

1. **Paste the SSH pubkey on GitHub** — already on your clipboard. Add it at <https://github.com/settings/ssh/new> as **both** an authentication and a signing key.
2. `gh auth login`
3. **Set Chrome as the default browser** from Chrome's _Make default_ button or System Settings. macOS 27 ignores every scripted route (`duti` answers `error -50` on `http`), so nothing here does it or checks it.
4. **Install the font** — take `IoskeleyMono-Term.zip` from the [upstream release](https://github.com/ahatem/IoskeleyMono/releases) and drop the `IoskeleyMonoTerm-*.ttf` files into `~/Library/Fonts`. The `font-ioskeley-mono` cask has no Term cut.

## The stack

| Layer     | Tool                                                                                   | Config                                   |
| --------- | -------------------------------------------------------------------------------------- | ---------------------------------------- |
| Browser   | Chrome                                                                                 | —                                        |
| Editor    | Zed, vim mode; `$EDITOR` is `zed --wait`                                               | [`zed/`](./zed)                          |
| Quick edits | vim, one plugin (`yegappan/lsp`); colours from the terminal palette              | [`vim/`](./vim)                          |
| Terminal  | Ghostty — tabs and splits are its own; ``cmd+` `` toggles the quick terminal globally | [`ghostty/config`](./ghostty/config)     |
| Windows   | Hammerspoon — two-app workspace on cmd+alt, i3-style motions on ctrl+alt          | [`hammerspoon/`](./hammerspoon)          |
| Shell     | fish, `fish_git_prompt`, fzf                                                           | [`fish/`](./fish)                        |
| Database  | TablePlus; `psql`, `pgcli`, `redis-cli` in the terminal                                | —                                        |
| Git       | SSH-signed commits                                                                    | [`git/gitconfig`](./git/gitconfig)       |
| Runtimes  | mise                                                                                   | [`mise/config.toml`](./mise/config.toml) |
| Questions | `? <question>` expands to `ask "…"` — one-off, read-only Claude                        | [`fish/functions/ask.fish`](./fish/functions/ask.fish) |

**Colours.** One palette, `mate`, in [`ghostty/themes/`](./ghostty/themes) — dark and light. Ghostty picks the variant from the macOS appearance (`theme = light:…,dark:…`) and Zed does the same (`"mode": "system"`), so there is no switch script. [`zed/themes/mate.json`](./zed/themes/mate.json) was generated from the Ghostty files: if a slot changes there, regenerate it rather than editing both by hand.

TablePlus gets the same palette from [`tableplus/`](./tableplus), mapped from the Zed theme. It is not linked by `install.sh`: import the folder once with *Theme > Import theme…*, then set `mate dark` and `mate light` as the dark and light defaults in *Settings > Theme*.

## Managed files

| Repo                 | Destination                      |
| -------------------- | -------------------------------- |
| `fish/`              | `~/.config/fish`                 |
| `ghostty/`           | `~/.config/ghostty`              |
| `zed/settings.json`  | `~/.config/zed/settings.json`    |
| `zed/keymap.json`    | `~/.config/zed/keymap.json`      |
| `zed/themes/`        | `~/.config/zed/themes`           |
| `mise/config.toml`   | `~/.config/mise/config.toml`     |
| `btop/btop.conf`     | `~/.config/btop/btop.conf`       |
| `git/gitconfig`      | `~/.gitconfig`                   |
| `git/ignore`         | `~/.config/git/ignore`           |
| `git/allowed_signers`| `~/.config/git/allowed_signers`  |
| `gh/config.yml`      | `~/.config/gh/config.yml`        |

`link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` first. Zed is linked file by file because it writes `prompts/` and `conversations/` into its own directory.

**Not managed:** Chrome and TablePlus keep settings the apps rewrite. `~/.aws/config` and `~/.pgpass` hold secrets and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. Deliberate.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** Deleting a line is how you uninstall.
- **`conf.d/00-env.fish` must sort first.** Homebrew's `vendor_conf.d/mise-activate.fish` prepends to whatever `$PATH` it finds, so if the env file ran later `~/.bun/bin` would shadow the mise-pinned runtime.
- **`~/.aws/config` has no `[default]` profile on purpose.** `AWS_PROFILE` follows the directory: `work` under `~/work`, `personal` everywhere else, re-evaluated on every `cd`.
- **The font's family is `Ioskeley Mono Term`, spaced**, not its filename. A family CoreText cannot find falls back to Menlo silently.
- **btop rewrites `btop.conf` on exit** unless `save_config_on_exit = false`, which is why that line is there.
- **`psql` reads `psqlrc` non-interactively too.** Scripts should use `psql -X`.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```
