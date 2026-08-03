# Shadows the aws.fish that fish 4 compiles into the binary: fish autoloads
# only the first match in $fish_complete_path, and ~/.config/fish/completions
# comes first. Registering the completer from config.fish instead would merge
# with that table and keep offering services awscli dropped years ago.
command -q aws_completer; or exit

function __aws_completer_complete
    set -l line (commandline --current-process --cut-at-cursor)
    # aws_completer prints a bare newline when it has nothing, which fish reads
    # as one empty candidate — without the filter the fallback below never runs.
    set -l out (env COMP_LINE=$line COMP_POINT=(string length -- $line) aws_completer \
        | string trim | string match -rv '^$')

    if set -q out[1]
        string join \n -- $out
    else
        # It stays quiet on path arguments expecting the shell to take over,
        # and --no-files stops that: `aws s3 cp ./`, `--cli-input-json file://`.
        __fish_complete_path (commandline --current-token)
    end
end

# -k: aws_completer emits its own order — `aws s3 ls --` starts at --recursive,
# not at --dryrun — and fish would re-sort it alphabetically.
complete -c aws -f -k -a '(__aws_completer_complete)'
