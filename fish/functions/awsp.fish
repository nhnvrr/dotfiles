function awsp --description 'Print the active AWS profile and region'
    # Same order as the AWS CLI: environment first, then the profile in ~/.aws/config.
    set -l region $AWS_REGION $AWS_DEFAULT_REGION
    if test -z "$region[1]"; and test -r $HOME/.aws/config
        set region (awk -v p="[profile $AWS_PROFILE]" \
            '$0==p{f=1;next} /^\[/{f=0} f&&$1=="region"{print $3;exit}' $HOME/.aws/config)
    end
    echo "profile: "(set -q AWS_PROFILE; and echo $AWS_PROFILE; or echo '(none)')
    echo "region:  "(test -n "$region[1]"; and echo $region[1]; or echo '(none)')
end
