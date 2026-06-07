-- Kintsugi Dark Flared — port from the VSCode theme of the same name.
-- Loadable via :colorscheme kintsugi-flared

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.o.background = "dark"
vim.g.colors_name = "kintsugi-flared"

local p = {
	-- backgrounds
	bg            = "#161618",
	bg_dark       = "#131314",
	bg_line       = "#1d1d1c",
	bg_float      = "#1c1c1c",
	bg_selection  = "#2a313a",
	bg_search     = "#3a3326",
	bg_match      = "#3a4248",
	bg_gutter_alt = "#20201f",

	-- foregrounds
	fg          = "#dddddd",
	fg_dim      = "#c9c4b8",
	fg_muted    = "#969b8c",
	fg_variable = "#BCAC8F",
	fg_punct    = "#7f7b66",

	-- subtle UI
	border         = "#2a2a28",
	border_strong  = "#3a3a37",
	line_nr        = "#444444",
	line_nr_active = "#b4aa60",
	comment        = "#5f5f5f",

	-- syntax accents
	gold       = "#dbad49",
	gold_soft  = "#d4a943",
	red        = "#D66848",
	orange     = "#E08542",
	peach      = "#cc7f66",
	amber      = "#DB9833",
	slate      = "#798283",
	teal       = "#678E87",

	-- diagnostics / diff / git
	diag_error = "#b38f8f",
	diag_warn  = "#ebcb8b",
	diag_info  = "#6c7a8a",
	diag_hint  = "#a3be8c",
	link       = "#8fa3b3",

	none = "NONE",
}

local hl = vim.api.nvim_set_hl

-- ─── UI core ─────────────────────────────────────────────
hl(0, "Normal",          { fg = p.fg,        bg = p.bg })
hl(0, "NormalNC",        { fg = p.fg,        bg = p.bg })
hl(0, "NormalFloat",     { fg = p.fg_dim,    bg = p.bg_float })
hl(0, "FloatBorder",     { fg = p.border_strong, bg = p.bg_float })
hl(0, "FloatTitle",      { fg = p.gold,      bg = p.bg_float, bold = true })
hl(0, "LineNr",          { fg = p.line_nr,   bg = p.bg })
hl(0, "CursorLine",      { bg = p.bg_line })
hl(0, "CursorLineNr",    { fg = p.line_nr_active, bg = p.bg_line, bold = true })
hl(0, "CursorColumn",    { bg = p.bg_line })
hl(0, "Visual",          { bg = p.bg_selection })
hl(0, "VisualNOS",       { bg = p.bg_selection })
hl(0, "Search",          { fg = p.fg, bg = p.bg_search })
hl(0, "IncSearch",       { fg = p.bg, bg = p.gold, bold = true })
hl(0, "CurSearch",       { fg = p.bg, bg = p.gold, bold = true })
hl(0, "MatchParen",      { bg = p.bg_match, bold = true })
hl(0, "Pmenu",           { fg = p.fg_dim, bg = p.bg_float })
hl(0, "PmenuSel",        { fg = p.fg,     bg = "#3e3b2c", bold = true })
hl(0, "PmenuSbar",       { bg = p.bg_gutter_alt })
hl(0, "PmenuThumb",      { bg = p.border_strong })
hl(0, "WinSeparator",    { fg = p.border, bg = p.none })
hl(0, "VertSplit",       { fg = p.border, bg = p.none })
hl(0, "StatusLine",      { fg = p.fg_muted, bg = p.bg_dark })
hl(0, "StatusLineNC",    { fg = p.comment,  bg = p.bg_dark })
hl(0, "TabLine",         { fg = p.fg_muted, bg = p.bg_dark })
hl(0, "TabLineFill",     { bg = p.bg_dark })
hl(0, "TabLineSel",      { fg = p.fg, bg = p.bg, bold = true })
hl(0, "Folded",          { fg = p.fg_muted, bg = "#1f1f1f" })
hl(0, "FoldColumn",      { fg = p.fg_muted, bg = p.bg })
hl(0, "ColorColumn",     { bg = p.bg_line })
hl(0, "SignColumn",      { fg = p.fg_dim, bg = p.bg })
hl(0, "Whitespace",      { fg = "#2e2c28" })
hl(0, "NonText",         { fg = p.line_nr })
hl(0, "EndOfBuffer",     { fg = p.bg })
hl(0, "Title",           { fg = p.gold, bold = true })
hl(0, "Directory",       { fg = p.gold })
hl(0, "Question",        { fg = p.diag_hint })
hl(0, "ModeMsg",         { fg = p.gold, bold = true })
hl(0, "MoreMsg",         { fg = p.diag_hint })
hl(0, "WarningMsg",      { fg = p.diag_warn })
hl(0, "ErrorMsg",        { fg = p.diag_error })
hl(0, "Conceal",         { fg = p.comment })
hl(0, "SpecialKey",      { fg = p.line_nr })
hl(0, "QuickFixLine",    { bg = p.bg_line, bold = true })

