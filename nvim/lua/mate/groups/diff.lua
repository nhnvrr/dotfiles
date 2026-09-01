return function(c, _)
  return {
    DiffAdd = { bg = c.diff_add },
    DiffDelete = { fg = c.surface, bg = c.diff_delete },
    DiffChange = { bg = c.diff_change },
    DiffText = { bg = c.diff_text, bold = true },
  }
end
