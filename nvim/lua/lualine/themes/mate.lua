-- Numbers are ANSI slots: with notermguicolors lualine passes them through
-- as ctermfg/ctermbg, so colours come from the terminal palette.
local dark = vim.o.background == 'dark'
local dim = dark and 248 or 8
local surf = dark and 8 or 0

local function mode(bg)
  return {
    a = { fg = 0, bg = bg },
    b = { fg = 15, bg = surf },
    c = { fg = 15, bg = surf },
  }
end

return {
  normal = mode(6),
  insert = mode(2),
  visual = mode(3),
  replace = mode(9),
  command = mode(5),
  terminal = mode(dim),
  inactive = {
    a = { fg = dim, bg = surf },
    b = { fg = dim, bg = surf },
    c = { fg = dim, bg = surf },
  },
}
