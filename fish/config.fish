# ─── Locale & editor ────────────────────────────────────
# Solo LANG: LC_ALL pisa TODAS las categorías LC_* de golpe y no deja
# override puntual (ej. LC_TIME distinto). LANG es el fallback de todas.
set -gx LANG en_US.UTF-8
set -gx EDITOR nvim
set -gx VISUAL nvim

# Sin banner de bienvenida al abrir una shell.
set -g fish_greeting

# ─── PATH ───────────────────────────────────────────────
# fish_add_path -g: modifica $PATH global de la sesión en vez de escribir la
# variable universal $fish_user_paths. config.fish corre en cada shell, así que
# el repo queda como única fuente de verdad (sin estado universal que derive).
# Los paths se prependan en el orden dado: el primero queda primero.
set -gx GOPATH $HOME/Develop/go
set -gx GOPRIVATE github.com/nhnvrr
fish_add_path -g $GOPATH/bin /opt/homebrew/bin /opt/homebrew/sbin \
    /opt/homebrew/opt/libpq/bin /usr/local/bin $HOME/.local/bin

# ─── Aliases ────────────────────────────────────────────
# Solo lo que el historial muestra en uso. `ll`/`la`/`cl` se borraron: 1 uso
# cada uno contra 13 de `ls` y 12 de `clear` — el alias perdió contra el
# comando real, así que era ruido.
# El editor es Zed. `-n` abre ventana nueva en vez de reusar la actual, igual
# que el `--new-window` que tenía el alias de VS Code.
alias e 'zed -n'
# VS Code sigue instalado como respaldo para el laburo de EC2 (AWS Toolkit + SSM).
alias code 'code --new-window'

# ─── Git abbreviations ──────────────────────────────────
# abbr expande en pantalla al apretar espacio: ves el comando real antes de
# ejecutarlo, y queda expandido en el historial. Es lo que zsh no tenía.
# Ojo al medir uso: como se expanden, en el historial figura la forma larga.
# Estas cinco son las que tienen tracción real (usos sobre 1222 comandos);
# gst/gp/gl/gca/gcan tenían 0 y se fueron.
abbr -a gc 'git commit -m' # 134
abbr -a gco 'git checkout' # 89
abbr -a ga 'git add' # 27
abbr -a gb 'git branch' # 10
abbr -a gd 'git diff' # 3

# ─── HTTP: curl para trabajo de API ─────────────────────
# A propósito NO hay ~/.curlrc: ese archivo lo lee TODA invocación de curl,
# incluida la del instalador de Homebrew en install.sh y la de cualquier script
# de terceros. Meter --silent o --location ahí cambiaría el comportamiento de
# cosas que hoy funcionan. Los flags viven acá, aplicados solo si los pedís.
#
#   --show-error   errores visibles aunque --silent apague la barra de progreso
#   --location     seguir redirects
#   --compressed   aceptar gzip
#   --globoff      que [] y {} en la URL no se interpreten como globs
#   timeouts       para que no cuelgue una terminal esperando para siempre
#
# Los argumentos se pasan tal cual, así que -i, -X POST, -d, -H funcionan.
function req --description 'curl con flags sanos; formatea la respuesta si es JSON'
    set -l out (curl --silent --show-error --location --compressed \
        --connect-timeout 10 --max-time 60 --globoff $argv | string collect)
    set -l code $pipestatus[1]
    test $code -ne 0; and return $code

    # jq solo si la respuesta parsea como JSON; si no, sale tal cual.
    if command -q jq; and printf '%s' $out | jq -e . >/dev/null 2>&1
        printf '%s' $out | jq .
    else
        printf '%s\n' $out
    end
end

# ─── tmux: abrir o crear una sesión con nombre ──────────
function __tx --argument-names name --description 'Attach/create una sesión tmux fija'
    set -l dir
    switch $name
        case dev
            set dir $HOME/develop
        case work
            set dir $HOME/work
        case side
            set dir $HOME/side
        case '*'
            echo "__tx: unknown session '$name'" >&2
            return 1
    end

    tmux has-session -t=$name 2>/dev/null
    or tmux new-session -d -s $name -c $dir

    if test -z "$TMUX"
        tmux attach-session -t $name
    else
        tmux switch-client -t $name
    end
