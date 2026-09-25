-- Built on the sixteen slots alacritty's dark.toml defines, read at load time
-- so the terminal and the editor cannot drift. Surfaces and the comment grey
-- are not in the palette; they are blended from the ground. No group paints
-- the ground itself: the terminal shows through, so it is alacritty's by
-- definition.

local function read_palette()
	local paths = {
		vim.fn.expand("~/.config/alacritty/dark.toml"),
		vim.fs.joinpath(vim.fs.dirname(vim.uv.fs_realpath(vim.fn.stdpath("config")) or ""), "alacritty/dark.toml"),
	}
	for _, path in ipairs(paths) do
		local fd = io.open(path, "r")
		if fd then
			local p, section = { normal = {}, bright = {}, primary = {} }, nil
			for line in fd:lines() do
				section = line:match("^%[colors%.(%w+)%]") or (line:match("^%[") and "other") or section
				local key, hex = line:match('^(%w+)%s*=%s*"[0#x]*(%x%x%x%x%x%x)"')
				if key and p[section] then
					p[section][key] = "#" .. hex:lower()
				end
			end
			fd:close()
			return p
		end
	end
end

local raw = read_palette()
if not raw then
	vim.notify("mate: alacritty/dark.toml not found", vim.log.levels.ERROR)
	return
end

local function blend(from, to, t)
	local a, b = tonumber(from:sub(2), 16), tonumber(to:sub(2), 16)
	local out = 0
	for shift = 16, 0, -8 do
		local x, y = bit.band(bit.rshift(a, shift), 0xff), bit.band(bit.rshift(b, shift), 0xff)
		out = out + bit.lshift(math.floor(x + (y - x) * t + 0.5), shift)
	end
	return string.format("#%06x", out)
end

local n, b = raw.normal, raw.bright
local bg = raw.primary.background
local c = {
	bg = bg,
	fg = n.white,
	text = raw.primary.foreground,
	keyword = n.magenta,
	punct = n.blue,
	orange = n.red,
	green = n.green,
	gold = n.yellow,
	teal = n.cyan,
	red = b.red,
	surface1 = blend(bg, "#ffffff", 0.05),
	float = blend(bg, "#ffffff", 0.07),
	surface2 = blend(bg, "#ffffff", 0.13),
	surface3 = blend(bg, "#ffffff", 0.18),
	nontext = blend(bg, "#ffffff", 0.25),
	muted = blend(bg, "#ffffff", 0.35),
	comment = blend(bg, "#ffffff", 0.48),
}

vim.cmd("hi clear")
vim.g.colors_name = "mate"
vim.o.background = "dark"

local hl = function(name, spec)
	vim.api.nvim_set_hl(0, name, spec)
end

for i, key in ipairs({ "black", "red", "green", "yellow", "blue", "magenta", "cyan", "white" }) do
	vim.g["terminal_color_" .. (i - 1)] = n[key]
	vim.g["terminal_color_" .. (i + 7)] = b[key]
end

-- editor
hl("Normal", { fg = c.fg })
hl("NormalNC", { link = "Normal" })
hl("NormalFloat", { fg = c.text })
hl("FloatBorder", { fg = c.surface3 })
hl("FloatTitle", { fg = c.fg, bold = true })
hl("Cursor", { fg = c.bg, bg = c.fg })
hl("CursorLine", { bg = c.surface1 })
hl("CursorColumn", { link = "CursorLine" })
hl("ColorColumn", { bg = c.surface2 })
hl("LineNr", { fg = c.muted })
hl("CursorLineNr", { fg = c.fg })
hl("SignColumn", {})
hl("FoldColumn", { fg = c.muted })
hl("Folded", { fg = c.comment })
hl("WinSeparator", { fg = c.surface2 })
hl("VertSplit", { link = "WinSeparator" })
hl("StatusLine", { fg = c.text })
hl("StatusLineNC", { fg = c.muted })
hl("TabLine", { fg = c.muted })
hl("TabLineSel", { fg = c.fg, bold = true })
hl("TabLineFill", {})
hl("WinBar", { fg = c.text })
hl("WinBarNC", { fg = c.muted })
hl("Visual", { bg = c.surface3 })
hl("Search", { fg = c.bg, bg = c.gold })
hl("IncSearch", { fg = c.bg, bg = c.orange })
hl("CurSearch", { link = "IncSearch" })
hl("Substitute", { link = "IncSearch" })
hl("MatchParen", { bg = c.surface3, bold = true })
hl("Pmenu", { fg = c.text, bg = c.float })
hl("PmenuSel", { fg = c.fg, bg = c.surface3 })
hl("PmenuSbar", { bg = c.surface1 })
hl("PmenuThumb", { bg = c.muted })
hl("PmenuMatch", { fg = c.gold, bold = true })
hl("PmenuMatchSel", { fg = c.gold, bold = true })
hl("NonText", { fg = c.nontext })
hl("Whitespace", { link = "NonText" })
hl("SpecialKey", { link = "NonText" })
hl("EndOfBuffer", { link = "NonText" })
hl("Conceal", { fg = c.comment })
hl("Directory", { fg = c.teal })
hl("Title", { fg = c.fg, bold = true })
hl("ErrorMsg", { fg = c.red })
hl("WarningMsg", { fg = c.gold })
hl("MoreMsg", { fg = c.green })
hl("ModeMsg", { fg = c.text })
hl("Question", { fg = c.teal })
hl("QuickFixLine", { bg = c.surface2 })
hl("WildMenu", { link = "PmenuSel" })
hl("SpellBad", { undercurl = true, sp = c.red })
hl("SpellCap", { undercurl = true, sp = c.gold })
hl("SpellRare", { undercurl = true, sp = c.teal })
hl("SpellLocal", { undercurl = true, sp = c.teal })

