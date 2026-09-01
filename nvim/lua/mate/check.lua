-- Lists highlight groups a loaded plugin defined that resolve to nothing —
-- the ones the theme forgot. Run with the full config loaded:
--   nvim --headless -c 'lua vim.defer_fn(function() require("mate.check")(); vim.cmd.qa() end, 1500)'
return function()
  local mine = require("mate").highlights()
  local prefixes = {
    "^BlinkCmp", "^FzfLua", "^GitSigns", "^WhichKey", "^NeoTree", "^Dap", "^NvimDap",
    "^Neotest", "^Diagnostic", "^Lsp", "^lualine",
  }
  local missing = {}
  for _, group in ipairs(vim.fn.getcompletion("", "highlight")) do
    local watched = false
    for _, pat in ipairs(prefixes) do
      if group:match(pat) then
        watched = true
        break
      end
    end
    if watched and mine[group] == nil then
      local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
      if ok and vim.tbl_isempty(hl) then
        missing[#missing + 1] = group
      end
    end
  end
  table.sort(missing)
  for _, g in ipairs(missing) do
    io.write("  " .. g .. "\n")
  end
  io.write(("mate: %d unresolved groups\n"):format(#missing))
  return missing
end
