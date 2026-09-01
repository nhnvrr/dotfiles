local c = require("mate").colors()

local function mode(accent)
  return {
    a = { fg = c.bg, bg = accent, gui = "bold" },
    b = { fg = c.silver, bg = c.surface },
    c = { fg = c.grey_light, bg = c.bg },
  }
end

return {
  normal = mode(c.func),
  insert = mode(c.string),
  visual = mode(c.type),
  replace = mode(c.keyword),
  command = mode(c.warning),
  terminal = mode(c.teal),
  inactive = {
    a = { fg = c.grey, bg = c.bg_alt },
    b = { fg = c.grey, bg = c.bg_alt },
    c = { fg = c.comment, bg = c.bg },
  },
}
