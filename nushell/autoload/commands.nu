# One-off question to Claude, read-only, no session. `? <question>` too.
def ask [...question: string] {
    if ($question | is-empty) {
        print -e 'ask: <question>   — or `? <question>`'
        return
    }
    # --disallowedTools is what makes this read-only; --allowedTools only
    # auto-approves. --verbose is required or stream-json prints nothing.
    (^claude -p --safe-mode --no-session-persistence --strict-mcp-config
        --disable-slash-commands --model sonnet --effort low
        --output-format stream-json --include-partial-messages --verbose
        --allowedTools WebSearch WebFetch
        --disallowedTools Bash Write Edit NotebookEdit Read Glob Grep Task
        --system-prompt 'Answer directly and concisely: a few sentences, no preamble, no follow-up offers. Search the web when the answer depends on current or recent information, and cite the sources when you do. Reply in the language of the question.'
        -- ($question | str join ' ')
    | ^jq --unbuffered -j 'select(.type == "stream_event" and .event.delta.type == "text_delta") | .event.delta.text')
    print ''
}
alias "?" = ask

# Switch the terminal between dark and light: mate [dark|light]
# Terminal only: macOS appearance is left alone. Ghostty reloads on SIGUSR2.
def mate [mode?: string] {
    let file = ($env.HOME | path join .config ghostty mode.local)
    let mode = match $mode {
        null => (if ($file | path exists) and (open --raw $file | str contains 'mate-light') { 'dark' } else { 'light' })
        'dark' | 'light' => $mode
        _ => { error make {msg: 'mate: [dark|light]   — no argument toggles'} }
    }
    $"theme = mate-($mode)\n" | save -f $file
    ^pkill -USR2 -x ghostty
}

# pgcli with the Mate config for the current terminal mode.
def --wrapped pgcli [...args] {
    let mode = ($env.HOME | path join .config ghostty mode.local)
    let rc = if ($mode | path exists) and (open --raw $mode | str contains 'mate-light') {
        [--pgclirc ($env.HOME | path join .config pgcli config-light)]
    } else { [] }
    ^pgcli ...$rc ...$args
}

# Active AWS profile and region, in the AWS CLI's order: environment first,
# then the profile's region in ~/.aws/config.
def awsp [] {
    let profile = ($env.AWS_PROFILE? | default '(none)')
    mut region = ($env.AWS_REGION? | default ($env.AWS_DEFAULT_REGION? | default ''))
    let cfg = ($env.HOME | path join .aws config)
    if ($region | is-empty) and ($cfg | path exists) {
        mut inside = false
        for l in (open --raw $cfg | lines | str trim) {
            if ($l | str starts-with '[') {
                $inside = ($l == $"[profile ($profile)]")
            } else if $inside and ($l =~ '^region\s*=') {
                $region = ($l | split row '=' | get 1 | str trim)
                break
            }
        }
    }
    print $"profile: ($profile)"
    print $"region:  (if ($region | is-empty) { '(none)' } else { $region })"
}

# nvm is bash-only: commands run through bash, node switches on cd (config.nu).
def --env --wrapped nvm [...args] {
    if $args == [current] {
        print ($env.NVM_CURRENT? | default 'none/bin' | path dirname | path basename)
        return
    }
    ^bash -c 'source /opt/homebrew/opt/nvm/nvm.sh --no-use && nvm "$@"' nvm ...$args
    $env.NVM_CURRENT = null
    nvm-auto
}
