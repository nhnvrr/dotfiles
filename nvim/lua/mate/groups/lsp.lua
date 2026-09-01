return function(c, _)
  return {
    LspReferenceText = { bg = c.surface },
    LspReferenceRead = { bg = c.surface },
    LspReferenceWrite = { bg = c.surface, underline = true, sp = c.border },
    LspReferenceTarget = { bg = c.surface },
    LspInlayHint = { fg = c.comment, bg = c.bg_soft, italic = true },
    LspCodeLens = { fg = c.comment },
    LspCodeLensSeparator = { fg = c.surface },
    LspSignatureActiveParameter = { fg = c.keyword, bold = true },
    LspInfoBorder = { fg = c.border, bg = c.bg_alt },
  }
end
