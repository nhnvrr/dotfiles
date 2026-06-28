# Nord — status bar (dark) con verde Aurora (#a3be8c) y separadores powerline.
# Verde enmarca la barra: bloque de sesión a la izquierda + bloque de hora a la
# derecha; la ventana activa se distingue con un bloque tenue y texto verde.
set -g status-style "fg=#d8dee9,bg=#3b4252"

# Sesión: bloque verde sólido + flecha powerline () hacia la barra.
set -g status-left "#[fg=#2e3440,bg=#a3be8c,bold] #S #[fg=#a3be8c,bg=#3b4252,nobold] "

# Ventanas: inactivas planas y apagadas; activa en bloque tenue con texto verde.
setw -g window-status-format "#[fg=#81848f,bg=#3b4252] #I:#W "
setw -g window-status-current-format "#[fg=#3b4252,bg=#434c5e]#[fg=#a3be8c,bg=#434c5e,bold] #I:#W #[fg=#434c5e,bg=#3b4252]"
setw -g window-status-separator ""

# Derecha: host azul frost, fecha gris, hora en bloque verde con flecha de entrada ().
set -g status-right "#[fg=#81a1c1] #H  #[fg=#616e88]%d/%m/%y #[fg=#a3be8c,bg=#3b4252]#[fg=#2e3440,bg=#a3be8c,bold] %H:%M "
