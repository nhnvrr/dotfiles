# dotfiles

macOS. zsh in Alacritty, herdr for agents and tmux for sessions, Hammerspoon for window layout, nvim and VS Code.

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
3. **Set Safari as the default browser** — System Settings → Desktop & Dock → *Default web browser*. That dialog is the only thing on this machine that can change the handler; macOS 27 ignores every scripted route (see Traps). `hammerspoon/mate/browser.lua` checks it on each load and raises an alert when it is not Safari, so you find out on the next reload rather than on the next link.
4. **Install the terminal font by hand** — it is the one thing `brew bundle` cannot do for you. The `font-ioskeley-mono` cask ships only the Normal build, with no Term cut, so it is not in the [`Brewfile`](./Brewfile) at all. Take `IoskeleyMono-Term.zip` from the [upstream release](https://github.com/ahatem/IoskeleyMono/releases) and drop the `IoskeleyMonoTerm-*.ttf` files into `~/Library/Fonts`. The plain Term build, not the Nerd Font one — nothing in this config prints a private-use glyph, for the reason in the traps below.
5. **Install Alacritty from the DMG and launch it once** — the Homebrew cask is disabled (see Traps), so take the release from <https://github.com/alacritty/alacritty/releases>, drop it in `/Applications`, run `xattr -dr com.apple.quarantine /Applications/Alacritty.app`, and `tic -xe alacritty,alacritty-direct extra/alacritty.info` from the same release for the terminfo. Font, window mode and `option_as_alt` come from [`alacritty/alacritty.toml`](./alacritty/alacritty.toml), and the colours come from Alacritty itself, so there is nothing to click.

## The stack

| Layer | Tool | Config |
|---|---|---|
| Shell | zsh — no framework. `PROMPT` is hand-written against `vcs_info`, with a `+vi-git-status` hook that gets all five markers from one `git status`. Stock `compinit` for completion, and the two Homebrew formulas that give back what fish had built in: `zsh-autosuggestions` and `zsh-syntax-highlighting` | [`zsh/zshrc`](./zsh/zshrc), [`zsh/prompt.zsh`](./zsh/prompt.zsh), [`zsh/zshenv`](./zsh/zshenv) |
| Terminal | Alacritty — no tabs, no splits; herdr and tmux do that. Window, font and keys, plus the one `import` line that is present in light and commented out in dark | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml), [`alacritty/light.toml`](./alacritty/light.toml) |
| Agents | herdr — agent state over its socket API, not a shell multiplexer | [`herdr/config.toml`](./herdr/config.toml) |
| Sessions | tmux — persistence across a disconnect, and the multiplexer that exists on a remote host; `prefix h/j/k/l` moves between panes, the same letters as the `ctrl+alt` set in Hammerspoon | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Quick questions | `ask`, or `??` for short — one-off question to Claude, read-only, web search when needed. Both aliases go through `noglob`, or the `?` ending the question globs | [`zsh/functions/ask`](./zsh/functions/ask), [`zsh/zshrc`](./zsh/zshrc) |
| Theme | Dark is Alacritty's own default. Light is the single palette written here, measured per slot on `#f4f2ed`. Everything downstream reads the sixteen ANSI slots and carries no colour of its own; which side is live follows the macOS appearance | [`alacritty/light.toml`](./alacritty/light.toml), [`bin/mate`](./bin/mate) |
| Editor | nvim on `vim.pack`, no plugin manager — treesitter, blink.cmp, conform, fzf-lua, gitsigns, neotest and dap. No colorscheme: the built-in one reads `background`. VS Code alongside it, user-level state, not configured here | [`nvim/`](./nvim) |
| `$EDITOR` | `code --wait` | [`zsh/zshenv`](./zsh/zshenv) |
| Browser | Safari, in every layout and as the default handler. Two keys name it — `browser` for what the layouts place, `defaultBrowser` for what opens a link — because they are separate jobs that happen to share an app. Chrome stays installed for work and is opened by hand. The handler is set by hand and only *checked* here | [`hammerspoon/mate/browser.lua`](./hammerspoon/mate/browser.lua), [`hammerspoon/mate/apps.lua`](./hammerspoon/mate/apps.lua) |
| Database | `psql` for scripts, `pgcli` for a shell with completion, DataGrip for anything interactive | — |
| Redis | `redis-cli` | — history path in [`zsh/zshenv`](./zsh/zshenv) |
| HTTP | `curl` for scripts and one-offs, Postman for anything interactive or worth saving as a collection | [`Brewfile`](./Brewfile) |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Fuzzy find | fzf + fd + bat | [`zsh/zshrc`](./zsh/zshrc) |
| Listing | BSD `ls` with `-G`, coloured through `LSCOLORS`. eza was here and is gone: it carried forty-five lines of `EZA_COLORS` comment to explain seven quirks, and `ls -lhG` says the same thing | [`zsh/zshrc`](./zsh/zshrc) |
| Monitoring | btop — four settings, the rest left at btop's defaults. `color_theme = "TTY"` so it follows the terminal's sixteen slots, `proc` first in `shown_boxes` sorted by `user`, and `net_auto = false` for a fixed scale | [`btop/btop.conf`](./btop/btop.conf) |
| Machine info | fastfetch — run by hand, no shell greeting; no colours of its own, so it follows the terminal slots like btop | — |
| Clipboard | Maccy | [`Brewfile`](./Brewfile) |
| Window layout | Hammerspoon — three workspaces on `cmd+alt+1/2/3`, rotated with `cmd+alt+R`; i3-style focus and halves on `ctrl+alt` | [`hammerspoon/mate/`](./hammerspoon/mate) |

