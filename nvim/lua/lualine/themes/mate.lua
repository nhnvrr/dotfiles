-- lualine's "auto" loads this whenever colors_name is "mate". Its generated
-- theme would fill the transparent StatusLine with #000000, so only the mode
-- block gets a bg: the mode's colour, with the terminal ground as ink.
local function fg(group)
	return string.format("#%06x", vim.api.nvim_get_hl(0, { name = group, link = false }).fg or 0)
end

local ink = vim.g.terminal_color_0
local text, muted = fg("StatusLine"), fg("StatusLineNC")
local function mode(group)
	return { a = { fg = ink, bg = fg(group), gui = "bold" }, b = { fg = text }, c = { fg = text } }
end

return {
	normal = mode("Normal"),
	insert = mode("String"),
	visual = mode("Type"),
	replace = mode("DiagnosticError"),
	command = mode("@variable"),
	inactive = { a = { fg = muted }, b = { fg = muted }, c = { fg = muted } },
}
