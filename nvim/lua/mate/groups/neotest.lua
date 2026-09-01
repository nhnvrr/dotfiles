return function(c, _)
  return {
    NeotestPassed = { fg = c.ok },
    NeotestFailed = { fg = c.error },
    NeotestRunning = { fg = c.warning },
    NeotestSkipped = { fg = c.comment },
    NeotestUnknown = { fg = c.grey },
    NeotestWatching = { fg = c.warning },
    NeotestTest = { fg = c.fg },
    NeotestNamespace = { fg = c.type },
    NeotestFile = { fg = c.func },
    NeotestDir = { fg = c.func },
    NeotestAdapterName = { fg = c.keyword, bold = true },
    NeotestIndent = { fg = c.surface },
    NeotestExpandMarker = { fg = c.grey },
    NeotestMarked = { fg = c.signal, bold = true },
    NeotestTarget = { fg = c.keyword },
    NeotestFocused = { bold = true, underline = true },
    NeotestWinSelect = { fg = c.keyword, bold = true },
    NeotestBorder = { fg = c.border, bg = c.bg_alt },
  }
end
