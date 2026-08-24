vim.loader.enable()

-- Leader has to be set before any module maps anything: vim.keymap.set resolves
-- <leader> at definition time, not at press time, so a map defined earlier binds
-- to whatever leader was then (backslash, by default).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Every autocmd in this config goes in a group with clear = true, so that
-- `:source $MYVIMRC` replaces them instead of stacking a second copy. Without
-- it, a re-source formats the buffer twice on write and attaches every
-- LspAttach handler twice.
local augroup = vim.api.nvim_create_augroup("dotfiles", { clear = true })

-- Registered before the FIRST vim.pack.add anywhere in the config, and that is
-- what this file's position buys. vim.pack synchronises the whole lockfile on
-- the first add — not on the add that names the plugin — installing everything
-- listed but missing from disk and emitting PackChanged for each one right
-- there. Registered later, the build hook below never runs on a cold start, and
-- the pcall around the extension load turns that into a silent fallback to the
-- Lua sorter rather than an error.
vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup,
  callback = function(args)
    local data = args.data
    if data.spec.name ~= "telescope-fzf-native.nvim" or data.kind == "delete" then
      return
    end
    local result = vim.system({ "make" }, { cwd = data.path, text = true }):wait()
    if result.code ~= 0 then
      vim.notify("telescope-fzf-native: make failed\n" .. (result.stderr or ""), vim.log.levels.ERROR)
    end
  end,
})

-- Order matters in three places and nowhere else:
--   options  first, because its vim.g.loaded_* guards must beat $VIMRUNTIME.
--   completion before lsp, because blink's capabilities have to be registered
--            on the '*' config before any server config is resolved.
--   keymaps  last, so a plugin default cannot silently win over one of ours.
for _, module in ipairs({
  "options",
  "ui",
  "treesitter",
  "finder",
  "completion",
  "lsp",
  "format",
  "debug",
  "test",
  "git",
  "keymaps",
}) do
  require("config." .. module)
end
