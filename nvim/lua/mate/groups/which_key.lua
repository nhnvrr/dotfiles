return function(c, _)
  return {
    WhichKey = { fg = c.keyword, bg = c.bg_alt },
    WhichKeyGroup = { fg = c.func, bg = c.bg_alt },
    WhichKeyDesc = { fg = c.fg, bg = c.bg_alt },
    WhichKeySeparator = { fg = c.comment, bg = c.bg_alt },
    WhichKeyValue = { fg = c.grey_light, bg = c.bg_alt },
    WhichKeyIcon = { fg = c.teal, bg = c.bg_alt },
    WhichKeyNormal = { fg = c.fg, bg = c.bg_alt },
    WhichKeyBorder = { fg = c.border, bg = c.bg_alt },
    WhichKeyTitle = { fg = c.silver, bg = c.bg_alt, bold = true },
    WhichKeyIconAzure = { fg = c.func, bg = c.bg_alt },
    WhichKeyIconBlue = { fg = c.func, bg = c.bg_alt },
    WhichKeyIconCyan = { fg = c.teal, bg = c.bg_alt },
    WhichKeyIconGreen = { fg = c.ok, bg = c.bg_alt },
    WhichKeyIconGrey = { fg = c.grey, bg = c.bg_alt },
    WhichKeyIconOrange = { fg = c.keyword, bg = c.bg_alt },
    WhichKeyIconPurple = { fg = c.type, bg = c.bg_alt },
    WhichKeyIconRed = { fg = c.error, bg = c.bg_alt },
    WhichKeyIconYellow = { fg = c.warning, bg = c.bg_alt },
  }
end