-- ─── Sintaxis clásica ────────────────────────────────────
hl(0, "Comment",        { fg = p.comment, italic = true })
hl(0, "SpecialComment", { fg = p.comment, italic = true, bold = true })
hl(0, "String",         { fg = p.peach })
hl(0, "Character",      { fg = p.peach })
hl(0, "Number",         { fg = p.amber })
hl(0, "Float",          { fg = p.amber })
hl(0, "Boolean",        { fg = p.amber })
hl(0, "Constant",       { fg = p.amber })
hl(0, "Identifier",     { fg = p.fg_variable })
hl(0, "Function",       { fg = p.slate })
hl(0, "Statement",      { fg = p.gold, bold = true })
hl(0, "Keyword",        { fg = p.red, bold = true })
hl(0, "Conditional",    { fg = p.red, bold = true })
hl(0, "Repeat",         { fg = p.red, bold = true })
hl(0, "Label",          { fg = p.red, bold = true })
hl(0, "Exception",      { fg = p.red, bold = true })
hl(0, "Operator",       { fg = p.orange })
hl(0, "PreProc",        { fg = p.orange })
hl(0, "Include",        { fg = p.red, bold = true })
hl(0, "Define",         { fg = p.orange })
hl(0, "Macro",          { fg = p.orange })
hl(0, "Type",           { fg = p.gold, bold = true })
hl(0, "StorageClass",   { fg = p.gold, bold = true })
hl(0, "Structure",      { fg = p.gold, bold = true })
hl(0, "Typedef",        { fg = p.gold, bold = true })
hl(0, "Special",        { fg = p.orange })
hl(0, "SpecialChar",    { fg = p.slate })
hl(0, "Tag",            { fg = p.gold, bold = true })
hl(0, "Delimiter",      { fg = p.fg_punct })
hl(0, "Underlined",     { fg = p.link, underline = true })
hl(0, "Todo",           { fg = p.gold, bg = p.none, bold = true })

-- ─── Treesitter ──────────────────────────────────────────
hl(0, "@comment",                { link = "Comment" })
hl(0, "@comment.documentation",  { fg = p.comment, italic = true })
hl(0, "@string",                 { link = "String" })
hl(0, "@string.escape",          { fg = p.slate })
hl(0, "@string.special",         { fg = p.orange })
hl(0, "@string.regexp",          { fg = p.orange })
hl(0, "@number",                 { link = "Number" })
hl(0, "@boolean",                { link = "Boolean" })
hl(0, "@float",                  { link = "Float" })
hl(0, "@constant",               { fg = p.amber })
hl(0, "@constant.builtin",       { fg = p.amber, bold = true })
hl(0, "@constant.macro",         { fg = p.orange })

hl(0, "@keyword",                { fg = p.red, bold = true })
hl(0, "@keyword.return",         { fg = p.red, bold = true })
hl(0, "@keyword.function",       { fg = p.gold, bold = true })
hl(0, "@keyword.operator",       { fg = p.red, bold = true })
hl(0, "@keyword.import",         { fg = p.red, bold = true })
hl(0, "@keyword.coroutine",      { fg = p.red, bold = true })
hl(0, "@keyword.exception",      { fg = p.red, bold = true })
hl(0, "@keyword.conditional",    { fg = p.red, bold = true })
hl(0, "@keyword.repeat",         { fg = p.red, bold = true })
hl(0, "@keyword.storage",        { fg = p.gold, bold = true })

hl(0, "@function",               { fg = p.slate })
hl(0, "@function.call",          { fg = p.slate })
hl(0, "@function.builtin",       { fg = p.orange })
hl(0, "@function.macro",         { fg = p.orange })
hl(0, "@method",                 { fg = p.slate })
hl(0, "@method.call",            { fg = p.slate })
hl(0, "@constructor",            { fg = p.gold, bold = true })
hl(0, "@parameter",              { fg = p.fg_variable })

