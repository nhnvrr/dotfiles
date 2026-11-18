# Environment and PATH, read before config.nu. nu is the login shell, and no
# path_helper runs for it, so /etc/paths is read here.

$env.HOMEBREW_PREFIX = '/opt/homebrew'
$env.HOMEBREW_CELLAR = '/opt/homebrew/Cellar'
$env.HOMEBREW_REPOSITORY = '/opt/homebrew'

$env.LANG = 'en_US.UTF-8'
$env.EDITOR = 'vim'
$env.VISUAL = 'vim'

$env.GOPATH = ($env.HOME | path join Develop go)
$env.GOPRIVATE = 'github.com/nhnvrr'
$env.PNPM_HOME = ($env.HOME | path join Library pnpm)

$env.AWS_PAGER = ''
$env.AWS_RETRY_MODE = 'standard'
$env.AWS_MAX_ATTEMPTS = '3'

$env.REDISCLI_HISTFILE = ($env.HOME | path join .local state redis history)
$env.BAT_THEME = 'ansi'
$env.NVM_DIR = ($env.HOME | path join .nvm)

# Default node from nvm's alias file, without nvm.sh (bash-only).
def nvm-bin [want: string] {
    let want = ($want | str trim | str replace -r '^v' '')
    let dirs = (glob ($env.NVM_DIR | path join versions node $"v($want)*" bin))
    if ($dirs | is-empty) { null } else { $dirs | sort -n | last }
}
let nvm_default = do {
    let f = ($env.NVM_DIR | path join alias default)
    if ($f | path exists) { nvm-bin (open $f) } else { null }
}

let system_paths = (
    [/etc/paths] ++ (glob /etc/paths.d/*)
    | where {|f| $f | path exists }
    | each {|f| open --raw $f | lines }
    | flatten
)

# Same order as zshenv. mise runs as shims: no per-prompt hook-env.
$env.PATH = (
    [
        $nvm_default
        ($env.HOME | path join .local share mise shims)
        ($env.GOPATH | path join bin)
        /opt/homebrew/bin
        /opt/homebrew/sbin
        /opt/homebrew/opt/libpq/bin
        ($env.HOME | path join .bun bin)
        ($env.HOME | path join .local bin)
        ($env.PNPM_HOME | path join bin)
        ($env.HOME | path join .docker bin)
        /usr/local/bin
    ]
    ++ $system_paths
    ++ ($env.PATH | split row (char esep))
    | compact
    | where {|p| $p | path exists }
    | uniq
)
$env.NVM_CURRENT = $nvm_default

$env.FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
$env.FZF_DEFAULT_OPTS = '--height 40% --layout=reverse --border=rounded --color=16,fg:-1,bg:-1,fg+:-1,bg+:8,hl:3,hl+:3:bold,prompt:1,pointer:1,marker:1,spinner:3,info:8,header:4,border:8,separator:8,scrollbar:8,label:8'
# carapace falls back to these shells' own completions for commands it lacks.
$env.CARAPACE_BRIDGES = 'zsh,fish,bash'