end

alias dev '__tx dev'
alias work '__tx work'
alias side '__tx side'

# ─── Claude Code: cuenta por sesión tmux ────────────────
# CLAUDE_CONFIG_DIR es env var oficial (verificado en el binario): cada proceso
# claude lee/escribe en SU dir. Cero estado global mutable, cero traps.
# Bootstrap (1 vez): CLAUDE_CONFIG_DIR=~/.claude-work claude → /login con la cuenta.
function claude --description 'Claude Code con config según la sesión tmux'
    set -l session (tmux display-message -p '#S' 2>/dev/null)
    set -lx CLAUDE_CONFIG_DIR $HOME/.claude
    test "$session" = work; and set -lx CLAUDE_CONFIG_DIR $HOME/.claude-work
    command claude $argv
end

# ─── mise (tool/runtime version manager) ────────────────
if command -q mise
    mise activate fish | source
end

# ─── AWS CLI completion ─────────────────────────────────
if command -q aws_completer
    complete -c aws -f -a "(env COMP_LINE=(commandline -pc) aws_completer | sed 's/ \$//')"
end

# ─── Docker Desktop completion ──────────────────────────
set -l docker_completion /Applications/Docker.app/Contents/Resources/etc/docker.fish-completion
test -f $docker_completion; and source $docker_completion

# ─── Tide prompt ────────────────────────────────────────
# Tide guarda su config en variables universales (set -U), que no son
# versionables. install.sh siembra la base con `tide configure --auto`; acá
# fijamos lo que nos importa con `set -g`, que sombrea al universal en el
# scoping de fish → el repo manda. Los hex van sin '#' (formato de set_color).
# Los nombres de item son los de `_tide_item_*` (ojo: es `rustc`, no `rust`).
# Cada uno solo se muestra si el proyecto lo amerita.
set -g tide_left_prompt_items os pwd git newline character
set -g tide_right_prompt_items status cmd_duration context jobs node bun go rustc python terraform aws docker time
set -g tide_prompt_add_newline_before true
set -g tide_prompt_transient_enabled true
set -g tide_cmd_duration_threshold 2000
set -g tide_time_format '%H:%M'

# Iconos. Igual que los colores, vivían solo en variables universales, o sea
# fuera del repo. Van solo los de los items que están en el prompt.
#
# Se definen por CODEPOINT y no pegando el glyph: los de Nerd Font viven en la
# zona de uso privado (U+E000-F8FF y U+F0000+) y se pierden al copiarlos entre
# editores, terminales o herramientas — quedan como string vacío sin avisar.
# Así el fuente es legible y sobrevive cualquier copy/paste.
# Catálogo: nerdfonts.com/cheat-sheet
# Para averiguar el codepoint de un glyph: printf '%s' 'X' | xxd
set -g tide_git_icon (printf '\U0000F126') # nf-fa-code_branch
set -g tide_os_icon (printf '\U0000F179') # apple
set -g tide_pwd_icon (printf '\U0000F07C') # carpeta
set -g tide_cmd_duration_icon (printf '\U0000F252') # reloj de arena
set -g tide_jobs_icon (printf '\U0000F013') # engranaje
set -g tide_node_icon (printf '\U0000E24F')
set -g tide_bun_icon (printf '\U000F0CD3')
set -g tide_go_icon (printf '\U0000E627')
set -g tide_rustc_icon (printf '\U0000E7A8')
set -g tide_python_icon (printf '\U000F0320')
set -g tide_terraform_icon (printf '\U000F1062')
set -g tide_aws_icon (printf '\U0000E7AD') # nf-dev-aws
set -g tide_docker_icon (printf '\U0000F308')

# El character no es Nerd Font sino Unicode común, y cambia según el modo vi
# (usás fish_hybrid_key_bindings): ❯ insert, ❮ normal, ▶ replace, V visual.
set -g tide_character_icon '❯'
set -g tide_character_vi_icon_default '❮'
set -g tide_character_vi_icon_replace '▶'
set -g tide_character_vi_icon_visual 'V'

