# fish_git_prompt shows only the branch until told otherwise.
# ANSI names, not hex: ghostty/config's sixteen slots are the single source.
# State glyphs follow the starship convention (! modified, + staged, ? untracked)
# as nf-fa-* Nerd Font icons; they need a patched face.
set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_showuntrackedfiles yes
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_stateseparator ' '
set -g __fish_git_prompt_char_dirtystate \uf12a
set -g __fish_git_prompt_char_stagedstate \uf067
set -g __fish_git_prompt_char_untrackedfiles \uf128
set -g __fish_git_prompt_char_stashstate \uf01c
set -g __fish_git_prompt_char_invalidstate \uf071
set -g __fish_git_prompt_char_upstream_ahead ⇡
set -g __fish_git_prompt_char_upstream_behind ⇣
set -g __fish_git_prompt_color_branch green
set -g __fish_git_prompt_color_dirtystate yellow
set -g __fish_git_prompt_color_stagedstate green
set -g __fish_git_prompt_color_untrackedfiles cyan
set -g __fish_git_prompt_color_stashstate yellow
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_upstream white
