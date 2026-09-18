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
| Terminal | Alacritty — no tabs, no splits; herdr and tmux do that. Window, font and keys, plus the one `import` that pulls in whichever palette is active | [`alacritty/alacritty.toml`](./alacritty/alacritty.toml), [`alacritty/mate.toml`](./alacritty/mate.toml), [`alacritty/mate-light.toml`](./alacritty/mate-light.toml) |
| Agents | herdr — agent state over its socket API, not a shell multiplexer | [`herdr/config.toml`](./herdr/config.toml) |
| Sessions | tmux — persistence across a disconnect, and the multiplexer that exists on a remote host; `prefix h/j/k/l` moves between panes, the same letters as the `ctrl+alt` set in Hammerspoon | [`tmux/tmux.conf`](./tmux/tmux.conf) |
| Quick questions | `ask` — one-off question to Claude, read-only, web search when needed | [`zsh/functions/ask`](./zsh/functions/ask) |
| Theme | Mate and Mate Light — written here, measured per slot on `#1f1f1f` and `#f2f1ee`. Read back from the terminal by everything that can; the editors run luna instead. Which one is live follows the macOS appearance | [`alacritty/mate.toml`](./alacritty/mate.toml), [`alacritty/mate-light.toml`](./alacritty/mate-light.toml), [`bin/mate`](./bin/mate) |
| Editor | nvim on `vim.pack`, no plugin manager — treesitter, blink.cmp, conform, fzf-lua, gitsigns, neotest and dap, themed with `luna.nvim` in both appearances. VS Code alongside it, user-level state, not configured here. Zed is here too, settings and the `Mate` / `Mate Light` themes | [`nvim/`](./nvim), [`zed/`](./zed) |
| `$EDITOR` | `code --wait` | [`zsh/zshenv`](./zsh/zshenv) |
| Browser | Safari, in every layout and as the default handler. Two keys name it — `browser` for what the layouts place, `defaultBrowser` for what opens a link — because they are separate jobs that happen to share an app. Chrome stays installed for work and is opened by hand. The handler is set by hand and only *checked* here | [`hammerspoon/mate/browser.lua`](./hammerspoon/mate/browser.lua), [`hammerspoon/mate/apps.lua`](./hammerspoon/mate/apps.lua) |
| Database | `psql` for scripts, `pgcli` for a shell with completion, DataGrip for anything interactive | — |
| Redis | `redis-cli` | — history path in [`zsh/zshenv`](./zsh/zshenv) |
| HTTP | `curl` | — |
| Git | SSH-signed commits, delta as pager | [`git/gitconfig`](./git/gitconfig) |
| Runtimes | mise | [`mise/config.toml`](./mise/config.toml) |
| Fuzzy find | fzf + fd + bat | [`zsh/zshrc`](./zsh/zshrc) |
| Listing | BSD `ls` with `-G`, coloured through `LSCOLORS`. eza was here and is gone: it carried forty-five lines of `EZA_COLORS` comment to explain seven quirks, and `ls -lhG` says the same thing | [`zsh/zshrc`](./zsh/zshrc) |
| Monitoring | btop — `color_theme = "TTY"`, so it follows the terminal's sixteen slots | [`btop/btop.conf`](./btop/btop.conf) |
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
| `ctrl+alt+-` / `ctrl+alt+=` | Shrink or grow its width, anchored on the nearer edge |
| `ctrl+alt+c` | Centre it at two thirds |
| `ctrl+alt+,` / `ctrl+alt+.` | Send it to the previous or next display |

This is **not** a tiling window manager and does not pretend to be one: there is no tree, nothing reflows when a window opens or closes, and two windows can overlap if you put them there. It is the part of i3 that gets used all day, without a new dependency.

`ask <question>` is a one-off question, streamed. The first word lands at ~1.7s no matter how long the answer runs; buffered, nothing appears until it is finished, which is 2.4s for one line and 9.2s for a long one. So the gain scales with the answer and is nil on a two-word reply. Answers needing live data cost ~12s and cite their sources.

It is read-only by construction: `--disallowedTools` blocks the file and shell tools, because `--allowedTools` only auto-approves and does not restrict. fish had a `?` abbreviation expanding to `ask ""`; zsh has no equivalent, because `?` is a glob character there too, so the function is typed by name.

