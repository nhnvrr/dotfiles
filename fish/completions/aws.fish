# Shadows the aws.fish that fish 4 compiles into the binary: fish autoloads
# only the first match in $fish_complete_path, and ~/.config/fish/completions
# comes first. Registering the completer from config.fish instead would merge
# with that table and keep offering services awscli dropped years ago. The s3
# helpers below are ported from that same table — aws_completer has no notion
# of s3:// URIs and shadowing it would otherwise lose them.
command -q aws_completer; or exit

# aws_completer only ever emits bare names. The descriptions are read out of the
# botocore models that ship inside the awscli bundle.
set -g __aws_models (path dirname (path resolve (command -v aws)))/awscli/botocore/data
set -g __aws_cache $HOME/.cache/fish/aws-completions

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

# Joins bare candidates on stdin against a name<TAB>description table. The key
# drops dashes and case instead of deriving the command name from the model:
# botocore's own xform_name turns ListHITs into list-hi-ts, which is not the
# list-hits the CLI takes.
function __aws_join --argument-names table
    # No table means jq failed or the model has no operations. awk would abort
    # on the missing file and swallow the candidates with it.
    if not test -s $table
        cat
        return
    end
    awk -F\t 'NR == FNR { d[$1] = $2; next }
        { k = tolower($1); gsub(/-/, "", k)
          print (k in d && d[k] != "") ? $1 "\t" d[k] : $1 }' $table -
end

# Both tables are cached because jq is far too slow for a keypress: ~1s over the
# 423 service models, and ~600ms for a single big one (ec2 alone is 3.9MB). An
# awscli upgrade lands a whole new tree, so the model directory's mtime is what
# says a cached table is stale. Cost lands on the first tab per service.
function __aws_stale --argument-names f
    not test -f $f -a $f -nt $__aws_models
end

function __aws_service_table
    set -l f $__aws_cache/services.tsv
    if __aws_stale $f
        mkdir -p $__aws_cache
        jq -r 'input_filename as $f
            | (($f | split("/"))[-3] | ascii_downcase | gsub("-"; ""))
              + "\t" + (.metadata.serviceFullName // .metadata.serviceId // "")' \
            $__aws_models/*/*/service-2.json >$f 2>/dev/null
    end
    echo $f
end

function __aws_operation_table --argument-names svc
    set -l f $__aws_cache/$svc.tsv
    if not __aws_stale $f
        echo $f
        return
    end
    mkdir -p $__aws_cache
    jq -r 'def clean:
            (. // "")
          # the docs open with a support notice often enough that the first
          # sentence is the banner, not the summary
          | gsub("<(important|note)>.*?</(important|note)>"; " ")
          | gsub("<[^>]*>"; " ")
          | gsub("&lt;"; "<") | gsub("&gt;"; ">") | gsub("&quot;"; "\"")
          | gsub("&#39;"; "\'") | gsub("&amp;"; "&")
          # POSIX classes, not \s: fish collapses \\ inside single quotes, so a
          # backslash class would reach jq as an invalid string escape.
          | gsub("[[:space:]]+"; " ") | ltrimstr(" ") | rtrimstr(" ")
          | (capture("^(?<s>.*?[.])([[:space:]]|$)").s // .)
          | if length > 80 then (.[0:80] | sub("[[:space:]][^[:space:]]*$"; "")) else . end;
        .operations | to_entries[]
        | "\(.key | ascii_downcase)\t\(.value.documentation | clean)"' \
        $__aws_models/$svc/*/service-2.json >$f 2>/dev/null
    echo $f
end

# The rest of the CLI services that own no model directory are customisations
# with nothing to read a description from.
function __aws_model_dir --argument-names svc
    switch $svc
        case s3api
            echo s3
        case configservice
            echo config
        case deploy
            echo codedeploy
        case '*'
            echo $svc
    end
end

function __aws_describe
    if not command -q jq; or not test -d $__aws_models
        cat
        return
    end
    # The service is the first token naming a model, not simply the second:
    # global flags may sit before it (`aws --region us-east-1 s3 …`).
    set -l toks (commandline --current-process --cut-at-cursor --tokenize)
    for t in $toks[2..]
        set -l dir (__aws_model_dir $t)
        if test -d $__aws_models/$dir
            __aws_join (__aws_operation_table $dir)
            return
        end
    end
    __aws_join (__aws_service_table)
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
        printf '%s\n' $out | __aws_describe
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
