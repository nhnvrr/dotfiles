function _fzf_complete --description 'Tab: fish completions picked in fzf, with descriptions and a preview'
    set -l token (commandline -ct)
    set -l candidates (complete -C -- (commandline -cp))
    switch (count $candidates)
        case 0
            return
        case 1
            set -f pick $candidates
        case '*'
            # A shared prefix longer than the token is inserted first, like plain tab.
            set -l names (string replace -r '\t.*' '' -- $candidates)
            set -l prefix (_fzf_common_prefix $names)
            if test (string length -- "$prefix") -gt (string length -- "$token")
                commandline -rt -- (_fzf_escape $prefix)
                return
            end
            set -f pick (printf '%s\n' $candidates | fzf --delimiter='\t' --nth=1 --tabstop=40 \
                --query="$token" --select-1 --exit-0 --multi --bind=tab:down,btab:up,ctrl-space:toggle \
                --preview='set -l f (string replace -r "^~" $HOME -- {1}); if test -d $f; ls -1 $f; else if test -f $f; bat --style=numbers --color=always --line-range :200 $f; else; echo {2..}; end' \
                --preview-window='right,50%,<80(hidden)' | string replace -r '\t.*' '')
            or begin
                commandline -f repaint
                return
            end
    end
    set pick (string replace -r '\t.*' '' -- $pick)
    set -l out
    for p in $pick
        set -a out (_fzf_escape $p)
    end
    set -l line (string join ' ' -- $out)
    # Directories and key= stay open for the next segment.
    if test (count $pick) -eq 1; and string match -qr '[/=]$' -- $pick
        commandline -rt -- $line
    else
        commandline -rt -- "$line "
    end
    commandline -f repaint
end

function _fzf_escape -a s
    # Keep a leading ~ expandable; escape everything else.
    if string match -q '~*' -- $s
        set -l rest (string sub -s 2 -- $s)
        echo -n '~'(string escape --no-quoted -- $rest)
    else
        string escape --no-quoted -- $s
    end
end

function _fzf_common_prefix
    set -l prefix $argv[1]
    for s in $argv[2..]
        while not string match -q -- "$prefix*" $s
            set prefix (string sub -e -1 -- $prefix)
            test -z "$prefix"; and return
        end
    end
    echo -n $prefix
end
