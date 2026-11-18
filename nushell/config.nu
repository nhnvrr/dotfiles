# Interactive nu. Environment and PATH live in env.nu; the prompt and the
# commands (ask, mate, awsp, nvm) in autoload/, sourced after this file.

$env.config.show_banner = false
$env.config.edit_mode = 'vi'
$env.config.cursor_shape = {vi_insert: blink_line, vi_normal: block, emacs: blink_line}
$env.config.history = {
    file_format: sqlite
    max_size: 50000
    sync_on_enter: true
    isolation: false
}
# Slot 8 (dark_gray, nu's default for hints) is near-black on mate's ground.
$env.config.color_config.hints = 'xterm_grey50'

$env.config.completions.algorithm = 'fuzzy'
$env.config.completions.case_sensitive = false
$env.config.completions.quick = true
$env.config.completions.partial = true
# carapace completes external commands (git, kubectl, aws, docker, brew…).
$env.config.completions.external = {
    enable: true
    max_results: 100
    completer: {|place|
        let spans = $place.command
        carapace $spans.0 nushell ...$spans | from json
    }
}

# --- per-directory environment ------------------------------------------------
def --env workspace-env [] {
    # ~/.aws/config has no [default] profile on purpose.
    let work = ($env.HOME | path join Work)
    $env.AWS_PROFILE = (if ($env.PWD == $work or ($env.PWD | str starts-with $"($work)/")) { 'work' } else { 'personal' })

    let ws = (
        [Work Side Orange]
        | each {|w| $env.HOME | path join $w }
        | where {|d| ($env.PWD == $d or ($env.PWD | str starts-with $"($d)/")) and ($d | path join .claude-config | path exists) }
    )
    if ($ws | is-empty) {
        hide-env -i CLAUDE_CONFIG_DIR
    } else {
        $env.CLAUDE_CONFIG_DIR = ($ws | first | path join .claude-config)
    }
}

# .nvmrc on cd, the default alias elsewhere; node straight from ~/.nvm/versions.
def --env nvm-auto [] {
    let rc = ($env.PWD | path join .nvmrc)
    let alias = ($env.NVM_DIR | path join alias default)
    let want = if ($rc | path exists) { open --raw $rc } else if ($alias | path exists) { open --raw $alias } else { return }
    let want = ($want | str trim | str replace -r '^v' '')
    let dirs = (glob ($env.NVM_DIR | path join versions node $"v($want)*" bin))
    if ($dirs | is-empty) {
        if ($rc | path exists) { print -e $"node ($want) not installed: nvm install ($want)" }
        return
    }
    let bin = ($dirs | sort -n | last)
    if ($env.NVM_CURRENT? == $bin) { return }
    let nvm_versions = ($env.NVM_DIR | path join versions node)
    $env.PATH = ([$bin] ++ ($env.PATH | where {|p| not ($p | str starts-with $nvm_versions) }))
    $env.NVM_CURRENT = $bin
}

$env.config.hooks.env_change.PWD = [
    {|before, after| workspace-env }
    {|before, after| nvm-auto }
]
workspace-env

# --- aliases ------------------------------------------------------------------
alias gc = git commit -m
alias gco = git checkout
alias gd = git diff
alias lg = lazygit
alias la = ls -a
def --env dw [] { cd ~/Downloads }
def --env docu [] { cd ~/Documents }

# --- keys ---------------------------------------------------------------------
# ctrl-r history, ctrl-t files, alt-c directories: all in fzf, like fish/zsh.
$env.config.keybindings ++= [
    {
        name: fzf_history
        modifier: control
        keycode: char_r
        mode: [emacs vi_insert vi_normal]
        event: {
            send: executehostcommand
            cmd: "commandline edit --replace (history | get command | reverse | uniq | str join (char nl) | fzf --exact --scheme=history --query (commandline) | str trim)"
        }
    }
    {
        name: fzf_files
        modifier: control
        keycode: char_t
        mode: [emacs vi_insert vi_normal]
        event: {
            send: executehostcommand
            cmd: "commandline edit --insert (fd --type f --hidden --follow --exclude .git | fzf --multi --preview 'bat --style=numbers --color=always --line-range :200 {}' | lines | str join ' ')"
        }
    }
    {
        name: fzf_cd
        modifier: alt
        keycode: char_c
        mode: [emacs vi_insert vi_normal]
        event: {
            send: executehostcommand
            cmd: "let d = (fd --type d --hidden --follow --exclude .git | fzf --preview 'ls -1 {}' | str trim); if ($d | is-not-empty) { cd $d }"
        }
    }
    {
        name: accept_hint
        modifier: control
        keycode: space
        mode: [emacs vi_insert]
        event: {send: historyhintcomplete}
    }
    {
        name: line_start
        modifier: control
        keycode: char_a
        mode: [vi_insert]
        event: {edit: movetolinestart}
    }
    {
        name: line_end
        modifier: control
        keycode: char_e
        mode: [vi_insert]
        event: {edit: movetolineend}
    }
]
