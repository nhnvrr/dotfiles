# NVIM

Leader is `Space`. `<leader>gs` is Space g s; `gd` alone is go to definition.
Press `Space` and wait for which-key to list the leader groups.

## Mine

### Editing and moving

| Keys                                | Mode                | Does                                                 |
| ----------------------------------- | ------------------- | ---------------------------------------------------- |
| `jk`                                | insert              | Leave insert mode                                    |
| `Esc`                               | normal              | Clear search highlight                               |
| `<leader>w`                         | normal              | Save                                                 |
| `<leader>q`                         | normal              | Quit                                                 |
| `Ctrl-h` `Ctrl-j` `Ctrl-k` `Ctrl-l` | normal              | Move to the window left / down / up / right          |
| `Ctrl-d` `Ctrl-u`                   | normal              | Half page down / up, cursor centred                  |
| `n` `N`                             | normal              | Next / previous match, cursor centred                |
| `J` `K`                             | visual              | Move the selected lines down / up                    |
| `<` `>`                             | visual              | Indent and keep the selection                        |
| `p`                                 | visual              | Paste over the selection without losing the register |
| `j` `k`                             | prose files         | Move by screen line on wrapped lines                 |
| `q`                                 | help, quickfix, man | Close the window                                     |

### Windows

| Keys         | Does             |
| ------------ | ---------------- |
| `<leader>sv` | Split vertical   |
| `<leader>sh` | Split horizontal |
| `<leader>sx` | Close window     |

### Find (fzf-lua)

| Keys                        | Does                           |
| --------------------------- | ------------------------------ |
| `<leader>ff`                | Files                          |
| `<leader>fg`                | Grep                           |
| `<leader>fw`                | Grep the word under the cursor |
| `<leader>fb`                | Buffers                        |
| `<leader>fr`                | Recent files                   |
| `<leader>fh`                | Help                           |
| `<leader>fd` / `<leader>fD` | Diagnostics, file / workspace  |
| `<leader>fs` / `<leader>fS` | Symbols, file / workspace      |
| `<leader>f.`                | Reopen the last picker         |

### Git

| Keys                        | Does                                                                              |
| --------------------------- | --------------------------------------------------------------------------------- |
| `<leader>gf`                | Uncommitted files; in the picker `Ctrl-s` stage, `Ctrl-u` unstage, `Ctrl-x` reset |
| `<leader>gc` / `<leader>gC` | Commits, repo / this file                                                         |
| `<leader>gB`                | Branches                                                                          |
| `]h` `[h`                   | Next / previous hunk                                                              |
| `<leader>gs`                | Stage hunk                                                                        |
| `<leader>gr`                | Reset hunk                                                                        |
| `<leader>gp`                | Preview hunk                                                                      |
| `<leader>gb`                | Toggle line blame                                                                 |

### Code and LSP

| Keys         | Does                                 |
| ------------ | ------------------------------------ |
| `gd`         | Go to definition                     |
| `gD`         | Go to declaration                    |
| `grr`        | References                           |
| `gri`        | Implementations                      |
| `grt`        | Type definition                      |
| `]d` `[d`    | Next / previous diagnostic           |
| `]e` `[e`    | Next / previous error only           |
| `<leader>cd` | Show the diagnostic under the cursor |
| `<leader>ci` | Hover info                           |
| `<leader>cs` | Signature help                       |
| `<leader>ch` | Toggle inlay hints                   |
| `<leader>cf` | Format                               |
| `<leader>co` | Organize imports (TS/JS)             |
| `<leader>cm` | Add missing imports (TS/JS)          |
| `<leader>ca` | Fix all eslint (TS/JS)               |

### Completion (insert mode, menu open)

| Keys                        | Does                                   |
| --------------------------- | -------------------------------------- |
| `Ctrl-Space`                | Open the menu                          |
| `Tab`                       | Select the first entry, then accept it |
| `S-Tab` `Ctrl-k` / `Ctrl-j` | Previous / next entry                  |
| `Enter`                     | Accept                                 |
| `Ctrl-e`                    | Close the menu                         |
| `Ctrl-b` `Ctrl-f`           | Scroll the docs                        |

### File tree (netrw, built in)

| Keys        | Does                                          |
| ----------- | --------------------------------------------- |
| `<leader>e` | Open the tree on the current file's directory |
| `Enter`     | Open the file or folder                       |
| `-`         | Up one directory                              |
| `%`         | New file                                      |
| `d`         | New folder                                    |
| `D`         | Delete                                        |
| `R`         | Rename                                        |
| `gh`        | Toggle hidden files                           |
| `Ctrl-^`    | Back to the file you came from                |

### Surround (nvim-surround)

| Keys               | Does                                       |
| ------------------ | ------------------------------------------ |
| `ys{motion}{char}` | Add, e.g. `ysiw"` wraps the word in quotes |
| `ds{char}`         | Delete, e.g. `ds"`                         |
| `cs{old}{new}`     | Change, e.g. `cs"'`                        |
| `S{char}`          | Wrap the visual selection                  |

## nvim's own

The ones worth knowing, not the full list. `:help index` has everything.

### Moving

| Keys              | Does                                                 |
| ----------------- | ---------------------------------------------------- |
| `w` `b` `e`       | Next word / previous word / end of word              |
| `0` `^` `$`       | Line start / first character / line end              |
| `gg` `G`          | Top / bottom of the file                             |
| `{` `}`           | Previous / next paragraph                            |
| `%`               | Jump to the matching bracket                         |
| `f{c}` `t{c}`     | To / before the next `c` on the line; `;` `,` repeat |
| `*` `#`           | Search the word under the cursor, forward / back     |
| `Ctrl-o` `Ctrl-i` | Back / forward in the jump list                      |
| `zz` `zt` `zb`    | Scroll the cursor line to middle / top / bottom      |

### Editing

| Keys                 | Does                                                                              |
| -------------------- | --------------------------------------------------------------------------------- |
| `ciw` `diw` `yiw`    | Change / delete / yank the word; `i(` `i"` `it` for inside brackets, quotes, tags |
| `ca(` `da"`          | Same, including the delimiters                                                    |
| `.`                  | Repeat the last change                                                            |
| `u` `Ctrl-r`         | Undo / redo                                                                       |
| `>>` `<<`            | Indent / dedent the line                                                          |
| `gcc` / `gc{motion}` | Toggle comment on the line / the motion                                           |
| `~`                  | Toggle case                                                                       |
| `Ctrl-a` `Ctrl-x`    | Increment / decrement the number                                                  |
| `gv`                 | Reselect the last selection                                                       |
| `v` `V` `Ctrl-v`     | Visual by character / line / block                                                |

### LSP defaults (nvim 0.11)

| Keys     | Does                         |
| -------- | ---------------------------- |
| `K`      | Hover                        |
| `grn`    | Rename                       |
| `gra`    | Code action                  |
| `gO`     | Document symbols             |
| `Ctrl-s` | Signature help (insert mode) |

### Windows and folds

| Keys               | Does                               |
| ------------------ | ---------------------------------- |
| `Ctrl-w =`         | Equalise window sizes              |
| `Ctrl-w o`         | Close all other windows            |
| `za` / `zR` / `zM` | Toggle fold / open all / close all |
