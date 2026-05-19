local M = {}

function M.diag_counts()
  local counts = vim.diagnostic.count(0)
  local e = counts[vim.diagnostic.severity.ERROR] or 0
  local w = counts[vim.diagnostic.severity.WARN] or 0
  if e + w == 0 then return "" end
  local parts = {}
  if e > 0 then parts[#parts + 1] = "E:" .. e end
  if w > 0 then parts[#parts + 1] = "W:" .. w end
  return table.concat(parts, " ")
end

vim.o.laststatus = 3
vim.o.statusline = " %f %m%r%=%{%v:lua.require'config.statusline'.diag_counts()%} %l:%c "

vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function() vim.cmd.redrawstatus() end,
})

return M
