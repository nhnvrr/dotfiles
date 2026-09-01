return function(c, _)
  return {
    DiagnosticError = { fg = c.error },
    DiagnosticWarn = { fg = c.warning },
    DiagnosticInfo = { fg = c.info },
    DiagnosticHint = { fg = c.hint },
    DiagnosticOk = { fg = c.ok },

    -- Colour on the ground, no box: virtual text should not compete with code.
    DiagnosticVirtualTextError = { fg = c.error, bg = c.bg },
    DiagnosticVirtualTextWarn = { fg = c.warning, bg = c.bg },
    DiagnosticVirtualTextInfo = { fg = c.info, bg = c.bg },
    DiagnosticVirtualTextHint = { fg = c.hint, bg = c.bg },
    DiagnosticVirtualTextOk = { fg = c.ok, bg = c.bg },
    DiagnosticVirtualLinesError = { fg = c.error },
    DiagnosticVirtualLinesWarn = { fg = c.warning },
    DiagnosticVirtualLinesInfo = { fg = c.info },
    DiagnosticVirtualLinesHint = { fg = c.hint },
    DiagnosticVirtualLinesOk = { fg = c.ok },

    DiagnosticUnderlineError = { undercurl = true, sp = c.error },
    DiagnosticUnderlineWarn = { undercurl = true, sp = c.warning },
    DiagnosticUnderlineInfo = { undercurl = true, sp = c.info },
    DiagnosticUnderlineHint = { undercurl = true, sp = c.hint },
    DiagnosticUnderlineOk = { undercurl = true, sp = c.ok },

    DiagnosticFloatingError = { fg = c.error, bg = c.bg_alt },
    DiagnosticFloatingWarn = { fg = c.warning, bg = c.bg_alt },
    DiagnosticFloatingInfo = { fg = c.info, bg = c.bg_alt },
    DiagnosticFloatingHint = { fg = c.hint, bg = c.bg_alt },
    DiagnosticFloatingOk = { fg = c.ok, bg = c.bg_alt },

    DiagnosticSignError = { fg = c.error, bg = c.bg },
    DiagnosticSignWarn = { fg = c.warning, bg = c.bg },
    DiagnosticSignInfo = { fg = c.info, bg = c.bg },
    DiagnosticSignHint = { fg = c.hint, bg = c.bg },
    DiagnosticSignOk = { fg = c.ok, bg = c.bg },

    DiagnosticUnnecessary = { fg = c.comment },
    DiagnosticDeprecated = { strikethrough = true, sp = c.grey },
  }
end
