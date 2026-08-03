# Shadows the aws.fish that fish 4 compiles into the binary: fish autoloads
# only the first match in $fish_complete_path, and ~/.config/fish/completions
# comes first. Registering the completer from config.fish instead would merge
# with that table and keep offering services awscli dropped years ago. The s3
# helpers below are ported from that same table — aws_completer has no notion
# of s3:// URIs and shadowing it would otherwise lose them.
command -q aws_completer; or exit

function __aws_completer_query --argument-names line
    # aws_completer prints a bare newline when it has nothing, which fish reads
    # as one empty candidate — without the filter the callers never fall back.
    env COMP_LINE=$line COMP_POINT=(string length -- $line) aws_completer \
        | string trim | string match -rv '^$'
end

function __aws_complete_s3 --argument-names token
    if string match -qr '^s3:/?/?[^/]*$' -- $token
        aws s3 ls 2>/dev/null | string replace -rf '.* (\S+)$' 's3://$1/'
    else if string match -qr '^s3://.+/' -- $token
        set -l dir (string replace -rf '(s3://.*/).*' '$1' -- $token)
        printf "$dir%s\n" (aws s3 ls $dir 2>/dev/null \
            | string replace -rf '^(\S+ +\S+ +\S+ |.*PRE )(.*)' '$2')
    end
end

function __aws_completer_complete
    set -l line (commandline --current-process --cut-at-cursor)
    set -l token (commandline --current-token)

    # aws_completer follows bash's COMP_WORDBREAKS and never sees the --opt=
    # prefix, so ask it the spaced form and put the prefix back.
    if set -l kv (string match -r '^(--[\w-]+)=(.*)$' -- $token)
        set -l vals (__aws_completer_query "aws $kv[2] $kv[3]")
        and printf "$kv[2]=%s\n" $vals
        return
    end

    set -l out (__aws_completer_query $line)
    if set -q out[1]
        string join \n -- $out
    else if string match -q 's3:*' -- $token
        __aws_complete_s3 $token
    else if not string match -q -- '-*' $token
        # It stays quiet on path arguments expecting the shell to take over,
        # and --no-files stops that: `aws s3 cp ./`, `--cli-input-json file://`.
        # A dash means an option it failed to parse, never a file — on the
        # current token, or on the previous one when this is a fresh word
        # (`--instance-ids ` wants ids, not the cwd).
        set -l prev (commandline --current-process --cut-at-cursor --tokenize)
        test -n "$token"; or not string match -q -- '-*' $prev[-1]
        and __fish_complete_path $token
    end
end

# -k: aws_completer emits its own order — `aws s3 ls --` starts at --recursive,
# not at --dryrun — and fish would re-sort it alphabetically.
complete -c aws -f -k -a '(__aws_completer_complete)'
