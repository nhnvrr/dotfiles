-- Three theme families, two halves each, one plugin per family: no single
-- colorscheme plugin carries all three. nightfox, which these replace, had none.
--
-- The mode needs no telling. Neovim's TUI asks the terminal for its background on
-- startup and sets 'background' itself (:h 'background'), so the terminal stays
-- the single source of truth. The family cannot be detected that way, so it is
-- read from the `# theme:` marker in the deployed alacritty theme — the same file
-- the `theme` switch writes, so there is still only one place holding the truth.

local M = {}

-- Two of the three use one colorscheme name for both halves and switch on
-- 'background'; onedarkpro ships a name per half instead.
local SCHEMES = {
  solarized = { dark = "solarized", light = "solarized" },
  gruvbox = { dark = "gruvbox", light = "gruvbox" },
  one = { dark = "onedark", light = "onelight" },
}

M.LUALINE = {
  solarized = { dark = "solarized_dark", light = "solarized_light" },
  gruvbox = { dark = "gruvbox_dark", light = "gruvbox_light" },
  one = { dark = "onedark", light = "onelight" },
}

-- Matches install.sh's seed, so a machine with nothing deployed still gets a pair
-- rather than an error.
local DEFAULT_FAMILY = "gruvbox"

local function read_family()
  local fh = io.open(vim.fn.expand("~/.config/alacritty/theme.toml"), "r")
  if not fh then return DEFAULT_FAMILY end
  local found
  for line in fh:lines() do
    -- The markers live in the header block; stop at the first real setting rather
    -- than reading the whole file on every startup.
    if not line:match("^#") and line ~= "" then break end
    found = line:match("^#%s*theme:%s*(%S+)")
    if found then break end
  end
  fh:close()
  return SCHEMES[found] and found or DEFAULT_FAMILY
end

M.family = read_family()

function M.mode()
  return vim.o.background == "light" and "light" or "dark"
end

-- Transparency is on in all three so the terminal's own background shows through
-- and nvim never paints one of its own. Each plugin names it differently, which is
-- the only reason these three blocks cannot be collapsed.
require("solarized").setup({
  transparent = { enabled = true },
  -- Off: it would tint the palette away from the sixteen ANSI slots, which is the
  -- one thing that has to stay matched.
  variant = "winter",
})
require("gruvbox").setup({
  transparent_mode = true,
  bold = false,
  italic = { comments = true, strings = false, folds = false, operators = false },
})
require("onedarkpro").setup({
  options = { transparency = true, bold = false, italic = true },
})

local applying = false
local applied

local function apply()
  local key = M.family .. ":" .. M.mode()
  -- Keyed on family and mode, not on colors_name: solarized and gruvbox use one
  -- name for both halves, so comparing names alone would skip the reload that
  -- actually repaints when only the mode changed.
  if applying or applied == key then return end
  applying = true
  applied = key
  vim.cmd.colorscheme(SCHEMES[M.family][M.mode()])
  applying = false
end

-- Two hooks and not one because they cover different windows: OptionSet does not
-- fire during startup at all (:h OptionSet), which is precisely when the terminal's
-- reply usually lands, and VimEnter runs once startup is over and the option has
-- settled. apply() is idempotent, so the second costs nothing when it is already
-- right.
vim.api.nvim_create_autocmd("OptionSet", { pattern = "background", callback = apply })
vim.api.nvim_create_autocmd("VimEnter", { callback = apply })

-- On ColorScheme so a reload doesn't undo it. Groups are read by their generic
-- names (Directory, Normal, Comment) rather than any theme's own, which is what
-- has let this block survive every colorscheme change untouched.
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = { "solarized", "gruvbox", "onedark", "onelight" },
  callback = function()
    local function fg(group)
      return vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    end
    local set = vim.api.nvim_set_hl

    -- Neovim's own defaults, which no theme option reaches.
    for _, group in ipairs({ "PmenuMatch", "PmenuMatchSel", "WinBar" }) do
      local h = vim.api.nvim_get_hl(0, { name = group, link = false })
      h.bold, h.cterm = nil, nil
      set(0, group, h)
    end

    set(0, "NeoTreeDirectoryName", { fg = fg("Directory") })
    set(0, "NeoTreeDirectoryIcon", { fg = fg("Directory") })
    set(0, "NeoTreeFileName", { fg = fg("Normal") })
    set(0, "NeoTreeFileNameOpened", { fg = fg("Normal") })
    set(0, "NeoTreeGitIgnored", { fg = fg("Comment"), italic = true })
    set(0, "NeoTreeDotfile", { fg = fg("Comment") })
  end,
})

apply()

return M
