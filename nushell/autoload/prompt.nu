# A bobthefish-style prompt in nu: powerline segments in the terminal's ANSI
# colours (so it follows Ghostty's mate), one git call, a transient ❯.
#
#   [exit] [k8s] [node] [~/full/path] [ branch flags]              date

const ARROW = "\u{e0b0}"
const THIN = "\u{e0b1}"

# Colours are foreground SGR codes (30-37, 90-97 bright); a segment's
# background is that code + 10. state.bg 0 means no segment drawn yet.
def seg-open [state: record, bg: int, fg: int, bold: bool] {
    let style = $"\e[0;($fg);($bg + 10)(if $bold { ';1' } else { '' })m"
    let sep = if $state.bg == 0 {
        ' '
    } else if $state.bg == $bg {
        $"($THIN) "
    } else {
        $"\e[0;($state.bg);($bg + 10)m($ARROW)($style) "
    }
    {bg: $bg, out: $"($state.out)($style)($sep)"}
}

def seg [state: record, bg: int, fg: int, text: string, --bold] {
    let s = (seg-open $state $bg $fg $bold)
    {bg: $s.bg, out: $"($s.out)($text) "}
}

def seg-close [state: record] {
    if $state.bg == 0 { return $state.out }
    $"($state.out)\e[0;($state.bg)m($ARROW)\e[0m"
}

# Full path, with $HOME shown as ~.
def short-path [p: string] {
    if $p == $env.HOME { return '~' }
    $p | str replace -r $"^(($env.HOME | str replace -a '/' '\/'))/" '~/'
}

def find-up [dir: string, names: list<string>] {
    mut d = $dir
    loop {
        for n in $names {
            if ($d | path join $n | path exists) { return $d }
        }
        if $d == '/' { return null }
        $d = ($d | path dirname)
    }
}

def k8s-context [] {
    let f = ($env.KUBECONFIG? | default ($env.HOME | path join .kube config) | split row ':' | first)
    if not ($f | path exists) { return null }
    let line = (open --raw $f | lines | where {|l| $l | str starts-with 'current-context:' } | first?)
    if $line == null { return null }
    let ctx = ($line | str replace 'current-context:' '' | str trim -c '"' | str trim -c "'" | str trim)
    if ($ctx | is-empty) or $ctx == default { null } else { $ctx }
}

def git-segment [state: record] {
    let st = (^git --no-optional-locks status --porcelain=v2 --branch --show-stash --untracked-files=no | complete)
    if $st.exit_code != 0 { return $state }
    mut branch = ''
    mut oid = ''
    mut ahead = 0
    mut behind = 0
    mut dirty = false
    mut staged = false
    mut stashed = false
    for l in ($st.stdout | lines) {
        if ($l | str starts-with '# branch.head ') {
            $branch = ($l | str substring 14..)
        } else if ($l | str starts-with '# branch.oid ') {
            $oid = ($l | str substring 13..19)
        } else if ($l | str starts-with '# branch.ab ') {
            let ab = ($l | split row ' ')
            $ahead = ($ab | get 2 | str substring 1.. | into int)
            $behind = ($ab | get 3 | str substring 1.. | into int)
        } else if ($l | str starts-with '# stash ') {
            $stashed = true
        } else if ($l =~ '^[12] ') {
            if ($l | str substring 2..2) != '.' { $staged = true }
            if ($l | str substring 3..3) != '.' { $dirty = true }
        } else if ($l | str starts-with 'u ') {
            $dirty = true
        }
    }
    let name = match $branch {
        '(detached)' => $"\u{f417} ($oid)"
        'main' | 'master' => "\u{f418}"
        _ => $"\u{f418} ($branch)"
    }
    let flags = ([
        (if $dirty { "\u{f448}" } else { '' })
        (if $staged { "\u{f0c7}" } else { '' })
        (if $stashed { "\u{f0c6}" } else { '' })
        (if $ahead > 0 and $behind > 0 { "\u{f0dc}" } else if $ahead > 0 { "\u{f0de}" } else if $behind > 0 { "\u{f0dd}" } else { '' })
    ] | str join '')
    # green clean, bright red dirty, yellow staged; black text.
    let bg = if $dirty { 91 } else if $staged { 33 } else { 32 }
    seg $state $bg 30 (if ($flags | is-empty) { $name } else { $"($name) ($flags)" })
}

def prompt-left [] {
    let code = ($env.LAST_EXIT_CODE? | default 0)
    mut s = {bg: 0, out: ''}
    if $code != 0 { $s = (seg $s 37 31 ($code | into string) --bold) }

    let ctx = (k8s-context)
    if $ctx != null { $s = (seg $s 35 37 $"\u{2388} ($ctx)" --bold) }

    if (find-up $env.PWD [.nvmrc .node-version package.json]) != null and $env.NVM_CURRENT? != null {
        let v = ($env.NVM_CURRENT | path dirname | path basename)
        $s = (seg $s 92 30 $"\u{e718} ($v)" --bold)
    }

    # The whole working directory in one segment, git after it.
    $s = (seg $s 30 37 (short-path $env.PWD) --bold)
    if (find-up $env.PWD [.git]) != null { $s = (git-segment $s) }
    seg-close $s
}

def prompt-right [] {
    let ms = ($env.CMD_DURATION_MS? | default '0' | into int)
    let took = if $ms < 100 {
        ''
    } else if $ms < 5000 {
        $"\e[90m($ms)ms \u{e0b3} "
    } else {
        $"\e[90m(($ms / 1000) | math round -p 1)s \u{e0b3} "
    }
    $"($took)\e[35m(date now | format date '%a %d %b %H:%M:%S')\e[0m"
}

$env.PROMPT_COMMAND = {|| prompt-left }
$env.PROMPT_COMMAND_RIGHT = {|| prompt-right }
$env.PROMPT_INDICATOR = ' '
$env.PROMPT_INDICATOR_VI_INSERT = ' '
$env.PROMPT_INDICATOR_VI_NORMAL = ' '
$env.PROMPT_MULTILINE_INDICATOR = '::: '

# Transient: once a command runs, its line collapses to ❯ in the scrollback.
$env.TRANSIENT_PROMPT_COMMAND = {||
    if ($env.LAST_EXIT_CODE? | default 0) == 0 { $"\e[32m❯\e[0m" } else { $"\e[31m❯\e[0m" }
}
$env.TRANSIENT_PROMPT_COMMAND_RIGHT = ''
$env.TRANSIENT_PROMPT_INDICATOR = ' '
$env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ' '
$env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = ' '
