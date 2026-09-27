" ANSI slots only, so the hex values stay in ghostty/themes. Slots 4 and 8
" swap roles between the two palettes (grey text vs surface), hence the split.

hi clear
if exists('syntax_on')
  syntax reset
endif
let g:colors_name = 'mate'

let s:dim  = &background ==# 'dark' ? 4 : 8
let s:surf = &background ==# 'dark' ? 8 : 0

function! s:hi(group, fg, bg, attr) abort
  exe 'hi' a:group 'ctermfg=' . a:fg 'ctermbg=' . a:bg 'cterm=' . a:attr
endfunction

call s:hi('Normal', 15, 'NONE', 'NONE')
call s:hi('Comment', s:dim, 'NONE', 'italic')
call s:hi('String', 2, 'NONE', 'NONE')
call s:hi('Constant', 6, 'NONE', 'NONE')
call s:hi('Special', 6, 'NONE', 'NONE')
call s:hi('Statement', 'NONE', 'NONE', 'bold')
call s:hi('Type', 3, 'NONE', 'NONE')
call s:hi('PreProc', 5, 'NONE', 'NONE')
call s:hi('Identifier', 'NONE', 'NONE', 'NONE')
call s:hi('Function', 'NONE', 'NONE', 'NONE')
call s:hi('Todo', 3, 'NONE', 'bold')
call s:hi('Error', 9, 'NONE', 'bold')
call s:hi('Underlined', 'NONE', 'NONE', 'underline')

call s:hi('LineNr', s:dim, 'NONE', 'NONE')
call s:hi('CursorLineNr', 'NONE', 'NONE', 'bold')
call s:hi('CursorLine', 'NONE', 'NONE', 'NONE')
call s:hi('SignColumn', 'NONE', 'NONE', 'NONE')
call s:hi('NonText', s:dim, 'NONE', 'NONE')
call s:hi('SpecialKey', s:dim, 'NONE', 'NONE')
call s:hi('Folded', s:dim, 'NONE', 'NONE')
call s:hi('VertSplit', s:surf, 'NONE', 'NONE')
call s:hi('StatusLine', 'NONE', s:surf, 'NONE')
call s:hi('StatusLineNC', s:dim, s:surf, 'NONE')
call s:hi('Visual', 'NONE', 'NONE', 'reverse')
call s:hi('Search', 0, 3, 'NONE')
call s:hi('IncSearch', 0, 1, 'NONE')
call s:hi('CurSearch', 0, 1, 'NONE')
call s:hi('MatchParen', 'NONE', 'NONE', 'bold,underline')
call s:hi('Pmenu', 'NONE', s:surf, 'NONE')
call s:hi('PmenuSel', 0, 1, 'NONE')
call s:hi('PmenuSbar', 'NONE', s:surf, 'NONE')
call s:hi('PmenuThumb', 'NONE', s:dim, 'NONE')
call s:hi('WildMenu', 0, 1, 'NONE')
call s:hi('Directory', 6, 'NONE', 'NONE')
call s:hi('Title', 'NONE', 'NONE', 'bold')
call s:hi('ErrorMsg', 9, 'NONE', 'bold')
call s:hi('WarningMsg', 3, 'NONE', 'NONE')
call s:hi('MoreMsg', 2, 'NONE', 'NONE')
call s:hi('Question', 2, 'NONE', 'NONE')
call s:hi('DiffAdd', 2, 'NONE', 'NONE')
call s:hi('DiffDelete', 9, 'NONE', 'NONE')
call s:hi('DiffChange', 3, 'NONE', 'NONE')
call s:hi('DiffText', 3, 'NONE', 'bold')

call s:hi('LspDiagSignErrorText', 9, 'NONE', 'NONE')
call s:hi('LspDiagSignWarningText', 3, 'NONE', 'NONE')
call s:hi('LspDiagSignInfoText', 6, 'NONE', 'NONE')
call s:hi('LspDiagSignHintText', 6, 'NONE', 'NONE')
