local augroup = vim.api.nvim_create_augroup("dotfiles.ui", { clear = true })

-- Kanso Ink — the same palette alacritty/alacritty.toml paints slot by slot, so
-- editor and terminal agree on #14171d and body text (#C5C9C7) lands at
-- 10.73:1. A real colorscheme rather than the sixteen ANSI slots: a colorscheme
-- addresses far more groups than sixteen.
--
-- termguicolors is set instead of left to autodetect, which reads COLORTERM —
-- that does not survive every ssh, and without it the theme drops to sixteen
-- colours silently rather than failing.
--
-- vim.pack is Neovim's own (0.12), so this adds a plugin without a plugin
-- manager. It clones on first start; nvim runs bare until it finishes.
vim.o.termguicolors = true
vim.pack.add({ "https://github.com/webhooked/kanso.nvim" })

-- The theme ships bold on a good number of groups, and this profile wants none
-- anywhere. Sweeping the whole table is the only way to reach the ones the
-- scheme does not declare itself — builtins it leaves alone, and every plugin
-- group defined later.
--
-- Linked groups come back as { link = "Other" } with no bold key, so the guard
-- skips them and the link is left intact rather than flattened into a copy.
local function strip_bold()
  for name, attrs in pairs(vim.api.nvim_get_hl(0, {})) do
    if attrs.bold or (attrs.cterm and attrs.cterm.bold) then
      attrs.bold = nil
      if attrs.cterm then
        attrs.cterm.bold = nil
      end
      -- nvim_get_hl reports default = true for groups declared with hi default,
      -- and nvim_set_hl reads that flag as "skip if the group already exists".
      -- Handing the table straight back would silently do nothing.
      attrs.default = nil
      vim.api.nvim_set_hl(0, name, attrs)
    end
  end
end

-- Registered BEFORE the colorscheme command, which is what makes it fire for
-- this load and not only for a later manual `:colorscheme`. Deferred inside, so
-- plugins that rebuild their own groups on ColorScheme run first.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup,
  callback = function()
    vim.schedule(strip_bold)
  end,
})

-- setup() has to run before the colorscheme command: it only stores options,
-- and the highlights are built when the scheme loads.
--
-- transparent drops the Normal background so the terminal shows through, which
-- is what keeps Alacritty's blur visible behind the buffer. It is also what
-- makes the background a single knob — it is painted in one place,
-- alacritty.toml, and nvim follows rather than disagreeing.
--
-- No palette override is needed anywhere: the theme's own bg0 is #14171d, which
-- is exactly what the terminal paints, so the surfaces it defines as a distance
-- above the background land where they were designed to.
require("kanso").setup({
  theme = "ink",
  background = { dark = "ink" },
  transparent = true,
  italics = false,
  bold = false,
})
vim.cmd.colorscheme("kanso-ink")

-- One more pass once the whole config has been read: the plugins required after
-- this module define their groups later, and Telescope defines some of its own
-- on first open.
vim.api.nvim_create_autocmd("VimEnter", {
  group = augroup,
  callback = function()
    vim.schedule(strip_bold)
  end,
})

-- neo-tree pulls three repos of its own: plenary and nui are hard requirements
-- it errors without, devicons is what draws the per-filetype icons.
--
-- The major is pinned rather than a branch: the v2 to v3 rewrite was breaking,
-- and an unpinned add would take a future v4 the same way.
vim.pack.add({
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = vim.version.range("3") },
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
})

