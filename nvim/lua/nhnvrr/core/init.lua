require("nhnvrr.core.options")
require("nhnvrr.core.keymaps")
local cmd = vim.api.nvim_create_user_command
vim.opt.showmode = false
cmd("W", "w<bang> <args>", { bang = true, nargs = "*", complete = "file" })
cmd("Q", "q<bang>", { bang = true })
vim.g.markdown_recommended_style = 0
