return function(c, _)
  local kinds = {
    "Array", "Boolean", "Class", "Color", "Constant", "Constructor", "Enum", "EnumMember",
    "Event", "Field", "File", "Folder", "Function", "Interface", "Key", "Keyword", "Method",
    "Module", "Namespace", "Null", "Number", "Object", "Operator", "Package", "Property",
    "Reference", "Snippet", "String", "Struct", "Text", "TypeParameter", "Unit", "Value",
    "Variable",
  }
  local hl = {
    BlinkCmpMenu = { fg = c.fg, bg = c.bg_alt },
    BlinkCmpMenuBorder = { fg = c.border, bg = c.bg_alt },
    BlinkCmpMenuSelection = { bg = c.surface },
    BlinkCmpScrollBarGutter = { bg = c.bg_alt },
    BlinkCmpScrollBarThumb = { bg = c.border },

    BlinkCmpLabel = { fg = c.fg },
    BlinkCmpLabelMatch = { fg = c.keyword, bold = true },
    BlinkCmpLabelDetail = { fg = c.grey },
    BlinkCmpLabelDescription = { fg = c.grey },
    BlinkCmpLabelDeprecated = { fg = c.comment, strikethrough = true },
    BlinkCmpSource = { fg = c.grey },
    BlinkCmpGhostText = { fg = c.comment, italic = true },

    BlinkCmpKind = { fg = c.func },
    BlinkCmpKindDefault = { fg = c.grey_light },
    BlinkCmpKindCopilot = { fg = c.silver },

    BlinkCmpDoc = { fg = c.fg, bg = c.bg_alt },
    BlinkCmpDocBorder = { fg = c.border, bg = c.bg_alt },
    BlinkCmpDocSeparator = { fg = c.border, bg = c.bg_alt },
    BlinkCmpDocCursorLine = { bg = c.bg_soft },

    BlinkCmpSignatureHelp = { fg = c.fg, bg = c.bg_alt },
    BlinkCmpSignatureHelpBorder = { fg = c.border, bg = c.bg_alt },
    BlinkCmpSignatureHelpActiveParameter = { fg = c.keyword, bold = true },
  }
  for _, k in ipairs(kinds) do
    hl["BlinkCmpKind" .. k] = "LspKind" .. k
  end
  return hl
end
