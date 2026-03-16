# Fish completion bridge for AWS CLI's bundled completer.
function __fish_aws_complete
    command -q aws_completer; or return

    set -l line (commandline -cp)
    set -l point (string length -- "$line")

    env COMP_LINE="$line" COMP_POINT="$point" aws_completer 2>/dev/null
end

complete -c aws -f -a '(__fish_aws_complete)'