hl(0, "@variable",               { fg = p.fg_variable })
hl(0, "@variable.builtin",       { fg = p.gold, bold = true })
hl(0, "@variable.member",        { fg = p.slate })
hl(0, "@variable.parameter",     { fg = p.fg_variable })

hl(0, "@type",                   { fg = p.slate })
hl(0, "@type.builtin",           { fg = p.orange })
hl(0, "@type.definition",        { fg = p.gold, bold = true })
hl(0, "@property",               { fg = p.slate })
hl(0, "@field",                  { fg = p.slate })

hl(0, "@punctuation.bracket",    { fg = p.fg_punct })
hl(0, "@punctuation.delimiter",  { fg = p.fg_punct })
hl(0, "@punctuation.special",    { fg = p.orange })

hl(0, "@operator",               { fg = p.orange })
hl(0, "@tag",                    { fg = p.gold, bold = true })
hl(0, "@tag.attribute",          { fg = p.slate })
hl(0, "@tag.delimiter",          { fg = p.fg_punct })
hl(0, "@tag.builtin",            { fg = p.gold, bold = true })
hl(0, "@attribute",              { fg = p.teal })
hl(0, "@namespace",              { fg = p.slate })
hl(0, "@module",                 { fg = p.slate })
hl(0, "@label",                  { fg = p.red, bold = true })

-- Markdown / markup
hl(0, "@markup.heading",         { fg = p.gold, bold = true })
hl(0, "@markup.heading.1",       { fg = p.gold, bold = true })
hl(0, "@markup.heading.2",       { fg = p.gold, bold = true })
hl(0, "@markup.heading.3",       { fg = p.gold_soft, bold = true })
hl(0, "@markup.heading.4",       { fg = p.gold_soft, bold = true })
hl(0, "@markup.strong",          { fg = p.gold, bold = true })
hl(0, "@markup.italic",          { fg = p.fg_variable, italic = true })
hl(0, "@markup.strikethrough",   { fg = p.comment, strikethrough = true })
hl(0, "@markup.underline",       { fg = p.link, underline = true })
hl(0, "@markup.raw",             { fg = p.peach })
hl(0, "@markup.raw.block",       { fg = p.peach })
hl(0, "@markup.link",            { fg = p.slate })
hl(0, "@markup.link.url",        { fg = p.link, underline = true })
hl(0, "@markup.link.label",      { fg = p.slate })
hl(0, "@markup.list",            { fg = p.orange })
hl(0, "@markup.quote",           { fg = p.comment, italic = true })

-- ─── LSP semantic tokens ────────────────────────────────
hl(0, "@lsp.type.class",         { fg = p.gold, bold = true })
hl(0, "@lsp.type.function",      { fg = p.slate })
hl(0, "@lsp.type.method",        { fg = p.slate })
hl(0, "@lsp.type.parameter",     { fg = p.fg_variable })
hl(0, "@lsp.type.variable",      { fg = p.fg_variable })
hl(0, "@lsp.type.property",      { fg = p.slate })
hl(0, "@lsp.type.enum",          { fg = p.gold, bold = true })
hl(0, "@lsp.type.enumMember",    { fg = p.amber })
hl(0, "@lsp.type.interface",     { fg = p.gold, bold = true })
hl(0, "@lsp.type.namespace",     { fg = p.slate })
hl(0, "@lsp.type.type",          { fg = p.slate })
hl(0, "@lsp.type.typeParameter", { fg = p.orange })
hl(0, "@lsp.type.decorator",     { fg = p.teal })
hl(0, "@lsp.type.macro",         { fg = p.orange })
hl(0, "@lsp.type.struct",        { fg = p.gold, bold = true })
hl(0, "@lsp.type.keyword",       { fg = p.red, bold = true })
hl(0, "@lsp.mod.readonly",       { fg = p.amber })
hl(0, "@lsp.mod.deprecated",     { strikethrough = true })
hl(0, "@lsp.mod.defaultLibrary", { fg = p.orange })