# Nord: frost para paths, aurora para estado git.
# Nota sobre el gris apagado: nord3 (#4C566A) daba 1.7:1 de contraste sobre el
# viejo fondo #2E3440 y 2.2:1 sobre el #212121 de Nord Wave — ilegible en ambos.
# Se usa #616E88 (el "comment" de Nord) que llega a 3.1:1, el mínimo para texto
# no-cuerpo. Sigue leyéndose como secundario pero se lee.
set -l nord_muted 616E88

set -g tide_pwd_color_dirs 81A1C1 # nord9  frost
set -g tide_pwd_color_anchors 88C0D0 # nord8  frost
set -g tide_pwd_color_truncated_dirs $nord_muted
set -g tide_git_color_branch A3BE8C # nord14 green
set -g tide_git_color_dirty EBCB8B # nord13 yellow
set -g tide_git_color_untracked B48EAD # nord15 purple
set -g tide_git_color_conflicted BF616A # nord11 red
set -g tide_git_color_staged A3BE8C
set -g tide_git_color_upstream 88C0D0
# Rebase/merge/cherry-pick en curso y stash pendiente: sin esto quedaban en los
# defaults 256-color de `tide configure --auto` (#FF0000 y #5FD700), los dos
# únicos colores crudos que seguían apareciendo en el prompt.
set -g tide_git_color_operation D08770 # nord12 orange → operación en curso
set -g tide_git_color_stash 8FBCBB # nord7  frost  → hay stash
set -g tide_character_color A3BE8C
set -g tide_character_color_failure BF616A
set -g tide_cmd_duration_color 88C0D0
set -g tide_status_color A3BE8C
set -g tide_status_color_failure BF616A
set -g tide_context_color_default $nord_muted
set -g tide_context_color_ssh D08770 # nord12 orange
set -g tide_context_color_root BF616A # nord11 red → root, mismo peso que un error
set -g tide_jobs_color 81A1C1
set -g tide_aws_color EBCB8B
set -g tide_node_color A3BE8C
set -g tide_bun_color E5E9F0
set -g tide_go_color 88C0D0
set -g tide_rustc_color BF616A
set -g tide_python_color EBCB8B
set -g tide_terraform_color B48EAD
set -g tide_docker_color 88C0D0
set -g tide_time_color $nord_muted

# Cromo del prompt (no son items, se pintan aparte): el relleno entre prompt
# izquierdo y derecho, y el separador entre items adyacentes del mismo color.
set -g tide_prompt_color_frame_and_connection 434C5E # nord2
set -g tide_prompt_color_separator_same_color $nord_muted

# El contexto de docker solo interesa cuando NO es el local: sin esto, el
# prompt muestra "desktop-linux" permanentemente.
set -g tide_docker_default_contexts default desktop-linux

# ─── Bell en comandos largos (>10s) ─────────────────────
# Solo bell → status bar naranja de tmux + Dock. Sin notificación macOS
# (osascript resultaba ruidoso). $CMD_DURATION lo da fish gratis, en ms.
set -g _notify_threshold 10000
set -g _notify_ignore nvim less man ssh tmux claude fzf watch top tail dev work side

function _notify_long_command --on-event fish_postexec --description 'Bell tras un comando largo'
    test -n "$argv[1]"; or return
    set -l cmd (string split -f1 ' ' -- (string trim -- $argv[1]))
    contains -- $cmd $_notify_ignore; and return
    test $CMD_DURATION -ge $_notify_threshold; and printf '\a'
end

# ─── Key bindings ───────────────────────────────────────
# Hybrid: defaults emacs (Ctrl+A/E/W/U/K/R, Alt+B/F) + vi mode apretando Esc.
# Sin perder muscle memory, ganás navegación vi sobre comandos largos.
# fish llama a fish_user_key_bindings después del binding function, así que
# nuestros binds sobreviven a los defaults. Se bindea en insert y default para
# que funcionen de los dos lados del hybrid.
function fish_user_key_bindings
    for mode in insert default
        # Ctrl-P/Ctrl-N: búsqueda de historial por prefijo (escribís "git ",
        # Ctrl-P trae solo comandos que empiezan con "git ").
        # Ojo: esto le saca a Ctrl-N el accept-autosuggestion que fish trae por
        # default. La autosugerencia se sigue aceptando con → o Ctrl-F.
        bind -M $mode ctrl-p up-or-search
        bind -M $mode ctrl-n down-or-search
        # Ctrl-O: editar la línea actual en $EDITOR (nvim).
        bind -M $mode ctrl-o edit_command_buffer
    end
