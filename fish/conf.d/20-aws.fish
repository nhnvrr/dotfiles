status is-interactive; or return

# ~/.aws/config has no [default] profile on purpose: work under ~/work,
# personal everywhere else.
function _aws_profile --on-variable PWD
    if string match -q -- "$HOME/work" "$PWD"
        or string match -q -- "$HOME/work/*" "$PWD"
        set -gx AWS_PROFILE work
    else
        set -gx AWS_PROFILE personal
    end
end
_aws_profile