## Theme

**Mate**, written here rather than taken from anywhere. It is the first palette
this repo has owned: before it, Alacritty ran its compiled-in Base16 Default
Dark and nothing here versioned a single slot.

[`alacritty/mate.toml`](./alacritty/mate.toml) is the source. `alacritty.toml`
imports it and overrides nothing, so everything that reads the terminal follows
for free — tmux, btop, bat, delta, fzf, `ls`, psql.

Three off-the-shelf palettes were tried first and all three were rejected in
use. The pass after them failed for a reason worth writing down: **it forced
every slot into 6.9–8.2:1 and the palette flattened.** Uniform contrast is not
the goal — with no value spread and low chroma, six hues read as one pastel
family. What the palette is actually built against is three numbers:

| | target | result |
|---|---|---|
| contrast on `#1f1f1f` | every text slot in 4.5:1–14:1 | **4.69:1 – 12.33:1** |
| hue separation | adjacent hues ΔE ≥ 25 | **41.8 – 66.9** |
| normal → bright | same hue, ΔE 8–20 | **12.4 – 16.2** |

| slot | | | on `#1f1f1f` |
|---|---|---|---|
| 1 | red | `#e05f5f` | 4.69:1 |
| 5 | magenta | `#b578d9` | 5.22:1 |
| 4 | blue | `#5b9bd5` | 5.57:1 |
| 6 | cyan | `#4fb3ab` | 6.57:1 |
| 8 | bright black | `#a6a6a6` | 6.77:1 |
| 2 | green | `#86b45e` | 6.83:1 |
| 3 | yellow | `#d9a03f` | 7.10:1 |
| 9 | bright red | `#ff8b8b` | 7.31:1 |
| 13 | bright magenta | `#d5a0f5` | 7.99:1 |
| 12 | bright blue | `#83bdf2` | 8.26:1 |
| 14 | bright cyan | `#75d6cd` | 9.62:1 |
| 10 | bright green | `#a9d67c` | 9.89:1 |
| 11 | bright yellow | `#f5c268` | 10.05:1 |
| 7 | white | `#c8ccd2` | 10.22:1 |
| 15 | bright white | `#dcdfe3` | 12.33:1 |

Nothing under the 4.5:1 floor, where the Base16 defaults failed on three slots —
slot 1 at 3.05:1 and slot 8 at 3.33:1, the two that carry diagnostics and the
autosuggestion. Nothing over 14:1 either: a band reaching 17–20:1 is halation
over a full day, not legibility. Slot 1 at 4.69:1 is the one with no room left;
it is what stops the ground going lighter than it already is.

Hue separation is where the borrowed candidates lost. Base16 put `blue`/`cyan`
at ΔE 20.7 and luna gives them the same hex, ΔE 0.0. Here the closest adjacent
pair is 41.8, so no two slots read as one colour.

`#1f1f1f` is the ground: dark enough to hold the band under 14:1, light enough
for floats and popups to sit above it. It started at `#181818` and was lifted
+3.5 L* for a reason that no contrast table catches — at this desk the darker
ground turned the screen into a mirror, and a reflection sitting in the middle
of the text is its own kind of illegible. The lift costs every slot ~7% of its
ratio, which the table above absorbs; the sixteen hues themselves did not move.
The neutrals above the ground and the two fills moved with it, one uniform
step, so the ramp kept its spacing.

### Mate Light

The dark ground lost an argument with physics. `#1f1f1f` emits about 4 nits on
a 300-nit panel and a lit room bounces 5 to 30 off the glass, so at this desk
the screen worked as a mirror and the reflection sat in the middle of the text.
No value that is still a dark theme wins that: reaching 22 nits means `#4d4d4d`,
where slot 1 falls to 2.40:1. Mate Light emits ~264 and ends the argument.

It is the same six hues. Each slot keeps its hue angle and its chroma from
Mate; only lightness moves, solved so the slot lands on a contrast target
against the new ground. Mirroring Mate's own ratios one-to-one was the first
attempt and it failed on yellow — matching 7.10:1 puts it at L\* 24, which is
brown, not yellow. The targets are assigned by role instead, and the band comes
out flatter than Mate's as a result:

