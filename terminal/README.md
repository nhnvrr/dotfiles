# Terminal.app profile

`Dotfiles.terminal` is the exported profile: font, the sixteen ANSI slots, cursor, Meta key and
bell. `install.sh` imports it and makes it both the default and the startup profile.

It is the one file here that isn't readable text — Terminal.app stores every colour as an
`NSKeyedArchiver` blob, so a `git diff` on it says nothing. That is the price of the app; nothing
else in the repo hardcodes a hex, everything asks by ANSI name.

## Editing it

Round-trips through the app, in this direction only:

```
  Terminal → Settings → Profiles → Dotfiles     edit
                                      │
                                      ├─ ⚙ → Export…  →  terminal/Dotfiles.terminal   commit
                                      │
  install.sh  ─────────────────────────┘                 (import, on another machine)
```

Editing the file in place does nothing: the app holds its settings in memory and overwrites the
plist when it quits.

## Re-importing

`./install.sh --skipBrew` is idempotent here. A profile can't be deleted while it's the default
one, so the script swaps the default to `Basic`, deletes `Dotfiles`, re-imports and sets it back —
which is also what stops a second run from leaving a `Dotfiles 2` behind.

## Settings that carry weight

| Setting | Why |
|---|---|
| Text → Font: MonaspiceAr Nerd Font **Mono** | the Propo variant drifts eza's icon columns |
| Text → "Use bright colors for bold text" **off** | otherwise bold repaints text in the bright slot |
| Advanced → "Dynamic ANSI foreground colors" **off** | it overrides the palette for contrast |
| Keyboard → "Use Option as Meta Key" **on** | fish's hybrid bindings read `Alt-<key>` as `ESC`+key |
| Advanced → Declare terminal as: `xterm-256color` | in the system terminfo, so `sudo` and `ssh` work |

Terminal.app has no window padding, no ligature control and no copy-on-select. The last one is
only missing outside tmux — inside, `MouseDragEnd1Pane` already pipes the selection to `pbcopy`.
