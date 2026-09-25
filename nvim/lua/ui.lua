vim.pack.add({
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/kylechui/nvim-surround",
})

require("lualine").setup({
  options = {
    -- "auto" derives the bar from the active colorscheme's highlight groups, so
    -- it follows `background` on its own and there is no palette to restate.
    theme = "auto",
    -- No nvim-web-devicons: the terminal font is not a Nerd Font build.
    icons_enabled = false,
    section_separators = "",
    component_separators = "|",
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "diagnostics", "filetype" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  },
  extensions = { "quickfix" },
})

require("which-key").setup({
  preset = "helix",
  icons = {
    mappings = false,
    separator = "->",
    -- Plain names: which-key's defaults are Nerd Font glyphs.
    keys = {
      Up = "<Up> ", Down = "<Down> ", Left = "<Left> ", Right = "<Right> ",
      C = "C-", M = "M-", D = "D-", S = "S-",
      CR = "<CR> ", Esc = "<Esc> ", NL = "<NL> ", BS = "<BS> ", Space = "<Space> ", Tab = "<Tab> ",
      ScrollWheelDown = "<ScrollWheelDown> ", ScrollWheelUp = "<ScrollWheelUp> ",
      F1 = "F1", F2 = "F2", F3 = "F3", F4 = "F4", F5 = "F5", F6 = "F6",
      F7 = "F7", F8 = "F8", F9 = "F9", F10 = "F10", F11 = "F11", F12 = "F12",
    },
  },
})
require("which-key").add({
  { "<leader>c", group = "code" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>s", group = "split" },
})

require("nvim-surround").setup({})

-- Toggle: opens on the current file's directory with the cursor on that file,
-- and from netrw goes back to the file it was opened from.
vim.keymap.set("n", "<leader>e", function()
  if vim.bo.filetype ~= "netrw" then
    vim.cmd("Explore")
  elseif not pcall(vim.cmd, "Rexplore") then
    local alt = vim.fn.bufnr("#")
    if alt > 0 and vim.bo[alt].filetype ~= "netrw" then
      vim.cmd("buffer #")
    end
  end
end, { desc = "File tree" })
