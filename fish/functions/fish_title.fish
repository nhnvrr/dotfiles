function fish_title --description 'window title: the mate, then the command or the directory'
    # $argv[1] is the running command; empty at the prompt.
    if test -n "$argv[1]"
        echo -n "🧉 $argv[1]"
    else
        echo -n "🧉 "(prompt_pwd --full-length-dirs=1)
    end
end
