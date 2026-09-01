-- mate — the one place every colour in this repo is defined.
-- alacritty/mate.toml and herdr's [theme.custom] are generated from here by
-- `nvim -l nvim/lua/mate/build.lua`; edit this file, never those.
local M = {}

M.name = "mate"
M.author = "nhnvrr"

M.colors = {
  -- Ground, three depths plus selection and a border tone.
  bg = "#13151a",
  bg_alt = "#1a1d23",
  bg_soft = "#1f2229",
  surface = "#272b33",
  selection = "#2f343d",
  border = "#383d47",

  -- Greys, dark to light.
  comment = "#7b8089",
  grey = "#8d9199",
  grey_light = "#aab0b8",
  silver = "#c6cad1",
  fg = "#dfe2e7",
  fg_bright = "#f0f2f5",

  -- Syntax accents, one semantic each.
  keyword = "#d99a74",
  func = "#7ea6c9",
  type = "#bfa7d3",
  string = "#9db58f",
  teal = "#86b3b3",
  signal = "#c2946e",

  -- Diagnostics and state.
  error = "#df8a8a",
  warning = "#d6a55e",
  info = "#8c9cb8",
  hint = "#ad9484",
  ok = "#77bb87",

  -- Bright ANSI half, one step lighter than the normal accents.
  bright_red = "#e69a9a",
  bright_green = "#a9c49a",
  bright_blue = "#8fb5d6",
  bright_magenta = "#cbb6dc",
  bright_cyan = "#98c4c4",

  -- Tinted grounds for diff and the stopped debugger frame.
  diff_add = "#1a2620",
  diff_delete = "#2a1a1d",
  diff_change = "#1e222b",
  diff_text = "#2b3340",

  none = "NONE",
}

local c = M.colors

-- The sixteen terminal slots. Alacritty owns them; nvim mirrors them into
-- :terminal so both draw fish and btop identically.
M.ansi = {
  [0] = c.bg_alt,
  [1] = c.error,
  [2] = c.string,
  [3] = c.keyword,
  [4] = c.func,
  [5] = c.type,
  [6] = c.teal,
  [7] = c.silver,
  [8] = c.comment,
  [9] = c.bright_red,
  [10] = c.ok,
  [11] = c.warning,
  [12] = c.info,
  [13] = c.bright_magenta,
  [14] = c.bright_cyan,
  [15] = c.fg_bright,
}

-- Indexed slots above 15, same roles luna's extras use so a tool written
-- against them keeps working.
M.indexed = {
  [16] = c.signal,
  [17] = c.keyword,
  [18] = c.bg_alt,
  [19] = c.selection,
  [20] = c.comment,
  [21] = c.silver,
}

return M
