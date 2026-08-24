local augroup = vim.api.nvim_create_augroup("dotfiles.keymaps", { clear = true })

-- ─── modes ───────────────────────────────────────────────────────────────────

-- Leaves insert mode without reaching for Esc. The cost is that a literal `j`
-- holds for 'timeoutlen' before it prints, waiting to see if a `k` follows.
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

-- Esc clears the search highlight as well as leaving the mode. Without this the
-- highlight from the last search stays lit until :noh, which nobody types.
vim.keymap.set("n", "<Esc>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- ─── splits ──────────────────────────────────────────────────────────────────
--
-- sv/sh and not the builtin <C-w>v / <C-w>s: those are two chords deep and this
-- is the one window operation used constantly. The letters follow the shape of
-- the resulting divider, not the direction of the new pane — sv puts a vertical
-- line down the middle, sh a horizontal one across.
vim.keymap.set("n", "<leader>sv", "<Cmd>vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>sh", "<Cmd>split<CR>", { desc = "Split horizontally" })
vim.keymap.set("n", "<leader>sc", "<Cmd>close<CR>", { desc = "Close split" })
vim.keymap.set("n", "<leader>so", "<Cmd>only<CR>", { desc = "Close other splits" })
vim.keymap.set("n", "<leader>s=", "<C-w>=", { desc = "Equalise splits" })

-- Moving between them, since a split is worth little without this.
--
-- Note that <C-l> shadows the builtin, which is nohlsearch + diffupdate +
-- redraw. The nohlsearch half is covered by <Esc> above; what is actually lost
-- is the forced redraw for a screen dirtied over ssh, which <C-w>l does not do.
-- :mode still does it when that happens.
for _, dir in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set("n", "<C-" .. dir .. ">", "<C-w>" .. dir, { desc = "Focus split " .. dir })
end

vim.keymap.set("n", "<C-Up>", "<Cmd>resize +2<CR>", { desc = "Grow split" })
vim.keymap.set("n", "<C-Down>", "<Cmd>resize -2<CR>", { desc = "Shrink split" })
vim.keymap.set("n", "<C-Left>", "<Cmd>vertical resize -4<CR>", { desc = "Narrow split" })
vim.keymap.set("n", "<C-Right>", "<Cmd>vertical resize +4<CR>", { desc = "Widen split" })

-- ─── buffers ─────────────────────────────────────────────────────────────────
--
-- Only the close map. Cycling used to live on <S-h>/<S-l>, but Neovim
-- normalises <S-{letter}> to the bare capital, so those were literally H and L
-- — the jumps to the top and bottom of the screen, gone. 0.12 already ships
-- [b and ]b for exactly this.
vim.keymap.set("n", "<leader>bd", "<Cmd>bdelete<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<leader>bo", "<Cmd>%bdelete|edit#|bdelete#<CR>", { desc = "Close other buffers" })

-- ─── motion ──────────────────────────────────────────────────────────────────
--
-- Keep the cursor in the middle when jumping. Half-page scrolling and search
-- both dump you at the edge of the screen otherwise, and reading around the
-- landing point is most of what happens next.
for _, key in ipairs({ "<C-d>", "<C-u>", "n", "N" }) do
  vim.keymap.set("n", key, key .. "zz", { desc = "Jump and centre" })
end

-- ─── visual ──────────────────────────────────────────────────────────────────
--
-- Every mapping here is "x", never "v". In vim "v" means Visual AND Select, and
-- Select is where snippet placeholders live: with these bound in "v", typing
-- `p` or `J` over a placeholder ran the mapping instead of replacing the text.
-- With gopls' usePlaceholders and blink's snippet source both on, that is a
-- constant edit.

-- Move the selection, reindenting as it goes. The one refactor motion that is
-- pure ceremony without a mapping: dd, navigate, p, re-indent.
vim.keymap.set("x", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("x", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Stay in visual mode after indenting, so > > > is one keypress repeated.
vim.keymap.set("x", "<", "<gv", { desc = "Indent left, keep selection" })
vim.keymap.set("x", ">", ">gv", { desc = "Indent right, keep selection" })

-- Paste over a selection without losing the register. The default swaps the
-- yanked text for whatever was replaced, which makes a second paste useless.
vim.keymap.set("x", "p", '"_dP', { desc = "Paste without clobbering register" })

-- ─── registers ───────────────────────────────────────────────────────────────
--
-- Delete without touching the unnamed register. This lived on <leader>d until
-- nvim-dap took that prefix; sharing it made every debug chord wait out the
-- 300ms timeoutlen before firing.
vim.keymap.set({ "n", "x" }, "<leader>x", '"_d', { desc = "Delete to black hole" })

-- ─── quickfix ────────────────────────────────────────────────────────────────
--
-- neotest and gitsigns both populate it without stealing focus, so it needs a
-- way in. []q are already builtin in 0.12; only the toggle is missing.
vim.keymap.set("n", "<leader>q", function()
  local open = vim.iter(vim.fn.getwininfo()):any(function(win)
    return win.quickfix == 1
  end)
  vim.cmd(open and "cclose" or "copen")
end, { desc = "Toggle quickfix" })

-- ─── autocmds ────────────────────────────────────────────────────────────────

-- A visible flash on whatever was just yanked, so a large yank is confirmed
-- without checking the register. 150ms is the default; it is spelled out
-- because the flash is the whole point of the autocmd.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Reopen a file where it was left. The mark survives in the shada file; the
-- guard skips it when the line no longer exists, which happens after a rebase.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- q closes the throwaway windows. Without it, help and quickfix need :q and the
-- dap-ui panels need the mouse.
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth", "dap-float", "neotest-output", "neotest-summary" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = args.buf, silent = true })
  end,
})

-- Terminal buffers: no line numbers, and Esc leaves terminal mode instead of
-- being swallowed by whatever is running. <C-\><C-n> is the builtin and stays.
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function(args)
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = args.buf })
  end,
})
