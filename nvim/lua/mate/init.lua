local M = {}

M.defaults = {
  -- 0-1: blends the four syntax accents toward grey_light. 1 = full colour.
  accent = 1.0,
  italics = { comments = true },
  on_colors = function(_) end,
  on_highlights = function(_, _) end,
}

M.opts = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.opts = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

local GROUPS = {
  "editor",
  "syntax",
  "treesitter",
  "semantic_tokens",
  "diagnostics",
  "lsp",
  "diff",
  "blink",
  "fzf_lua",
  "gitsigns",
  "which_key",
  "neotree",
  "dap",
  "neotest",
}

--- Palette after `accent` and `on_colors`.
function M.colors()
  local palette = require("mate.palette")
  local util = require("mate.util")
  local c = vim.deepcopy(palette.colors)
  if M.opts.accent < 1 then
    for _, k in ipairs({ "keyword", "func", "type", "string", "teal", "signal" }) do
      c[k] = util.blend(c[k], c.grey_light, M.opts.accent)
    end
  end
  M.opts.on_colors(c)
  return c
end

--- Every highlight group, merged in GROUPS order (later wins).
function M.highlights()
  local c = M.colors()
  local hl = {}
  for _, name in ipairs(GROUPS) do
    local groups = require("mate.groups." .. name)(c, M.opts)
    for group, spec in pairs(groups) do
      hl[group] = spec
    end
  end
  M.opts.on_highlights(hl, c)
  return hl, c
end

function M.load()
  if vim.g.colors_name then
    vim.cmd.hi("clear")
  end
  vim.o.termguicolors = true
  vim.o.background = "dark"
  vim.g.colors_name = "mate"

  local hl = M.highlights()
  for group, spec in pairs(hl) do
    -- A string is a link; a table is a full definition.
    if type(spec) == "string" then
      vim.api.nvim_set_hl(0, group, { link = spec })
    else
      vim.api.nvim_set_hl(0, group, spec)
    end
  end

  local ansi = require("mate.palette").ansi
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = ansi[i]
  end
end

return M
