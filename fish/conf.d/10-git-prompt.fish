# fish_git_prompt shows only the branch until told otherwise.
# ANSI names, not hex: alacritty/mate.toml's sixteen slots are the single source.
# Plain ASCII state markers: no patched font needed, so ssh and Terminal.app
# show the same prompt.
set -g __fish_git_prompt_showdirtystate yes
set -g __fish_git_prompt_showuntrackedfiles yes
set -g __fish_git_prompt_showstashstate yes
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_stateseparator ' '
set -g __fish_git_prompt_char_dirtystate '*'
set -g __fish_git_prompt_char_stagedstate '+'
set -g __fish_git_prompt_char_untrackedfiles '?'
set -g __fish_git_prompt_char_stashstate '$'
set -g __fish_git_prompt_char_invalidstate '!'
set -g __fish_git_prompt_char_upstream_ahead ⇡
set -g __fish_git_prompt_char_upstream_behind ⇣
set -g __fish_git_prompt_color_branch green
set -g __fish_git_prompt_color_dirtystate yellow
set -g __fish_git_prompt_color_stagedstate green
set -g __fish_git_prompt_color_untrackedfiles cyan
set -g __fish_git_prompt_color_stashstate yellow
set -g __fish_git_prompt_color_invalidstate red
set -g __fish_git_prompt_color_upstream white

# Worktree branches run to 50+ chars (bug/sc-10957-propagate-on-conflict-…)
# and push the chevron off the edge. 15 keeps `bug/sc-NNNNN`, the part that
# identifies the work; string shorten appends … when it cuts.
set -g __fish_git_prompt_shorten_branch_len 15