-- Filetype icons are left at their defaults: they are already Nerd Font glyphs,
-- and the terminal profile loads the Mono build where each one is one cell.
--
-- The git markers are not. Two of the defaults — `✚` and `✖` — are East-Asian
-- Ambiguous, so their width depends on a terminal setting rather than on the
-- font, and next to the one-cell Nerd Font glyphs the column shifts by a cell
-- as files change state. These are git's own porcelain letters, every one of
-- them ASCII and one cell wide, so the column never moves.
--
-- unstaged is empty on purpose: unstaged is the normal case, and printing it
-- next to the change type gives every modified file two markers instead of one.
-- Only the exception is drawn — `=` for what is already staged. ignored is
-- empty too, since filtered_items hides those anyway.
require("neo-tree").setup({
  close_if_last_window = true,
  window = { width = 32 },
  default_component_configs = {
    git_status = {
      symbols = {
        added     = "+",
        modified  = "~",
        deleted   = "-",
        renamed   = ">",
        untracked = "?",
        conflict  = "!",
        staged    = "=",
        unstaged  = "",
        ignored   = "",
      },
    },
  },
  filesystem = {
    -- This is a dotfiles repo: hiding dotfiles would hide the whole tree.
    filtered_items = { hide_dotfiles = false, hide_gitignored = true },
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
  },
})

vim.keymap.set("n", "<leader>e", "<Cmd>Neotree toggle reveal<CR>", { desc = "Toggle file tree" })

-- The builtin statusline cannot show diagnostic counts or the git branch
-- without hand-writing a vim.o.statusline expression and its refresh; that is
-- the limit being bought out here, not the looks. Unpinned like plenary and
-- nui: lualine publishes no tags, so a range would have nothing to match.
--
-- devicons is already loaded above for neo-tree.
vim.pack.add({ "https://github.com/nvim-lualine/lualine.nvim" })

-- kanso.nvim ships its own lualine theme, so this is the palette itself
-- and not the auto theme's guess at it. It arrives with solid backgrounds and a
-- bold mode section; both are stripped here rather than after setup(), because
-- lualine copies the table it is given and rebuilds these groups on
-- ColorScheme, which would undo a later override.
local function luminance(hex)
  local function channel(value)
    value = tonumber(value, 16) / 255
    return value <= 0.04045 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    return nil
  end
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

local lualine_theme = require("lualine.themes.kanso")
for _, mode in pairs(lualine_theme) do
  for _, section in pairs(mode) do
    -- The mode section is a coloured chip with near-black text on it. Dropping
    -- the chip without touching the text leaves near-black on black, which is
    -- invisible — so where the text is the darker of the two, the chip's own
    -- colour becomes the text colour. That is what carried the mode anyway.
    local fg, bg = luminance(section.fg or ""), luminance(section.bg or "")
    if fg and bg and fg < bg then
      section.fg = section.bg
    end
    section.bg = "NONE"
    section.gui = nil
  end
end

require("lualine").setup({
  options = {
    theme = lualine_theme,
    -- Plain separators: the powerline arrows need a glyph that changes width
    -- between Nerd Font builds, and the profile loads the Mono one.
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
  extensions = { "neo-tree", "nvim-dap-ui", "quickfix" },
})

-- which-key. With nine leader groups and timeoutlen at 300ms, the cost of a
-- forgotten chord is a 300ms stall followed by a wrong command; this turns the
-- same pause into a menu. It is also the only thing that makes the buffer-local
-- per-language maps discoverable, since they exist in some buffers and not
-- others.
vim.pack.add({ "https://github.com/folke/which-key.nvim" })

require("which-key").setup({
  preset = "helix",
  -- Same reasoning as the neo-tree markers and the Telescope prefix: one-cell
  -- ASCII rather than glyphs whose width depends on a terminal setting.
  icons = { mappings = false, separator = "->" },
})

require("which-key").add({
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>d", group = "debug" },
  { "<leader>f", group = "find" },
  { "<leader>g", group = "git" },
  { "<leader>s", group = "split" },
  { "<leader>t", group = "test" },
})

-- Two builtins-in-spirit that cost nothing at startup and remove ceremony:
-- surround (cs"' , ysiw) , ds") and a visual undo tree, which is the only way
-- to reach what `undofile = true` has been saving all along.
vim.pack.add({
  "https://github.com/kylechui/nvim-surround",
  "https://github.com/mbbill/undotree",
})

require("nvim-surround").setup({})

vim.keymap.set("n", "<leader>u", "<Cmd>UndotreeToggle<CR>", { desc = "Toggle undo tree" })
