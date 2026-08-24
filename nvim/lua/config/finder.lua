-- Telescope. plenary is already loaded by ui.lua for neo-tree, and so is
-- devicons, which is what draws the filetype glyph in the results list.
--
-- telescope-fzf-native is a C extension that has to be compiled; the build hook
-- lives in init.lua because it must be registered before the first
-- vim.pack.add anywhere in the config. It is not decoration: without it the
-- sorter is Telescope's own Lua fuzzy matcher, which scores differently from
-- the fzf binary the shell uses on Ctrl-T. With it, the same query ranks the
-- same way in both places.
--
-- Unpinned: telescope's last tag is 0.1.8, and master is where the fixes for
-- Neovim 0.12 landed. fzf-native publishes no tags at all.
--
-- live_grep shells out to ripgrep, which is why Brewfile declares it: every rg
-- on this machine otherwise belongs to some editor extension, not the profile.
vim.pack.add({
  "https://github.com/nvim-telescope/telescope.nvim",
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

local telescope = require("telescope")

telescope.setup({
  defaults = {
    -- Same shape as the neo-tree markers: one-cell ASCII rather than glyphs
    -- whose width depends on a terminal setting.
    prompt_prefix = "> ",
    selection_caret = "> ",
    -- flex is horizontal (matches left, preview right) and only stacks the
    -- preview below when the window is narrower than flip_columns.
    layout_strategy = "flex",
    layout_config = {
      width = 0.9,
      height = 0.9,
      prompt_position = "top",
      flip_columns = 120,
      horizontal = { preview_width = 0.55 },
      vertical = { preview_height = 0.45 },
    },
    sorting_strategy = "ascending",
    path_display = { "truncate" },
    -- The default ignores nothing, so .git objects flood a --hidden search.
    file_ignore_patterns = { "^%.git/" },
  },
  pickers = {
    find_files = {
      -- Same switches as FZF_CTRL_T_COMMAND in zsh/zshrc.
      find_command = { "fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git" },
    },
  },
  extensions = {
    fzf = { fuzzy = true, override_generic_sorter = true, override_file_sorter = true },
  },
})

-- After setup(), and guarded: the extension is a compiled .so, and if the build
-- failed this would error out of the whole config instead of falling back to
-- the Lua sorter.
pcall(telescope.load_extension, "fzf")

local builtin = require("telescope.builtin")

vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find file" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Grep in project" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffer" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help tag" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent file" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostic" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Find symbol in file" })
vim.keymap.set("n", "<leader>fS", builtin.lsp_dynamic_workspace_symbols, { desc = "Find symbol in project" })
vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Find keymap" })
vim.keymap.set("n", "<leader>fc", builtin.resume, { desc = "Resume last picker" })
vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Grep in current file" })
