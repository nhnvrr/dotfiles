command -q aws_completer; or exit

set -g __aws_models (path dirname (path resolve (command -v aws)))/awscli/botocore/data
set -g __aws_cache $HOME/.cache/fish/aws-completions

function __aws_completer_query --argument-names line
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

function __aws_join --argument-names table
    if not test -s $table
        cat
        return
    end
    awk -F\t 'NR == FNR { d[$1] = $2; next }
        { k = tolower($1); gsub(/-/, "", k)
          print (k in d && d[k] != "") ? $1 "\t" d[k] : $1 }' $table -
end

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
        set -l prev (commandline --current-process --cut-at-cursor --tokenize)
        test -n "$token"; or not string match -q -- '-*' $prev[-1]
        and __fish_complete_path $token
    end
end

complete -c aws -f -k -a '(__aws_completer_complete)'