-- syntax
hl("Comment", { fg = c.comment })
hl("Constant", { fg = c.green })
hl("String", { fg = c.gold })
hl("Character", { link = "String" })
hl("Number", { fg = c.green })
hl("Boolean", { link = "Number" })
hl("Float", { link = "Number" })
hl("Identifier", { fg = c.teal })
hl("Function", { fg = c.fg })
hl("Statement", { fg = c.keyword })
hl("Keyword", { link = "Statement" })
hl("Conditional", { link = "Statement" })
hl("Repeat", { link = "Statement" })
hl("Label", { link = "Statement" })
hl("Exception", { link = "Statement" })
hl("Operator", { fg = c.text })
hl("PreProc", { fg = c.keyword })
hl("Include", { link = "PreProc" })
hl("Type", { fg = c.orange })
hl("StorageClass", { link = "Statement" })
hl("Special", { fg = c.orange })
hl("Delimiter", { fg = c.punct })
hl("Underlined", { underline = true })
hl("Error", { fg = c.red })
hl("Todo", { fg = c.bg, bg = c.gold, bold = true })

-- treesitter
hl("@variable", { fg = c.teal })
hl("@variable.builtin", { fg = c.orange })
hl("@variable.parameter", { fg = c.teal })
hl("@variable.member", { fg = c.text })
hl("@property", { link = "@variable.member" })
hl("@constant", { fg = c.teal })
hl("@constant.builtin", { fg = c.green })
hl("@module", { fg = c.text })
hl("@label", { fg = c.keyword })
hl("@string", { link = "String" })
hl("@string.escape", { fg = c.orange })
hl("@string.regexp", { fg = c.orange })
hl("@string.special", { fg = c.orange })
hl("@function", { link = "Function" })
hl("@function.builtin", { fg = c.fg })
hl("@constructor", { fg = c.orange })
hl("@keyword", { link = "Keyword" })
hl("@operator", { link = "Operator" })
hl("@type", { link = "Type" })
hl("@type.builtin", { fg = c.orange })
hl("@attribute", { fg = c.keyword })
hl("@punctuation", { link = "Delimiter" })
hl("@punctuation.delimiter", { link = "Delimiter" })
hl("@punctuation.bracket", { link = "Delimiter" })
hl("@punctuation.special", { fg = c.orange })
hl("@tag", { fg = c.orange })
hl("@tag.attribute", { fg = c.teal })
hl("@tag.delimiter", { link = "Delimiter" })
hl("@comment.todo", { link = "Todo" })
hl("@comment.error", { fg = c.bg, bg = c.red, bold = true })
hl("@comment.warning", { fg = c.bg, bg = c.gold, bold = true })
hl("@comment.note", { fg = c.bg, bg = c.teal, bold = true })
hl("@markup.heading", { fg = c.gold, bold = true })
hl("@markup.strong", { bold = true })
hl("@markup.italic", { italic = true })
hl("@markup.strikethrough", { strikethrough = true })
hl("@markup.link", { fg = c.teal })
hl("@markup.link.url", { fg = c.teal, underline = true })
hl("@markup.raw", { fg = c.green })
hl("@markup.list", { fg = c.orange })
hl("@markup.quote", { fg = c.comment, italic = true })
hl("@diff.plus", { fg = c.green })
hl("@diff.minus", { fg = c.red })
hl("@diff.delta", { fg = c.gold })

-- lsp semantic tokens: route to the treesitter groups instead of their defaults
for token, group in pairs({
	variable = "@variable", parameter = "@variable.parameter", property = "@property",
	["function"] = "@function", method = "@function", type = "@type", class = "@type",
	interface = "@type", enum = "@type", typeParameter = "@type", namespace = "@module",
	enumMember = "@constant", keyword = "@keyword", decorator = "@attribute",
}) do
	hl("@lsp.type." .. token, { link = group })
end
hl("@lsp.typemod.variable.readonly", { link = "@constant" })
hl("LspReferenceText", { bg = c.surface2 })
hl("LspReferenceRead", { link = "LspReferenceText" })
hl("LspReferenceWrite", { link = "LspReferenceText" })
hl("LspInlayHint", { fg = c.comment })

-- diagnostics
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.gold })
hl("DiagnosticInfo", { fg = c.teal })
hl("DiagnosticHint", { fg = c.comment })
hl("DiagnosticOk", { fg = c.green })
for _, kind in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
	local fg = vim.api.nvim_get_hl(0, { name = "Diagnostic" .. kind }).fg
	hl("DiagnosticUnderline" .. kind, { undercurl = true, sp = fg })
end

-- diff and git
hl("DiffAdd", { bg = blend(bg, c.green, 0.18) })
hl("DiffDelete", { bg = blend(bg, c.red, 0.18) })
hl("DiffChange", { bg = blend(bg, c.gold, 0.10) })
hl("DiffText", { bg = blend(bg, c.gold, 0.25) })
hl("Added", { fg = c.green })
hl("Changed", { fg = c.gold })
hl("Removed", { fg = c.red })
hl("GitSignsAdd", { link = "Added" })
hl("GitSignsChange", { link = "Changed" })
hl("GitSignsDelete", { link = "Removed" })

-- plugins
hl("CmpItemAbbr", { fg = c.text })
hl("CmpItemAbbrMatch", { fg = c.gold, bold = true })
hl("CmpItemAbbrMatchFuzzy", { link = "CmpItemAbbrMatch" })
hl("CmpItemAbbrDeprecated", { fg = c.comment, strikethrough = true })
hl("CmpItemKind", { fg = c.keyword })
hl("CmpItemMenu", { fg = c.comment })