Keys split by modifier: Alacritty takes `cmd`, Hammerspoon takes `cmd+alt` for the workspace and `ctrl+alt` for the i3-style bindings, zsh takes bare `ctrl`, and inside herdr or tmux `ctrl+b` is the prefix before any of it. **Bare `alt` is reserved for the terminal** — `option_as_alt = "Both"` in [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) is what makes `option+b` and `option+f` word-jump in the shell, and a Hammerspoon hotkey is global, so it would take those keys before the terminal saw them. That is why the i3-style bindings sit on `ctrl+alt` rather than the bare `alt` an i3 config would use.

| Binding | Does |
|---|---|
| `cmd+alt+1` | Hide every other application, then Alacritty and Safari on half the screen each |
| `cmd+alt+2` | VS Code on the left half and Safari on the right half |
| `cmd+alt+3` | VS Code on the left half, Safari top-right and Alacritty bottom-right |
| `cmd+alt+4` | Alacritty on the left half and Chrome on the right — `cmd+alt+1` with the work browser, and the only layout that places Chrome |
| `cmd+alt+R` | Move every occupant one slot along: a swap with two, `1 2 3` → `3 1 2` with three |
| `cmd+alt+0` | Toggle the display resolution |
| `cmd+alt+F` | Zoom the focused window to full screen and back |
| `cmd+alt+ctrl+R` | Reload the Hammerspoon config |
| ``cmd+` `` | Show the terminal, or hide it if it is already frontmost |
| `ctrl+alt+h/j/k/l` | Move focus west, south, north, east |
| `ctrl+alt+shift+h/j/k/l` | Put the focused window in that half |
| `cmd+alt+z` / `cmd+alt+x` | Put the focused window in the left or right half — the same motion on a pair you can hit without leaving the home row |
| `cmd+alt+c` | Centre it at two thirds — the same `motion.centre` as `ctrl+alt+c`, on the modifier the halves use. Takes `cmd+alt+c` from Finder, where it is "Copy as Pathname" |
| `ctrl+alt+-` / `ctrl+alt+=` | Shrink or grow its width, anchored on the nearer edge |
| `ctrl+alt+c` | Centre it at two thirds |
| `ctrl+alt+,` / `ctrl+alt+.` | Send it to the previous or next display |

This is **not** a tiling window manager and does not pretend to be one: there is no tree, nothing reflows when a window opens or closes, and two windows can overlap if you put them there. It is the part of i3 that gets used all day, without a new dependency.

`ask <question>` is a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. fish had a `?` abbreviation expanding to `ask ""`; zsh has no equivalent, because `?` is a glob character there too, so the function is typed by name.

## Theme

One colour file, [`alacritty/light.toml`](./alacritty/light.toml), and nothing else.

Dark is Alacritty's own default palette, which is the **absence** of an import
line — no file to maintain and nothing that can drift from anything. Light is
the one palette written here, because Alacritty ships no light mode at all and
the alternative was vendoring a theme with somebody else's name on it.

Everything downstream reads the terminal's sixteen ANSI slots instead of
carrying colours of its own, so the single `import` line above is the whole
switch:

| Consumer | How it follows |
|---|---|
| herdr | `[theme] name = "terminal"` — every hue comes from the ANSI slots. Three tokens per appearance are overridden, and only those; see below |
| nvim | no colorscheme: the built-in one reads `background`, and `mate` sets it |
| lualine | `theme = "auto"`, derived from whichever highlight groups are live |
| btop | `color_theme = "TTY"` |
| bat, delta | `syntax-theme = ansi` |
| `ls`, fzf, `psql` | `LSCOLORS`, ANSI names, raw SGR slots |
| tmux | by carrying no colours whatsoever — no `status-style`, so the bar keeps tmux's own default of `bg=green`, the *slot* and not a colour |

### The light palette, measured

Built against the background rather than by eye. Contrast on `#f4f2ed`:

