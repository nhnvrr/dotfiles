# Keymaps

## General

| Keymap       | Mode   | Action                          |
| ------------ | ------ | ------------------------------- |
| `jk`         | Insert | Exit insert mode                |
| `<leader>nh` | Normal | Clear search highlights         |
| `<leader>+`  | Normal | Increment number                |
| `<leader>-`  | Normal | Decrement number                |
| `q`          | Normal | Close buffer (help/man/qf only) |

## Windows & Terminal

| Keymap       | Mode   | Action                     |
| ------------ | ------ | -------------------------- |
| `<leader>sv` | Normal | Split vertical             |
| `<leader>sh` | Normal | Split horizontal           |
| `<leader>se` | Normal | Make splits equal size     |
| `<leader>sx` | Normal | Close current split        |
| `<leader>tv` | Normal | Terminal in vertical split |
| `<leader>th` | Normal | Terminal in horizontal split |

## LSP (custom)

| Keymap       | Mode   | Action                  |
| ------------ | ------ | ----------------------- |
| `gd`         | Normal | Definitions (fzf-lua)   |
| `GD`         | Normal | Definition in new tab   |
| `<leader>rs` | Normal | Restart LSP             |

## LSP (Neovim 0.12 defaults)

| Keymap   | Mode          | Action           |
| -------- | ------------- | ---------------- |
| `grr`    | Normal        | References       |
| `gri`    | Normal        | Implementations  |
| `grn`    | Normal        | Rename           |
| `gra`    | Normal/Visual | Code actions     |
| `grt`    | Normal        | Type definition  |
| `gO`     | Normal        | Document symbols |
| `gD`     | Normal        | Declaration      |
| `K`      | Normal        | Hover documentation |
| `Ctrl-S` | Insert        | Signature help   |

## Diagnostics

| Keymap      | Mode   | Action                         |
| ----------- | ------ | ------------------------------ |
| `[d`        | Normal | Previous diagnostic            |
| `]d`        | Normal | Next diagnostic                |
| `gl`        | Normal | Diagnostic float               |
| `<leader>D` | Normal | Buffer diagnostics (fzf-lua)   |

## Completion (native 0.12)

| Keymap      | Mode   | Action                       |
| ----------- | ------ | ---------------------------- |
| `<C-n>`     | Insert | Next item (built-in)         |
| `<C-p>`     | Insert | Previous item (built-in)     |
| `<C-y>`     | Insert | Confirm selection (built-in) |
| `<C-e>`     | Insert | Dismiss menu (built-in)      |
| `<C-Space>` | Insert | Trigger omni completion      |

## Fuzzy Finder (fzf-lua)

| Keymap       | Mode   | Action                   |
| ------------ | ------ | ------------------------ |
| `<leader>ff` | Normal | Find files               |
| `<leader>fr` | Normal | Recent files             |
| `<leader>fs` | Normal | Live grep                |
| `<leader>fg` | Normal | Git files                |
| `<leader>fc` | Normal | Grep string under cursor |
| `<leader>fk` | Normal | Find keymaps             |
| `<leader>fb` | Normal | Find buffers             |

## File Explorer

| Keymap       | Mode   | Action             |
| ------------ | ------ | ------------------ |
| `<leader>ee` | Normal | Toggle netrw explorer at project root |

## Trouble

| Keymap       | Mode   | Action                |
| ------------ | ------ | --------------------- |
| `<leader>xw` | Normal | Workspace diagnostics |
| `<leader>xd` | Normal | Document diagnostics  |
| `<leader>xq` | Normal | Quickfix list         |
| `<leader>xl` | Normal | Location list         |

## Git

| Keymap       | Mode   | Action       |
| ------------ | ------ | ------------ |
| `]h`         | Normal | Next hunk    |
| `[h`         | Normal | Prev hunk    |
| `<leader>hs` | Normal | Stage hunk   |
| `<leader>hr` | Normal | Reset hunk   |
| `<leader>hp` | Normal | Preview hunk |
| `<leader>hb` | Normal | Blame line   |

## Formatting

| Keymap       | Mode          | Action               |
| ------------ | ------------- | -------------------- |
| `<leader>mp` | Normal/Visual | Format file or range |

## Scroll

| Keymap             | Mode  | Action   |
| ------------------ | ----- | -------- |
| `ScrollWheelLeft`  | n/v/i | Disabled |
| `ScrollWheelRight` | n/v/i | Disabled |
