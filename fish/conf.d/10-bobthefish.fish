set -l dir $HOME/.local/share/fish/bobthefish/functions
test -d $dir; or exit
set -a fish_function_path $dir

set -g theme_color_scheme terminal
set -g theme_nerd_fonts yes
set -g theme_display_date yes
set -g theme_date_format "+%a %b %d %H:%M:%S %z"
set -g theme_display_user no
set -g theme_display_hostname no
set -g theme_display_vi no
set -g theme_display_cmd_duration no
set -g theme_display_git_untracked no
set -g theme_display_git_dirty_verbose no
set -g theme_display_git_ahead_verbose no
set -g theme_display_git_stashed_verbose no
set -g theme_display_go no
set -g theme_display_node no
set -g theme_display_ruby no
set -g theme_display_virtualenv no
set -g theme_display_k8s_context no
set -g theme_display_docker_machine no
set -g theme_display_nix no
set -g theme_newline_cursor no