-- ─── Diagnostics ────────────────────────────────────────
hl(0, "DiagnosticError",                { fg = p.diag_error })
hl(0, "DiagnosticWarn",                 { fg = p.diag_warn })
hl(0, "DiagnosticInfo",                 { fg = p.diag_info })
hl(0, "DiagnosticHint",                 { fg = p.diag_hint })
hl(0, "DiagnosticOk",                   { fg = p.diag_hint })

hl(0, "DiagnosticSignError",            { fg = p.diag_error, bg = p.bg })
hl(0, "DiagnosticSignWarn",             { fg = p.diag_warn,  bg = p.bg })
hl(0, "DiagnosticSignInfo",             { fg = p.diag_info,  bg = p.bg })
hl(0, "DiagnosticSignHint",             { fg = p.diag_hint,  bg = p.bg })

hl(0, "DiagnosticUnderlineError",       { undercurl = true, sp = p.diag_error })
hl(0, "DiagnosticUnderlineWarn",        { undercurl = true, sp = p.diag_warn })
hl(0, "DiagnosticUnderlineInfo",        { undercurl = true, sp = p.diag_info })
hl(0, "DiagnosticUnderlineHint",        { undercurl = true, sp = p.diag_hint })

hl(0, "DiagnosticVirtualTextError",     { fg = p.diag_error, bg = p.none, italic = true })
hl(0, "DiagnosticVirtualTextWarn",      { fg = p.diag_warn,  bg = p.none, italic = true })
hl(0, "DiagnosticVirtualTextInfo",      { fg = p.diag_info,  bg = p.none, italic = true })
hl(0, "DiagnosticVirtualTextHint",      { fg = p.diag_hint,  bg = p.none, italic = true })

hl(0, "DiagnosticFloatingError",        { fg = p.diag_error, bg = p.bg_float })
hl(0, "DiagnosticFloatingWarn",         { fg = p.diag_warn,  bg = p.bg_float })
hl(0, "DiagnosticFloatingInfo",         { fg = p.diag_info,  bg = p.bg_float })
hl(0, "DiagnosticFloatingHint",         { fg = p.diag_hint,  bg = p.bg_float })

hl(0, "DiagnosticDeprecated",           { strikethrough = true, sp = p.comment })
hl(0, "DiagnosticUnnecessary",          { fg = p.comment })

-- LSP references / inlay
hl(0, "LspReferenceText",   { bg = "#2a313a" })
hl(0, "LspReferenceRead",   { bg = "#2a313a" })
hl(0, "LspReferenceWrite",  { bg = "#2a313a", bold = true })
hl(0, "LspInlayHint",       { fg = p.gold_soft, bg = "#2a2a28", italic = true })
hl(0, "LspSignatureActiveParameter", { fg = p.gold, bold = true })
hl(0, "LspCodeLens",        { fg = p.comment, italic = true })

-- ─── Diff / Git ─────────────────────────────────────────
hl(0, "DiffAdd",            { bg = "#1e2a1e" })
hl(0, "DiffChange",         { bg = "#2a2620" })
hl(0, "DiffDelete",         { bg = "#2a1e1e" })
hl(0, "DiffText",           { bg = "#3a3220", bold = true })

hl(0, "GitSignsAdd",        { fg = p.diag_hint, bg = p.bg })
hl(0, "GitSignsChange",     { fg = p.diag_warn, bg = p.bg })
hl(0, "GitSignsDelete",     { fg = p.diag_error, bg = p.bg })
hl(0, "GitSignsAddNr",      { fg = p.diag_hint })
hl(0, "GitSignsChangeNr",   { fg = p.diag_warn })
hl(0, "GitSignsDeleteNr",   { fg = p.diag_error })
hl(0, "GitSignsAddLn",      { bg = "#1c241c" })
hl(0, "GitSignsChangeLn",   { bg = "#252118" })
hl(0, "GitSignsDeleteLn",   { bg = "#241c1c" })
hl(0, "GitSignsCurrentLineBlame", { fg = p.comment, italic = true })

