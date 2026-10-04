function mate --description 'Switch the terminal between dark and light: mate [dark|light]'
    # Terminal only: macOS appearance is left alone. Ghostty reloads on SIGUSR2.
    set file ~/.config/ghostty/mode.local
    switch "$argv[1]"
        case ''
            if string match -q '*mate-light*' (cat $file 2>/dev/null)
                set mode dark
            else
                set mode light
            end
        case dark light
            set mode $argv[1]
        case '*'
            echo 'mate: [dark|light]   — no argument toggles' >&2
            return 2
    end
    echo "theme = mate-$mode" >$file
    pkill -USR2 -x ghostty
end