| Slot | normal | | bright | |
|---|---|---|---|---|
| black | `#2f3033` | 11.79 | `#6b6862` | 4.96 |
| red | `#a32b31` | 6.37 | `#821f25` | 8.64 |
| green | `#3f6b1f` | 5.63 | `#2f5216` | 8.02 |
| yellow | `#7a5600` | 5.94 | `#5e4200` | 8.32 |
| blue | `#1b5c94` | 6.25 | `#134672` | 8.74 |
| magenta | `#783f9e` | 6.25 | `#5c2f7a` | 8.76 |
| cyan | `#0f6660` | 6.08 | `#0a4d48` | 8.66 |
| white | `#8a8780` | 3.20 | `#2f3033` | 11.79 |

Two things are deliberate and look like mistakes. **Bright is darker than
normal, not lighter**: on a pale ground "bright" has to mean *more* contrast,
and the usual lightening moves it the wrong way — bright red on white is the
classic unreadable slot. And **`normal white` is the only one under 4.5:1**, at
3.20, because it is the de-emphasis slot: comments, inactive text, the things
that are supposed to recede. Lifting it to the floor would defeat what it is
for.

### The six tokens ANSI cannot express

`terminal` fills herdr's palette from the sixteen slots, which works for every
hue and for the ground. It does not work for a *surface*: ANSI has no such
concept, and asked for one anyway `terminal` reaches for slot 8 — then hands
the same slot to the dimmed second row of the sidebar. The branch name was
drawn in exactly the colour it sat on:

| | row fill | branch text | contrast |
|---|---|---|---|
| light | `#6b6863` | `#6b6863` | 1.00 |
| dark | `#6b6b6b` | `#6b6b6b` | 1.00 |

Invisible in both appearances, and not fixable from the palette — in dark the
slot is Alacritty's own default, which this repo does not set. So
[`herdr/config.toml`](./herdr/config.toml) overrides three tokens per mode and
nothing else: `active_row_bg` and `selection_bg`, the two surfaces, and
`overlay0`, the dim text that has to stay legible on them.

| | light on `#f4f2ed` | dark on `#181818` |
|---|---|---|
| row against the panel | 1.21 | 1.25 |
| text on the row | 9.73 | 9.93 |
| branch on the row | 5.08 | 5.41 |
| branch on the selection | 4.61 | 4.35 |

Every hue still comes from the terminal. These are the only hexes in the file.

### Following the system

[`bin/mate`](./bin/mate) is the switch. `mate` toggles, `mate light|dark`
forces, `mate auto` follows macOS, `mate status` prints. Hammerspoon calls
`mate auto` from an `AppleInterfaceThemeChangedNotification` watcher in
[`hammerspoon/mate/appearance.lua`](./hammerspoon/mate/appearance.lua).

It writes two files and one state word:

```
~/.config/alacritty/alacritty.toml   the repo file, import line on or off
~/.config/herdr/config.toml          the repo file, [theme.custom.<mode>]
                                     flattened into [theme.custom]
~/.local/state/mate/appearance       the word `light` or `dark`
```

