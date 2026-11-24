function pgcli --wraps pgcli --description 'pgcli with the Mate config for the current terminal mode'
    set -l rc
    if string match -q '*mate-light*' -- (cat $HOME/.config/ghostty/mode.local 2>/dev/null)
        set rc --pgclirc $HOME/.config/pgcli/config-light
    end
    command pgcli $rc $argv
end