| | target | result |
|---|---|---|
| contrast on `#f2f1ee` | every text slot in 4.5:1–14:1 | **4.68:1 – 12.40:1** |
| hue separation | adjacent hues ΔE ≥ 25 | **41.2 – 66.3** |
| normal → bright | same hue, ΔE 8–20 | **9.3 – 12.8** |

| slot | | | on `#f2f1ee` |
|---|---|---|---|
| 3 | yellow | `#906300` | 4.68:1 |
| 8 | bright black | `#6b6b6b` | 4.72:1 |
| 6 | cyan | `#06756e` | 4.92:1 |
| 2 | green | `#467322` | 4.98:1 |
| 1 | red | `#b4393e` | 5.17:1 |
| 5 | magenta | `#8249a5` | 5.40:1 |
| 4 | blue | `#08649a` | 5.63:1 |
| 11 | bright yellow | `#705000` | 6.55:1 |
| 14 | bright cyan | `#015d57` | 6.87:1 |
| 10 | bright green | `#305c05` | 6.99:1 |
| 9 | bright red | `#912a33` | 7.20:1 |
| 13 | bright magenta | `#663984` | 7.49:1 |
| 12 | bright blue | `#004f78` | 7.78:1 |
| 7 | white | `#36393d` | 10.27:1 |
| 15 | bright white | `#2a2c2f` | 12.40:1 |

**The neutral slots are inverted, and that is a decision and not an oversight.**
Slot 0 is `#e2e2e2` at 1.15:1 — a light grey called `black` — and slot 7 is the
dark `#36393d`. The alternative is the Solarized Light convention, where slot 0
stays dark and slots 7 and 15 sit near the background at about 1.2:1, below the
floor this palette holds everywhere else. Inverting keeps the *contrast of every
pair* rather than the name of every slot, so nothing is ever drawn unreadably.
The price is that a program asking for black on white gets the pair the other
way round. Nothing here does, and legibility was the thing worth keeping.

### Following the system

Alacritty 0.17 cannot follow the macOS appearance. herdr and Zed both can, so
only the terminal needs help, and everything that reads its slots back comes
along for free once it flips.

```

  appearance switch, top to bottom

    macOS appearance change
             │
             ▼
    hs.distributednotifications      hammerspoon/mate/appearance.lua
             │
             ▼
    bin/mate
             │
             ├──► ~/.config/alacritty/alacritty.toml     import line rewritten
             │              │
             │              ▼
             │        live_config_reload ──► terminal repaints
             │                                     │
             │                                     ▼
             │                        tmux, btop, bat, delta,
             │                        fzf, ls, psql
             │
             ├──► ~/.config/herdr/config.toml ──► server reload-config
             │
             ├──► ~/.local/state/mate/appearance         one word
             │              │
             │              ▼
             │        nvim's fs_event, and FocusGained
             │
             └──► ~/.local/state/mate/nvim/<pid>.sock
                            │
                            ▼
                      :MateAppearance, per running instance

    Zed is not on this path: "mode": "system" asks macOS directly.

  legend: ──► writes to or triggers
```

Three consequences worth stating.

**nvim gets reloaded three ways**, because none of them is reliable alone. It
watches the state file with a libuv `fs_event`; it re-checks on `FocusGained`
for a flip that happened while it was suspended; and each instance leaves a
socket at `~/.local/state/mate/nvim/<pid>.sock`, which `mate` uses to run
`:MateAppearance` in it directly. Stale sockets are unlinked when the pid is
gone. `:MateAppearance light|dark` also works by hand.

**`~/.config/alacritty/alacritty.toml` is generated, not linked.**
`live_config_reload` does not see through a symlink: with the config linked
into the repo, editing it changed nothing and the running terminal kept the
import list it was launched with. `mate` writes the real file, rewriting the
one `import` line to name `mate.toml` or `mate-light.toml`. The palettes
themselves stay linked — their contents never change, only which one is named.

**herdr's `auto_switch` is off, and its config is generated.** The docs say it
switches when the host terminal *reports* an appearance change, which is DEC
private mode 2031; Alacritty 0.17 does not implement it, so it would never
fire. herdr has no include directive either — 208 config keys, none of them —
and its socket API exposes no theme surface to force. So the repo file carries
both `[theme.custom.dark]` and `[theme.custom.light]`, and
`bin/mate` flattens the matching one into the plain `[theme.custom]`
that herdr always applies, writing the result to `~/.config/herdr/config.toml`
and calling `herdr server reload-config`.