-- ─── Plugins ────────────────────────────────────────────
-- fzf-lua
hl(0, "FzfLuaNormal",        { fg = p.fg_dim, bg = p.bg_dark })
hl(0, "FzfLuaBorder",        { fg = p.border_strong, bg = p.bg_dark })
hl(0, "FzfLuaTitle",         { fg = p.gold, bg = p.bg_dark, bold = true })
hl(0, "FzfLuaPreviewTitle",  { fg = p.gold, bg = p.bg_dark, bold = true })
hl(0, "FzfLuaPreviewNormal", { fg = p.fg, bg = p.bg })
hl(0, "FzfLuaPreviewBorder", { fg = p.border_strong, bg = p.bg })
hl(0, "FzfLuaHeaderBind",    { fg = p.gold })
hl(0, "FzfLuaHeaderText",    { fg = p.peach })
hl(0, "FzfLuaCursor",        { fg = p.bg, bg = p.gold })
hl(0, "FzfLuaCursorLine",    { bg = p.bg_line })
hl(0, "FzfLuaPathColNr",     { fg = p.diag_info })
hl(0, "FzfLuaPathLineNr",    { fg = p.line_nr_active })
hl(0, "FzfLuaBufNr",         { fg = p.amber })
hl(0, "FzfLuaBufFlagCur",    { fg = p.gold })
hl(0, "FzfLuaBufFlagAlt",    { fg = p.peach })

-- flash.nvim
hl(0, "FlashLabel",          { fg = p.bg, bg = p.gold, bold = true })
hl(0, "FlashMatch",          { fg = p.fg, bg = "#3a3326" })
hl(0, "FlashCurrent",        { fg = p.bg, bg = p.orange, bold = true })
hl(0, "FlashBackdrop",       { fg = p.comment })

-- trouble.nvim
hl(0, "TroubleNormal",       { fg = p.fg_dim, bg = p.bg_dark })
hl(0, "TroubleText",         { fg = p.fg_dim })
hl(0, "TroubleCount",        { fg = p.gold, bg = p.bg_dark, bold = true })
hl(0, "TroubleFile",         { fg = p.fg })
hl(0, "TroubleSource",       { fg = p.comment })
hl(0, "TroubleFoldIcon",     { fg = p.gold })
hl(0, "TroubleLocation",     { fg = p.comment })

-- nvim-dap-ui
hl(0, "DapBreakpoint",                  { fg = p.diag_error })
hl(0, "DapBreakpointCondition",         { fg = p.diag_warn })
hl(0, "DapLogPoint",                    { fg = p.diag_info })
hl(0, "DapStopped",                     { fg = p.gold })
hl(0, "DapStoppedLine",                 { bg = "#3a3326" })
hl(0, "DapUIVariable",                  { fg = p.fg_variable })
hl(0, "DapUIScope",                     { fg = p.gold, bold = true })
hl(0, "DapUIType",                      { fg = p.slate })
hl(0, "DapUIValue",                     { fg = p.amber })
hl(0, "DapUIModifiedValue",             { fg = p.orange, bold = true })
hl(0, "DapUIDecoration",                { fg = p.gold })
hl(0, "DapUIThread",                    { fg = p.diag_hint })
hl(0, "DapUIStoppedThread",             { fg = p.gold })
hl(0, "DapUISource",                    { fg = p.peach })
hl(0, "DapUILineNumber",                { fg = p.line_nr_active })
hl(0, "DapUIFloatBorder",               { fg = p.border_strong })
hl(0, "DapUIWatchesEmpty",              { fg = p.diag_error })
hl(0, "DapUIWatchesValue",              { fg = p.diag_hint })
hl(0, "DapUIWatchesError",              { fg = p.diag_error })
hl(0, "DapUIBreakpointsPath",           { fg = p.peach })
hl(0, "DapUIBreakpointsInfo",           { fg = p.diag_hint })
hl(0, "DapUIBreakpointsCurrentLine",    { fg = p.gold, bold = true })
hl(0, "DapUIBreakpointsLine",           { fg = p.line_nr_active })
hl(0, "DapUIBreakpointsDisabledLine",   { fg = p.comment })
hl(0, "DapUIPlayPause",                 { fg = p.diag_hint })
hl(0, "DapUIRestart",                   { fg = p.diag_hint })
hl(0, "DapUIStop",                      { fg = p.diag_error })
hl(0, "DapUIStepOver",                  { fg = p.link })
hl(0, "DapUIStepInto",                  { fg = p.link })
hl(0, "DapUIStepBack",                  { fg = p.link })
hl(0, "DapUIStepOut",                   { fg = p.link })
hl(0, "DapUIUnavailable",               { fg = p.comment })
hl(0, "NvimDapVirtualText",             { fg = p.gold_soft, italic = true })
