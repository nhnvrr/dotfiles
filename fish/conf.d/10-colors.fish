# Colours by ANSI name, never hex: the sixteen slots in ghostty/config are the
# single source of truth, same rule the fzf block in config.fish follows.

# The 10- prefix is load-bearing: conf.d is sourced sorted by name and this has
# to land after 00-env.fish.

# -g and not -U on purpose. fish resolves local → global → universal, so a
# global here wins over anything fish_config left behind in fish_variables, and
# the repo stays the source of truth instead of that file.

# No --bold anywhere: weight is not one of the sixteen slots, so it is the one
# attribute the profile cannot keep consistent across the stack.

set -g fish_color_normal          normal
set -g fish_color_command         blue
set -g fish_color_keyword         brblue
set -g fish_color_quote           yellow
set -g fish_color_redirection     cyan
set -g fish_color_end             brcyan
set -g fish_color_error           red
set -g fish_color_param           white
set -g fish_color_option          brwhite
set -g fish_color_comment         brblack
set -g fish_color_operator        brcyan
set -g fish_color_escape          magenta
set -g fish_color_autosuggestion  brblack
set -g fish_color_valid_path      --underline
set -g fish_color_selection       --background=brblack
set -g fish_color_search_match    --background=brblack
set -g fish_color_history_current brcyan
set -g fish_color_cancel          brred

# fish_color_cwd, _user and _host are deliberately absent: starship draws the
# prompt and fish never reads them.

set -g fish_pager_color_progress            brblack
set -g fish_pager_color_prefix              cyan
set -g fish_pager_color_completion          white
set -g fish_pager_color_description         brblack
set -g fish_pager_color_selected_background --background=brblack
