# dotfiles

macOS. fish in Ghostty, Hammerspoon for window tiling, herdr for agents, VS Code, Kanso Ink.

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
4. **Launch Ghostty once** — font, palette, window mode and `macos-option-as-alt` all come from [`ghostty/config`](./ghostty/config), so there is nothing to click. It opens maximized, in a native macOS window titled `🧉`.

## The stack

| Layer | Tool | Config |
|---|---|---|
| Shell | fish — hand-written prompt (pwd, `fish_git_prompt`, date on the right; no theme), stock completions, stock highlighting; `/bin/zsh` stays for scripts | [`fish/config.fish`](./fish/config.fish), [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish), [`fish/functions/fish_prompt.fish`](./fish/functions/fish_prompt.fish) |
| Terminal | Ghostty | [`ghostty/config`](./ghostty/config) |
| Agents | herdr — agent state over its socket API, not a shell multiplexer | [`herdr/config.toml`](./herdr/config.toml) |
| Sessions | tmux — persistence across a disconnect, and the multiplexer that exists on a remote host | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Quick questions | `?` → `ask` — one-off question to Claude, read-only, web search when needed | [`fish/functions/ask.fish`](./fish/functions/ask.fish) |
| Environment | `envinfo` — shell, path, git, the mise toolchain, AWS profile, docker context, on demand | [`fish/functions/envinfo.fish`](./fish/functions/envinfo.fish) |
| Editor | Neovim — Everforest, native `vim.pack`, LSP for TypeScript, Go, Rust, YAML and JSON | [`nvim/init.lua`](./nvim/init.lua), [`nvim/lua/lsp.lua`](./nvim/lua/lsp.lua) |
| Editor (GUI) | VS Code | — user-level |
| `$EDITOR` | `code --wait` | [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) |
| Browser | Chrome — the default handler, and where the Claude in Chrome extension lives | — user-level |
| Database | `psql` for scripts, a GUI client for interactive | [`psql/psqlrc`](./psql/psqlrc) |
| Redis | `redis-cli` | — history path in [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) |
| HTTP | `curl`; Bruno for exploratory work | — |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Listing | eza — icons, directories first, theme from the sixteen slots | [`eza/theme.yml`](./eza/theme.yml) |
| Fuzzy find | fzf + fd + bat | [`fish/config.fish`](./fish/config.fish) |
| Monitoring | btop — `color_theme = "TTY"`, so it follows the terminal's sixteen slots | [`btop/btop.conf`](./btop/btop.conf) |
| Clipboard | Maccy | [`Brewfile`](./Brewfile) |
| Window tiling | Hammerspoon — right pane the browser, left pane on `cmd+alt+1/2/3` | [`hammerspoon/init.lua`](./hammerspoon/init.lua) |

Keys split by modifier: Ghostty takes `cmd`, fish takes bare `ctrl`, and inside a herdr pane `ctrl+b` is the prefix before any of it.

Typing `?` and a space expands to `ask ""` with the cursor between the quotes — a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. The abbreviation exists so the question lands inside quotes; typed bare, `? why is 5 > 3` would be a redirection and fish would write a file named `3`.

## Theme

