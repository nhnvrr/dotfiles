function envinfo --description 'Shell, git, toolchain, AWS and docker context, on demand'
    function _env_row
        printf '  %s%-9s%s %s\n' (set_color blue) $argv[1] (set_color normal) "$argv[2]"
    end

    _env_row shell "fish $FISH_VERSION   "(set_color brblack)"editor $EDITOR"(set_color normal)
    _env_row dir (prompt_pwd --full-length-dirs=99)

    set -l git (fish_git_prompt '%s')
    test -n "$git"; and _env_row git $git

    if command -q mise
        set -l tools
        mise ls --current 2>/dev/null | while read -l name ver rest
            set -a tools (set_color white)$name(set_color normal)" $ver"
        end
        for i in (seq 1 3 (math max 1, (count $tools)))
            set -l label
            test $i -eq 1; and set label mise
            _env_row "$label" (string join '   ' $tools[$i..(math $i + 2)])
        end
    end

    set -l region (set -q AWS_REGION; and echo $AWS_REGION; or echo -)
    _env_row aws "$AWS_PROFILE   "(set_color brblack)"region $region"(set_color normal)
    # Behind the flag on purpose: this one goes over the network.
    if test "$argv[1]" = -a; and command -q aws
        _env_row '' (aws sts get-caller-identity --query Arn --output text 2>&1)
    end

    if command -q docker
        set -l dctx (docker context show 2>/dev/null)
        test -n "$dctx"; and _env_row docker $dctx
    end

    _env_row term "$TERM_PROGRAM   "(set_color brblack)"TERM=$TERM"(set_color normal)

    functions -e _env_row
end
