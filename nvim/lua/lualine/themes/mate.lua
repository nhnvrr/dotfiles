-- lualine's "auto" loads this whenever colors_name is "mate". Its generated
-- theme would fill the transparent StatusLine with #000000, so every section
-- here leaves bg unset and the mode is carried by the colour of its name.
local function fg(group)
	return string.format("#%06x", vim.api.nvim_get_hl(0, { name = group, link = false }).fg or 0)
end

local text, muted = fg("StatusLine"), fg("StatusLineNC")
local function mode(group)
	return { a = { fg = fg(group), gui = "bold" }, b = { fg = text }, c = { fg = text } }
end

return {
	normal = mode("Normal"),
	insert = mode("String"),
	visual = mode("Type"),
	replace = mode("DiagnosticError"),
	command = mode("@variable"),
	inactive = { a = { fg = muted }, b = { fg = muted }, c = { fg = muted } },
}
