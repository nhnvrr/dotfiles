-- Native insert-mode auto-completion (Neovim 0.12)
-- autocomplete = "popup" is set vvoptions.lua
--
-- Built-in keymaps:
--   <C-n>     next item
--   <C-p>     previous item
--   <C-y>     confirm selection
--   <C-e>     dismiss menu
--   <C-Space> trigger omni completion (custom)

vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", { desc = "Trigger omni completion" })