end
set -g fish_key_bindings fish_hybrid_key_bindings

# Cursor: beam parpadeante en TODOS los modos vi.
# Con bindings vi (o hybrid) fish maneja el cursor él mismo vía fish_vi_cursor,
# y su default en modo normal es `block` — eso es lo que pisaba el beam que
# configuran Ghostty y tmux, y por qué el cursor quedaba cuadrado al apretar Esc.
# `line`+`blink` emite \e[5 q, el mismo escape que pide tmux con blinking-bar.
# El modo se sigue distinguiendo por el caracter del prompt: ❯ insert, ❮ normal.
for _m in default insert replace replace_one visual external unknown
    set -g fish_cursor_$_m line blink
end
set -e _m

# ─── Interactive-only setup ─────────────────────────────
if status is-interactive
    # Let Ctrl-S/Ctrl-Q reach the shell instead of being eaten by the terminal.
    stty -ixon 2>/dev/null

    # AWS_PROFILE siempre explícito, según la sesión tmux.
    # Antes solo se seteaba en la sesión "work" y en el resto quedaba vacío:
    # como ~/.aws/config no tiene un perfil [default], todo comando aws fuera
    # de esa sesión fallaba con NoCredentials hasta exportarlo a mano.
    # Además el item `aws` de Tide solo se dibuja cuando la variable existe,
    # así que tenerla siempre puesta = ver siempre contra qué cuenta estás.
    # Solo interactivo: subshells y scripts no lo heredan sin querer.
    if test -n "$TMUX"; and test (tmux display-message -p '#S' 2>/dev/null) = work
        set -gx AWS_PROFILE work
    else
        set -gx AWS_PROFILE personal
    end

    # ─── fzf: Ctrl-R history, Ctrl-T files, Alt-C dirs ────
    if command -q fzf
        # bat: usar la paleta ANSI del terminal en vez del theme propio de bat
        # → el preview de fzf matchea el resto y sigue al tema del terminal.
        set -gx BAT_THEME ansi

        # fd respeta .gitignore, ignora hidden por default, más rápido que find.
        set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
        set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
        set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

        # Layout: pane abajo, reversa (input arriba), 40% height, borde sutil.
        # --bind: Ctrl-/ togglea preview, Ctrl-y copia la selección al clipboard.
        # Colores sobre el fondo #212121 de Nord Wave:
        #   bg+ (fila seleccionada) #3B4252 daba 1.60:1 — casi invisible.
        #     Con #4C566A queda en 2.18:1 y la selección se distingue.
        #   info/border #4C566A daban 2.18:1 → #616E88 los lleva a 3.14:1,
        #     el mismo gris que usa el prompt Tide.
        set -gx FZF_DEFAULT_OPTS '
          --height 40% --layout=reverse --border=rounded
          --bind="ctrl-/:toggle-preview,ctrl-y:execute-silent(echo {} | pbcopy)+abort"
          --color=bg+:#4C566A,fg:#D8DEE9,fg+:#ECEFF4,hl:#88C0D0,hl+:#8FBCBB,info:#616E88,prompt:#81A1C1,pointer:#BF616A,marker:#A3BE8C,border:#616E88,header:#81A1C1,spinner:#8FBCBB'

        # Preview con bat para Ctrl-T y completion de archivos.
        set -gx FZF_CTRL_T_OPTS "--preview 'bat --style=numbers --color=always --line-range :200 {}'"
        # Preview con ls para Alt-C (cd a subdir).
        set -gx FZF_ALT_C_OPTS "--preview 'ls -la {} | head -100'"
        # Ctrl-R: ver el comando completo cuando es multilínea.
        set -gx FZF_CTRL_R_OPTS '--preview "echo {}" --preview-window=down:3:wrap'

        fzf --fish | source
    end
end