`alacritty.toml` is **generated, not linked**: `live_config_reload` does not see
through a symlink, so a linked config never reloads at all — the file Alacritty
was launched with has to be the one that changes.

The line is rewritten with `awk` comparing `$0` to the literal string, not with
`sed`. It is full of `[`, `]`, `/`, `.` and quotes, and escaping all of them
into a regex is how the first version of this broke.

herdr's hues need nothing — it is already reading the slots Alacritty is
serving — but `auto_switch` would have to wait for DEC mode 2031, which
Alacritty 0.17 does not send, so the per-mode block is flattened here instead.
nvim watches the state file with an `fs_event`, plus `FocusGained` for a flip that
happened while it was suspended; because that event does not always survive,
each instance also leaves a socket under `~/.local/state/mate/nvim/` and `mate`
pokes it with `:MateAppearance`.

### Transparency

`alacritty.toml` sets no `opacity`, so the ground behind the editor is the
terminal's own background and not the desktop. Nothing here is translucent.

## Managed files

| Repo | Destination |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/functions/` | `~/.config/zsh/functions` |
| `zsh/prompt.zsh` | `~/.config/zsh/prompt.zsh` |
| `alacritty/light.toml` | `~/.config/alacritty/light.toml` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `herdr/sounds/done.mp3` | `~/.config/herdr/sounds/done.mp3` |
| `herdr/sounds/request.mp3` | `~/.config/herdr/sounds/request.mp3` |
| `nvim/` | `~/.config/nvim` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `hammerspoon/mate/` | `~/.hammerspoon/mate` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files, except `zsh/functions/`, `nvim/` and `hammerspoon/mate/`, which are linked as directories so a new file inside them needs no install step. herdr is the opposite case and deliberately file-by-file: it keeps its sockets, logs and `session.json` in `~/.config/herdr`, all written at runtime, so the directory cannot be a link into the repo. zsh has no single config directory to link: `.zshenv` and `.zshrc` are read from `$HOME` by name. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

Two files are missing from this list because they are *generated* rather than
linked, both by [`bin/mate`](./bin/mate) and both seeded once by `install.sh`:
`~/.config/alacritty/alacritty.toml`, the repo file with its `import` line
present or commented out, and `~/.config/herdr/config.toml`, the repo file with
the matching `[theme.custom.<mode>]` block flattened into `[theme.custom]`.
Neither can be a symlink into the repo — Alacritty would never reload it, and
for herdr the generator would overwrite its own input.

**Not managed, and why not:** the terminal font is installed by hand from `IoskeleyMono-Term.zip` into `~/Library/Fonts`, because there is no cask for it. **Alacritty itself** comes from the upstream DMG, because its Homebrew cask is disabled — see Traps. Chrome keeps its settings in a file the app rewrites on quit, so it cannot be a symlink. VS Code and `~/.claude/` are user-level state. `~/.aws/config` and `~/.pgpass` hold reconnaissance material and secrets, and this repo is public — write them by hand (`chmod 600 ~/.pgpass`).

## Traps

The things that will bite you, and nothing else:

- **`$PATH` is set in `zsh/zshenv`, and that is not where it ends up.** macOS ships `/etc/zprofile`, which runs `path_helper` *after* `.zshenv` for every login shell and hoists `/usr/bin` and `/bin` back to the front. Anything that must win the lookup has to prepend later than that, which is why `mise activate` is the last `eval` in `zshrc` and not an entry in the `path` array — sort it earlier and `~/.bun/bin` shadows the mise-pinned runtime. Homebrew's `vendor_conf.d` did this for fish automatically; for zsh nothing does.
- **`zsh-syntax-highlighting` must be sourced last of all.** It wraps the ZLE widgets that exist at the moment it loads, so anything binding keys after it is simply not highlighted, silently. `zsh-autosuggestions` goes immediately before it for the same reason.
- **`~/.gitconfig` is a symlink into this repo**, so `git config --global …` writes here and the repo shows dirty. That is deliberate — the change gets versioned instead of drifting.
- **`brew bundle cleanup` uninstalls anything not in the Brewfile.** The Brewfile is the source of truth in both directions: an app you want to keep has to be declared, and deleting a line is how you uninstall — the `cleanup` run is what actually removes it, not the edit.
- **The `alacritty` cask is `disable!`d in Homebrew since 2026-09-01** (`fails_gatekeeper_check`), so `brew bundle` refuses it — an uncommented line would abort the whole run, which is why the one in the [`Brewfile`](./Brewfile) is commented and the app comes from the upstream DMG with the quarantine attribute stripped. `brew bundle cleanup` does not touch it, because Homebrew never installed it, and updates are by hand.
- **`TERM` is `alacritty`, and `ssh` is not covered.** Alacritty ships no shell integration, so a remote host without the terminfo entry breaks `clear` and `less`. Either `TERM=xterm-256color ssh host` for the odd machine, or install it once: `infocmp -x alacritty | ssh host tic -x -`.
- **No tabs, no splits, no "new window in the same directory".** Alacritty is one surface per window and has no shell integration to inherit the cwd. Splits are herdr, or tmux (`prefix |`, `prefix -`); `cmd+n` opens in `$HOME`.
- **herdr's prefix is `ctrl+b`, the same as tmux's.** Inside a herdr pane the outer one wins and tmux never sees it. That is affordable only because [`herdr/config.toml`](./herdr/config.toml) sets `allow_nested = false`, so herdr refuses to nest at all — the two are meant to sit side by side, not stacked. Wanting them stacked means moving one of the two prefixes.
- **herdr's `[ui.sound]` paths are relative on purpose, and that is load-bearing.** herdr resolves them from the config file's directory, and that file is a symlink — so `sounds/done.mp3` lands either in `~/.config/herdr/` or in the repo, depending on whether herdr calls `realpath` first. `install.sh` links the two sounds into `~/.config/herdr/sounds/` precisely so both readings hit a real file and the ambiguity stops mattering.
- **`cmd+k` is remapped to send `ctrl-l`.** Alacritty's default binds it to `ClearHistory`, which wipes the scrollback; the override in [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) lets the shell (or tmux, or herdr, or nvim) do the clearing instead.
- **The workspace hides, it never minimises.** `cmd+alt+1` puts every other application away with `app:hide()`, which is per-application and instant. Minimising is per-window and runs the Dock's genie animation, which is the slowest thing a layout can ask macOS to do — it is what made the previous version of this config feel sluggish. Hiding also keeps the windows: a hidden app hands its window straight back on `unhide()` in the same tick, which is why `cmd+alt+1` re-places both halves in about 20 ms when nothing has to launch.
- **`cmd+alt+R` is stateful, and the state is `workspace.M.current`.** The rotation is not derived from where the windows currently are — it is an ordered list of occupants that `rotate()` cycles and the slot geometry reads positionally. So pressing `cmd+alt+1` after a rotation rebuilds the *rotated* arrangement, not the original one, and the only thing that resets it is a Hammerspoon reload.
- **A slot holds an application, not one of its windows.** A second Terminal window opened by hand used to sit on top of the browser's half when `cmd+alt+1` placed the workspace. Every layout now puts *all* of an application's standard windows into its slot, the primary one last so it ends on top. Repeating a layout stays cheap because `frame.placeWindow` returns early on a window already in place, so only the strays move.
- **The launch watcher has to skip the workspace's own two apps, and `frame.claimed` is not enough to make it.** The watcher maximises anything newly launched, and a layout claims a bundle ID to opt out of that — but the claim is released the instant the layout has placed its window, while the watcher is off waiting for a window of its own. On a browser that had to be launched from cold the two waits resolve in the wrong order often enough to see it: `cmd+alt+1` would place the browser in its half and the watcher would maximise it a moment later. It now ignores any bundle in `M.order` outright.
- **A window that refuses a frame keeps the one it had, and `applyFrame` gives up rather than looping.** Apps with a minimum size — preferences windows, some Electron builds — simply do not take the rect. The log says so once; nothing on screen does.
- **The default browser cannot be set from a script on macOS 27, and nothing tells you it failed.** `hs.urlevent.setDefaultHandler` and `duti` both call the deprecated `LSSetDefaultHandlerForURLScheme`; on 27.0 (26A5425a) it is accepted and ignored. Measured in both directions, so it is the API and not a quirk of one app: with Chrome as the handler, setting it to Helium left it on Chrome; with Helium as the handler, setting it back to Chrome left it on Helium. Helium is what this config placed when the measurement was taken — the finding is about LaunchServices, not about either browser. `duti -s net.imput.helium http all` answers `failed … (error -50)` because it maps the scheme to a dynamic UTI, and the `public.html` form returns success while changing nothing. The only thing that works is the browser asking for itself through `NSWorkspace` — Chrome's first-run prompt, its *Make default* button, or System Settings. `mate/browser.lua` still makes the call, because it is the right one on the versions that honour it, then reads the handler back and raises an alert when it did not take. The silence is the bug being worked around, not the failure.

- **`GAP` is one distance, and `frame.frameFor` splits it in half to get there.** Half comes off the screen before the slot fractions are taken and half off the slot afterwards, so the two halves meet at every internal seam and add up to a full `GAP` at the screen edge. A window sits `GAP` off the edge and two neighbours sit `GAP` apart — the same number, which is the point. It used to be per-window padding, which made the middle seam twice the outer margin. No slot has to know what sits next to it either way. The one thing that bites: `frame.frameMatches` treats anything within 4pt as already in place, which is what makes repeating a layout free, so nudging `GAP` by 1 or 2 changes the numbers and moves nothing on screen. Either change it by more, or move the window out of its slot first so the next layout has to re-place it.

- **Watchers are held on their module table, never left anonymous.** Hammerspoon garbage-collects an `hs.application.watcher` or `hs.pathwatcher` whose only reference was the expression that started it. The failure is silent and arrives minutes later: newly launched apps stop being placed, and nothing appears in the log. Same reason the hotkeys are collected into a table in `mate/keys.lua`.
- **Layouts target the main screen; motions follow the window.** `cmd+alt+1` and `cmd+alt+R` are statements about the workspace, so they build on `hs.screen.mainScreen()`. Halves, centre, resize and zoom are statements about the window in front of you, so they use `win:screen()`. Getting a window across displays is `ctrl+alt+,` / `ctrl+alt+.` and never a side effect of a half.
- **Hammerspoon and Maccy both need Accessibility permission**, granted by hand on first launch. Without it Hammerspoon's placements silently no-op — `init.lua` raises an alert when it detects the permission missing, which is the only reason you find out.
- **`~/.aws/config` has no `[default]` profile on purpose.** Without one every command fails with `NoCredentials` unless `AWS_PROFILE` is set, which is what stops a command from silently hitting the wrong account. `AWS_PROFILE` follows **the directory you are in**: `work` under `~/work`, personal everywhere else, re-evaluated on every `cd`. Claude does not: the terminal always runs the personal account, and the work one is only ever used from the web.
- **`psql` reads `psqlrc` non-interactively too.** A script parsing output sees the `Ø` for NULL and the unicode borders. Use `psql -X`.
- **There is deliberately no `~/.curlrc`.** That file is read by *every* curl invocation, Homebrew's installer included.
- **A Symbols-Only Nerd Font does not rescue a terminal, because CoreText's fallback stops at the BMP Private Use Area.** This is worth stating flatly, since the obvious assumption is the opposite one and it cost an afternoon: macOS *does* have a cascade list, and it *does* reach third-party families — but not for `U+E000`–`U+F8FF`, which is where the seti, devicon, font-awesome, octicon and powerline sets live. Asking `CTFontCreateForString` with the unpatched base family:

  | codepoint | set | fallback family |
  |---|---|---|
  | `U+E5FF` | seti | `.LastResort` |
  | `U+E73C` | devicon | `.LastResort` |
  | `U+F07B` | font-awesome | `.LastResort` |
  | `U+F0219` | material design, plane 15 | `Symbols Nerd Font` |

  Only the plane-15 range resolves, so a separate icon font is not a substitute: the face itself would have to carry the glyphs. **Which is why this config prints none.** That is not a workaround, it is the cheaper half of the trade — `ls` is BSD `ls -lhG`, the git prompt uses `* + ? $ !`, lualine has `icons_enabled = false`, neo-tree draws folders with `+` and `-`, neotest uses `+ x ~ -`, and diagnostics are `E W I H`. So the terminal runs the plain `Ioskeley Mono Term` and an `ssh` into a host without the font still gives a readable prompt. The two non-ASCII exceptions are emoji, not icons: the 🧉 in the zsh prompt and a variation selector in the Hammerspoon config, both served by Apple Color Emoji.
- **`duti` hands `.json`, `.yaml`/`.yml`, `.toml`, `.ini` and `.cfg` to VS Code** from `install.sh`; `duti -x json` shows the current binding. A bare `config`, `tmux.conf` or `.env` cannot be bound from a script: macOS files them under `public.data` or a dynamic UTI, VS Code declares neither, and `duti` answers `error -50`. `public.plain-text` accepts the call and then stays on TextEdit. Those stay on Finder's "Open With → Always" or `code <file>`.
- **A symlinked config that the app rewrites writes into this repo.** `install.sh` already generates Alacritty's and herdr's configs as real files for exactly this reason, but btop and `gh` are linked, and both save their own state. btop is the loud one: `save_config_on_exit` defaults to **true**, so quitting it replaced [`btop/btop.conf`](./btop/btop.conf) with 79 lines of generated defaults, six times in this repo's history. It is now explicitly `false`. `gh` is quieter — it rewrites only the keys you `gh config set`, and re-indented the `aliases` block on its own at least once.
- **Both of those files now hold only what differs from the tool's default,** which is why they are short. Checked against btop 1.4.7's own `btop_config.cpp`: 74 of the 79 settings in the old file were the default value spelled out. `gh` reads a two-key config and fills the rest in, verified with `gh config get spinner` against the trimmed file.
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **The terminal font comes from no cask, and its family name is not its filename.** The files are `IoskeleyMonoTerm-*.ttf` in `~/Library/Fonts`; **the family CoreText registers is `Ioskeley Mono Term`**, spaced, which is what [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) has to say. A family CoreText cannot find falls back to Menlo *silently* — the terminal still renders and nothing tells you the name was wrong. `system_profiler SPFontsDataType | grep -i "Family: Ioskeley"` lists what is actually registered. Every weight past the four regular faces gets its own family name, so they are separate families in a picker, not styles of one.
- **Never native fullscreen.** macOS fullscreen moves a window to a Space of its own, where `hammerspoon/init.lua` can no longer tile it — `cmd+alt+1` would have nothing to place it beside. Maximise instead. The bundle IDs live in `hammerspoon/mate/apps.lua`: `org.alacritty` and `com.google.Chrome`, the two lines to change if either app ever does.
- **The dark palette has no source in this repo, and something tuned against it that does.** In dark mode Alacritty declares no colours, so the sixteen slots are its built-in defaults and live in its source, not here. What is tuned against them and does live here is herdr's three dark tokens, measured against Alacritty's `#181818` and its slot 8. An Alacritty release that moves either leaves them holding values that no longer match anything, silently — and `git log` in this repo will show nothing, because nothing here changed.
- **Three of the fifteen text slots are under 4.5:1**, including slot 1 at 3.05:1 (error red) and slot 8 at 3.33:1 (the zsh autosuggestion and fzf's info line). That is a property of Alacritty's defaults, taken knowingly — see Theme for the numbers. Declaring `[colors.normal].red` and `[colors.bright].black` in `alacritty.toml` is the two-line repair if it ever stops being acceptable.


## Homebrew

```bash
brew bundle check --file=./Brewfile     # what's missing
brew bundle --file=./Brewfile           # install it
brew bundle cleanup --file=./Brewfile   # uninstall what's not declared
```

## Notes

- macOS only. Prompts for your password once, for `chsh`. There is no `sudo` step any more: `/bin/zsh` ships in `/etc/shells`, which fish never did.
- Shell startup is ~60ms warm, measured end-to-end with `/usr/bin/time -p zsh -l -i -c exit`. fish was ~40ms — zsh pays for `compinit`, `mise activate` and the two plugin sources, none of which fish needed. It was ~70ms with a prompt framework in the chain; the hand-written `PROMPT` in [`zsh/prompt.zsh`](./zsh/prompt.zsh) is what bought that back, by getting all five git markers out of one `git status` (~30ms) instead of the five calls `vcs_info` makes on its own (~80ms).