Ghostty runs its built-in Nord theme; Neovim runs [Everforest](https://github.com/sainnhe/everforest) (`hard`). The Kanso Ink palette below is kept in [`ghostty/config.kanso-ink`](./ghostty/config.kanso-ink) as the alternative.

**[Kanso Ink](https://github.com/webhooked/kanso.nvim).** [`ghostty/config`](./ghostty/config) carries the palette slot by slot, so the terminal owns the sixteen slots and everything downstream follows them for free: `bat` and delta run `syntax-theme = ansi`, fish's stock colours are ANSI names, `psql` writes the raw SGR slots, and `btop` runs `color_theme = "TTY"`. None of them carries a colour of its own.

One thing restates the palette as hex, and has to: herdr's theme tokens accept no ANSI reference, so [`herdr/config.toml`](./herdr/config.toml) writes them out under `[theme.custom]`, using the theme's own `bg0`–`bg4` ramp for its surfaces.

**The palette is verbatim, and that is the reason it is here.** The two themes this replaced both repeat the normal colours in the bright half, which collapses the distinctions fish's highlighter draws on — `command` against `keyword`, `redirection` against `end` — and each needed eight slots relit by hand to survive. Kanso Ink gives all sixteen genuinely different values, so nothing is hand-tuned.

| | Ratio on `#14171d` |
|---|---|
| body text `#C5C9C7` | 10.73:1 |
| tightest slot — red `#c4746e` | 5.19:1 |
| slot 8 `#A4A7A4` (comments, autosuggestions, dim text) | 7.39:1 |
| selection `#393B44`, text on top | 1.61:1 / 6.67:1 |

The one thing to know: `black` is the background itself, so a program that explicitly asks for ANSI black draws invisibly. That is upstream's choice, kept here; swapping slot 0 for `#1f1f26` is a one-line change if it ever bites.

## Managed files

| Repo | Destination |
|---|---|
| `fish/` | `~/.config/fish` |
| `ghostty/config` | `~/.config/ghostty/config` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `herdr/sounds/done.mp3` | `~/.config/herdr/sounds/done.mp3` |
| `herdr/sounds/request.mp3` | `~/.config/herdr/sounds/request.mp3` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `psql/psqlrc` | `~/.psqlrc` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files, except `fish/`, which is linked as a directory so a new function file needs no install step. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

**Not managed, and why not:** the terminal font is installed by hand from `IoskeleyMono-Term.zip` into `~/Library/Fonts`, because there is no cask for it — a fresh machine needs it dropped there before Ghostty renders as intended. Chrome keeps its settings in a file the app rewrites on quit, so it cannot be a symlink. VS Code and `~/.claude/` are user-level state. `~/.aws/config` and `~/.pgpass` hold reconnaissance material and secrets, and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

The things that will bite you, and nothing else:

- **tmux's prefix is `ctrl+b`, the same as herdr's.** Inside a herdr pane the outer one wins and tmux never sees it. That is affordable only because `herdr/config.toml` sets `allow_nested = false`, so herdr refuses to nest at all — the two are meant to sit side by side, not stacked. Wanting them stacked means moving one of the two prefixes.
- **fish is not POSIX.** `export FOO=bar`, `source .env` and `$(...)`-heavy snippets pasted from a README fail; use `set -gx`, or run them under `/bin/zsh -c`, which is why zsh stays installed with no config.
- **`$PATH` is set in `conf.d/00-env.fish`, and the `00-` prefix matters.** Homebrew's `vendor_conf.d/mise-activate.fish` sources after it and prepends the mise shims; sort the file later and `~/.bun/bin` shadows the mise-pinned runtime.
- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. That is deliberate — the change gets versioned instead of drifting.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** The Brewfile is the source of truth in both directions: an app you want to keep has to be declared, and deleting a line is how you uninstall — the `cleanup` run is what actually removes it, not the edit.
- **Hammerspoon and Maccy both need Accessibility permission**, granted by hand on first launch. Without it Hammerspoon's placements silently no-op — `init.lua` raises an alert when it detects the permission missing, which is the only reason you find out.
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` follows **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`. Claude does not: the terminal always runs the personal account, and the work one is only ever used from the web.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **eza reads `~/Library/Application Support/eza` on macOS**, not `~/.config`. `EZA_CONFIG_DIR` in [`fish/conf.d/00-env.fish`](./fish/conf.d/00-env.fish) is what makes the theme load at all; without it nothing fails, the theme is just never read.
- **The `ls` icons come from the Nerd Font symbols Ghostty embeds**, not from Ioskeley. Outside Ghostty — Terminal.app, a plain ssh client — `ls` shows boxes. `--icons=auto` only drops them when stdout is a pipe, not on another terminal.
- **`duti` hands `.json`, `.yaml`/`.yml`, `.toml`, `.ini` and `.cfg` to VS Code** from `install.sh`; `duti -x json` shows the current binding. A bare `config`, `tmux.conf` or `.env` cannot be bound from a script: macOS files them under `public.data` or a dynamic UTI, VS Code declares neither, and `duti` answers `error -50`. `public.plain-text` accepts the call and then stays on TextEdit. Those stay on Finder's "Open With → Always" or `code <file>`.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **The terminal font comes from no cask, and its family name is not its filename.** The files are `IoskeleyMonoTerm-*.ttf` in `~/Library/Fonts`; **the family CoreText registers is `Ioskeley Mono Term`**, which is what `ghostty/config` has to say. Check it with `ghostty +list-fonts`; a family CoreText cannot find falls back to Menlo silently, so the terminal still renders and nothing tells you the name was wrong.
- **`maximize`, not `fullscreen`.** Native macOS fullscreen moves the window to a Space of its own, where `hammerspoon/init.lua` can no longer tile it — `cmd+alt+2` would have nothing to place it beside.
- **`TERM` is `xterm-ghostty`, and ssh is covered.** `shell-integration-features = ssh-terminfo` copies the terminfo entry to the remote host on first connect, so `clear` and `less` keep working there without downgrading `TERM` locally.

## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```

## Notes

- macOS only. Prompts for your password once, for `chsh`, and for `sudo` only if fish is not yet in `/etc/shells`.
- Shell startup is ~40ms warm, measured end-to-end with `/usr/bin/time -p fish -l -i -c exit`.
