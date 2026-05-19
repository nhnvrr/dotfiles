-- Native insert-mode auto-completion (Neovim 0.12)
-- See completeopt/autocomplete in options.lua.
--
-- Built-in keymaps:
--   <C-n>     next item
--   <C-p>     previous item
--   <C-y>     confirm selection
--   <C-e>     dismiss menu
--   <C-Space> trigger omni completion (custom)
--   <C-j>     next item when popup visible, else default (custom)
--   <C-k>     previous item when popup visible, else default (custom)

vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", { desc = "Trigger omni completion" })

vim.keymap.set("i", "<C-j>", function()
  return vim.fn.pumvisible() == 1 and "<C-n>" or "<C-j>"
end, { expr = true, desc = "Next completion item" })

vim.keymap.set("i", "<C-k>", function()
  return vim.fn.pumvisible() == 1 and "<C-p>" or "<C-k>"
end, { expr = true, desc = "Previous completion item" })
