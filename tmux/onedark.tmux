# OneDark — status bar flat, sin fondo propio: usa el fondo (transparente) del
# terminal. Acentos por color de texto en vez de bloques sólidos → look limpio
# que aprovecha la opacity/blur de Alacritty.
set -g status-style "fg=#abb2bf,bg=default"
set -g status-left "#[fg=#1b1d23,bg=#98c379,bold] #S #[default] "
setw -g window-status-format "#[fg=#5c6370] #I:#W "
setw -g window-status-current-format "#[fg=#98c379,bold] #I:#W "
setw -g window-status-separator ""
set -g status-right "#[fg=#61afef]#H  #[fg=#5c6370]%d/%m/%y  #[fg=#98c379,bold]%H:%M "
set -g pane-border-lines "double"
set -g pane-border-style "fg=#3e4452"
set -g pane-active-border-style "fg=#98c379"
set -g window-active-style "fg=#abb2bf,bg=default"
set -g window-style "fg=#5c6370,bg=default"