That destination is a real file and **must not** be a symlink back into the
repo: redirecting the generator's output into a link to its own input truncates
the source before `awk` reads a byte of it. The generator refuses to run when
the two paths resolve to the same file, and `install.sh` removes the link if it
finds one.

### herdr

`[theme.custom]` in [`herdr/config.toml`](./herdr/config.toml) is told hexes
rather than slots, because a sidebar needs the ramp between background and
foreground and the sixteen slots expose only its ends. There are two of them in
the repo file, `[theme.custom.dark]` and `[theme.custom.light]`, and the
generator described above flattens one of them into the section herdr actually
reads. A ground and its ramp cannot be shared, which is why there is no plain
`[theme.custom]` block for both to inherit from.

Two things the [config reference](https://herdr.dev/) settles, both of which
were guessed wrong first:

- The selected row is **`active_row_bg`** (active Space, focused Agent) and
  **`selection_bg`** (Navigate-mode cursor). `overlay0` and `overlay1` are
  separators and dim label text, *not* the row — darkening them to fix the row
  only made `spaces`, `agents` and the branch subtitles unreadable.
- **There is no border or outline token.** The selection can only be a fill, so
  a ring around the selected item is not available in 0.9.1.

Both fills are tinted toward the blue slot rather than left neutral: at the same
lightness a tint reads as *selected* and a grey reads as dirt. The ramp:

| token | | | draws |
|---|---|---|---|
| `active_row_bg` | `#303540` | 1.34:1 | the selected row |
| `selection_bg` | `#383f4b` | 1.55:1 | the Navigate cursor |
| `overlay0` | `#a6a6a6` | 6.77:1 | separators, the faintest labels |
| `overlay1` | `#b0b4ba` | 7.91:1 | dim text |
| `subtext0` | `#bcc0c6` | 9.02:1 | the row subtitle |
| `text` | `#c8ccd2` | 10.22:1 | the row name |

And the light ramp, solved against `#f2f1ee` to the same two fill ratios:

| token | | | draws |
|---|---|---|---|
| `active_row_bg` | `#c9d3e1` | 1.34:1 | the selected row |
| `selection_bg` | `#b8c5d6` | 1.55:1 | the Navigate cursor |
| `overlay0` | `#6b6b6b` | 4.72:1 | separators, the faintest labels |
| `overlay1` | `#5c5c5c` | 5.92:1 | dim text |
| `subtext0` | `#43464a` | 8.40:1 | the row subtitle |
| `text` | `#36393d` | 10.27:1 | the row name |

The fills stay under 1.6:1 so the row is a raise and not a slab; the contrast the
row needs comes from its text, 6.73:1 for the subtitle over `#303540` and 6.27:1
over `#c9d3e1`. Both fills were re-derived when the ground moved rather than
shifted blindly, so they hold the same 1.34:1 and 1.55:1 they had on `#181818`.

### Editors

nvim and Zed both run [`luna.nvim`](https://github.com/WTFox/luna.nvim) by wtfox
on the same ground as the terminal, and **they do not follow the sixteen slots
above.** nvim loads the colorscheme itself and borrows only the background back,
in [`nvim/lua/mate/init.lua`](./nvim/lua/mate/init.lua).
[`zed/themes/mate.json`](./zed/themes/mate.json) is luna's own Zed theme, from
its `extras/zed/`, merged into one family: `Mate` from `luna.json` and
`Mate Blur` from `luna-blur.json`, with luna's `#060606` swapped for `#1f1f1f`
— which in the blur variant carries its alpha, `#1f1f1fdd` for the window and
`#1f1f1f00` for the editor and terminal panes.

**luna is dark-only**, so the light side is luna's own palette re-solved rather
than a second colorscheme. Every colour keeps its hue and chroma and moves only
in lightness, to the value that reproduces the contrast it had on `#1f1f1f` —
the same method the sixteen slots got, applied to the 32 colours luna defines.
The result is a lookup table in
[`nvim/lua/mate/light.lua`](./nvim/lua/mate/light.lua), fed back through
`on_colors`, which buys every highlight group luna ships instead of a second
set to maintain. [`zed/themes/mate-light.json`](./zed/themes/mate-light.json) is
the same transform run over the Zed theme, `Mate Light` and `Mate Light Blur`.
A colour that sat *below* the dark ground is solved *above* the light one, so
the stacking order of the surfaces survives the flip.

Two details travel with the nvim swap: luna blends `line_nr` and the three diff
tints against `bg` at load and stores the result, so they are recomputed beside
it, and lualine's theme is patched in [`nvim/lua/ui.lua`](./nvim/lua/ui.lua)
because it reads `luna.palette` directly and never sees `on_colors`. The cost is
inside the popups: luna's `comment`, `#7c7c7c`, reads 4.85:1 on its own `#060606`
and would fall to 3.95:1 here, under the floor the rest of the palette holds. It
is overridden to `#868686`, 4.53:1, in the same `on_colors` hook and in the Zed
theme beside it. The light side inherits the same miss, faithfully, and gets the
same lift: `#6e6e6e`, 4.51:1, the lightest grey that still clears the floor.

Zed reads loose themes from `~/.config/zed/themes/*.json`, so there is no
extension to build and saving the file reloads it live.

### Transparency

`alacritty.toml` sets no `opacity`, so the ground behind the editor is the
terminal's own background and not the desktop. The `Blur` variants in Zed are
the one place anything is translucent, in both appearances.

### The one hand-kept copy

Everything else either reads a slot from the terminal or loads luna itself. One
consumer does neither.

The count is worth stating plainly, because it grew: the ground now lives in
`alacritty/mate.toml`, `alacritty/mate-light.toml`, `herdr/config.toml`,
`zed/themes/mate.json`, `zed/themes/mate-light.json` and
`nvim/lua/mate/init.lua` — six copies. The generator that used to derive them from one
palette file is gone, and nothing has replaced it.

| Consumer | Where |
|---|---|
| Hammerspoon | the focus ring in [`hammerspoon/mate/border.lua`](./hammerspoon/mate/border.lua) is slots 4 and 12 as hexes rather than as indices, `#5b9bd5` and `#83bdf2`. ΔE 13.1, one hue across two tiers, so it reads as a sheen rather than as two colours meeting. **This is the file that has to move when `mate.toml` moves**, and it does not follow the appearance at all — the ring is the same blue on both grounds, 5.57:1 on `#1f1f1f` and 3.19:1 on white |
| Everything else | the terminal owns the sixteen slots and the rest follows for free: `bat` and delta run `syntax-theme = ansi`, `ls` colours through `LSCOLORS`, `psql` writes raw SGR slots, `btop` runs `color_theme = "TTY"`, fzf takes ANSI names. None of them carries a hex of its own |

**tmux is in the same group, by carrying no colours at all.** [`tmux/tmux.conf`](./tmux/tmux.conf) sets no `status-style` and no `message-style`, so the status bar keeps tmux's own default of `bg=green` — the ANSI *slot*, not a colour. The palette owns that slot, which is what makes the bar follow it for free.


## Managed files

| Repo | Destination |
|---|---|
| `zsh/zshenv` | `~/.zshenv` |
| `zsh/zshrc` | `~/.zshrc` |
| `zsh/functions/` | `~/.config/zsh/functions` |
| `zsh/prompt.zsh` | `~/.config/zsh/prompt.zsh` |
| `alacritty/mate.toml` | `~/.config/alacritty/mate.toml` |
| `alacritty/mate-light.toml` | `~/.config/alacritty/mate-light.toml` |
| `herdr/sounds/done.mp3` | `~/.config/herdr/sounds/done.mp3` |
| `herdr/sounds/request.mp3` | `~/.config/herdr/sounds/request.mp3` |
| `nvim/` | `~/.config/nvim` |
| `zed/settings.json` | `~/.config/zed/settings.json` |
| `zed/themes/mate.json` | `~/.config/zed/themes/mate.json` |
| `zed/themes/mate-light.json` | `~/.config/zed/themes/mate-light.json` |
| `btop/btop.conf` | `~/.config/btop/btop.conf` |
| `mise/config.toml` | `~/.config/mise/config.toml` |
| `hammerspoon/init.lua` | `~/.hammerspoon/init.lua` |
| `hammerspoon/mate/` | `~/.hammerspoon/mate` |
| `git/gitconfig` | `~/.gitconfig` |
| `git/ignore` | `~/.config/git/ignore` |
| `git/allowed_signers` | `~/.config/git/allowed_signers` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `gh/config.yml` | `~/.config/gh/config.yml` |

Single files, except `zsh/functions/`, `nvim/` and `hammerspoon/mate/`, which are linked as directories so a new file inside them needs no install step. herdr and Zed are the opposite case and deliberately file-by-file: herdr keeps its sockets, logs and `session.json` in `~/.config/herdr` and Zed keeps `keymap.json`, its extensions and its state in `~/.config/zed`, both written at runtime, so neither directory can be a link into the repo. zsh has no single config directory to link: `.zshenv` and `.zshrc` are read from `$HOME` by name. `link_file` moves any pre-existing regular file to `<dst>.bak.<timestamp>` before replacing it.

Two files are missing from this list because they are *generated* rather than
linked, both by [`bin/mate`](./bin/mate) and both seeded once by `install.sh`:
`~/.config/alacritty/alacritty.toml`, the repo file with its `import` line
pointed at the active palette, and `~/.config/herdr/config.toml`, the repo file
with the matching `[theme.custom.<mode>]` block flattened into
`[theme.custom]`. Neither can be a symlink into the repo — Alacritty would
never reload it, and for herdr the generator would overwrite its own input.

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

- **The focus ring is an `hs.canvas` panel, not a window border — macOS has no such API.** It tracks the focused window via an `hs.window.filter`, and its 3pt band straddles the window edge — half in, half out — so it fits inside `GAP` without touching the neighbouring pane. All the geometry derives from the width, so that constant is the only thing to change. A drag emits an AX notification per display frame, so the repaint is throttled on the leading edge with a trailing call and mutates the single canvas element in place rather than rebuilding it; a debounce would be the wrong tool, since at sixty notifications a second it would never fire until the window stopped. Its colour is a gradient between the terminal's two blues, literals in `mate/border.lua` — `#6a9fb5` and `#82b8c8`, ANSI slots 4 and 12 of Alacritty's defaults. Staying inside one hue keeps it a sheen on an outline rather than two colours meeting, which is why the ΔE 9.8 between them is wanted here. It takes two filled rectangles rather than one stroked one, because `hs.canvas` has no `strokeGradient`: the inner rectangle composites with `destinationOut` to punch the middle out of the gradient. These two are one of only two hand-kept copies of the palette, and the palette itself is not in this repo, so an Alacritty release that moves slot 4 or 12 silently unmatches the ring. Hammerspoon runs LuaJIT, so the behaviour flags are summed with `+`: a `|` there is a syntax error, not a runtime one, and takes the whole config down with it.
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
- **`fd` and `bat` are not optional next to fzf** — `FZF_DEFAULT_COMMAND` and the `Ctrl-T` preview shell out to them.
- **The terminal font comes from no cask, and its family name is not its filename.** The files are `IoskeleyMonoTerm-*.ttf` in `~/Library/Fonts`; **the family CoreText registers is `Ioskeley Mono Term`**, spaced, which is what [`alacritty/alacritty.toml`](./alacritty/alacritty.toml) has to say. A family CoreText cannot find falls back to Menlo *silently* — the terminal still renders and nothing tells you the name was wrong. `system_profiler SPFontsDataType | grep -i "Family: Ioskeley"` lists what is actually registered. Every weight past the four regular faces gets its own family name, so they are separate families in a picker, not styles of one.
- **Never native fullscreen.** macOS fullscreen moves a window to a Space of its own, where `hammerspoon/init.lua` can no longer tile it — `cmd+alt+1` would have nothing to place it beside. Maximise instead. The bundle IDs live in `hammerspoon/mate/apps.lua`: `org.alacritty` and `com.google.Chrome`, the two lines to change if either app ever does.
- **The palette has no source in this repo, and two copies of it that do.** Alacritty declares no colours, so the sixteen slots are its built-in defaults and live in its source, not here. herdr's `[theme.custom]` and the Hammerspoon focus ring each carry their own hex, because neither can reference an ANSI slot by index. An Alacritty release that changes a default leaves both holding the old value, silently — and `git log` in this repo will show nothing, because nothing here changed.
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
