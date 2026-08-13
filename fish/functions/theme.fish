# The theme switch for the whole terminal stack: three families, two modes each.
#
# Alacritty's sixteen ANSI slots are the single source of truth, so swapping the
# imported theme file drags fish, starship, fzf, bat, eza, delta and pgcli's
# [colors] along with it and none of them need a line of their own. Four things do
# need a hand, and each for a different reason:
#
#   btop    keeps its own hex, so its theme is generated from those same slots
#   pgcli   syntax_style is a pygments name resolved inside Python, not a path
#   herdr   ships native themes per family, named in its own config
#   nvim    can ask the terminal for the mode but not for the family
#
# The live state is not stored anywhere of its own: it is the `# theme:` and
# `# mode:` markers in the deployed theme.toml, so there is no second copy to
# drift.

set -g __theme_families solarized gruvbox one

# pgcli's style per family and mode. pygments ships five of the six; one-light
# does not exist, and `default` is the most legible light style measured against
# One Light's background — 4.14:1 at its worst token, where the alternatives sas
# and perldoc give 3.90 and 3.41. It is a substitute, not the official pairing.
set -g __theme_pgcli_solarized_dark  solarized-dark
set -g __theme_pgcli_solarized_light solarized-light
set -g __theme_pgcli_gruvbox_dark    gruvbox-dark
set -g __theme_pgcli_gruvbox_light   gruvbox-light
set -g __theme_pgcli_one_dark        one-dark
set -g __theme_pgcli_one_light       default

# herdr's own theme names. It picks between the two itself, by asking the terminal
# for its background the same way nvim does, so only the family is written here.
set -g __theme_herdr_solarized solarized solarized-light
set -g __theme_herdr_gruvbox   gruvbox   gruvbox-light
set -g __theme_herdr_one       one-dark  one-light

# Pull every colour out of a deployed theme file as `section_key hex` rows, where
# the section is p/n/b for primary/normal/bright. The section tracking is the
# point: `red` exists in both [colors.normal] and [colors.bright].
function __theme_slots --argument-names file
    awk '
      /^\[colors\.primary\]/ { sec = "p"; next }
      /^\[colors\.normal\]/  { sec = "n"; next }
      /^\[colors\.bright\]/  { sec = "b"; next }
      /^\[/                  { sec = "";  next }
      sec != "" && /^[a-z_]+[ ]*=[ ]*"#/ {
        if (match($0, /#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]/))
          printf "%s_%s %s\n", sec, $1, substr($0, RSTART, RLENGTH)
      }
    ' $file
end

function theme --description 'Switch the terminal stack between theme families and modes'
    # The repo root, from this file's own symlink. install.sh links
    # fish/functions/theme.fish, so three levels up from the resolved path is it.
    set -l self (status filename)
    set -l repo
    test -n "$self"; and set repo (dirname (dirname (dirname (realpath $self))))
    if not test -d "$repo/alacritty/themes"
        echo "theme: cannot find the dotfiles repo from '$self'" >&2
        return 1
    end

    set -l deployed $HOME/.config/alacritty/theme.toml
    set -l cur_family cur_mode
    if test -f $deployed
        set cur_family (string match -rg '^# theme: (\S+)' <$deployed | head -1)
        set cur_mode (string match -rg '^# mode: (\S+)' <$deployed | head -1)
    end

    # Two axes, either of which can be omitted to keep what is live.
    set -l family $cur_family
    set -l mode $cur_mode
    for arg in $argv
        if contains -- $arg $__theme_families
            set family $arg
        else
            switch $arg
                case dark light
                    set mode $arg
                case toggle
                    test "$mode" = dark; and set mode light; or set mode dark
                case '*'
                    echo "theme: unknown argument '$arg'" >&2
                    echo "usage: theme [solarized|gruvbox|one] [dark|light|toggle]" >&2
                    return 1
            end
        end
    end

    if test -z "$family" -o -z "$mode"
        echo "theme: nothing deployed yet; run e.g. 'theme gruvbox dark'" >&2
        return 1
    end

    # Nothing asked for: report and stop before touching a single file.
    if test (count $argv) -eq 0
        echo "$family $mode"
        return 0
    end

    set -l src "$repo/alacritty/themes/$family-$mode.toml"
    if not test -f $src
        echo "theme: no such theme file: $src" >&2
        return 1
    end

    # --- alacritty ---------------------------------------------------------
    # A copy and not a symlink, twice over: the watcher does not fire reliably on
    # a repointed link, and a link into the repo would have every switch write
    # inside the working tree. rm first because both cp and > follow an existing
    # symlink and would edit its target instead of replacing it.
    mkdir -p (dirname $deployed)
    rm -f $deployed
    cp $src $deployed
    # Insurance only. Alacritty watches the files in its import chain, so
    # replacing theme.toml is what triggers the reload; touching the top-level
    # config costs nothing and covers the case where it stops.
    touch $HOME/.config/alacritty/alacritty.toml

    # --- btop --------------------------------------------------------------
    # Generated from the slots just deployed, into the name btop.conf asks for.
    set -l tmpl "$repo/btop/themes/template.theme"
    set -l out (cat $tmpl)
    for row in (__theme_slots $src)
        set -l pair (string split ' ' $row)
        set out (string replace -a "@$pair[1]@" $pair[2] -- $out)
    end
    # Fail loud: an unresolved placeholder makes btop fall back to its own theme
    # silently, which reads as "the switch did nothing".
    if string match -qr '@[a-z]+_[a-z]+@' -- $out
        echo "theme: unresolved placeholders in $tmpl" >&2
        printf '%s\n' $out | string match -r '.*@[a-z]+_[a-z]+@.*' >&2
        return 1
    end
    mkdir -p $HOME/.config/btop/themes
    rm -f $HOME/.config/btop/themes/current.theme
    printf '%s\n' $out >$HOME/.config/btop/themes/current.theme

    # --- pgcli -------------------------------------------------------------
    # syntax_style is the one setting in the stack that resolves neither through
    # an ANSI slot nor through a path, so the deployed config is a copy with that
    # single line rewritten. The trap: editing pgcli/config no longer lands until
    # `theme` runs again.
    set -l style (eval echo \$__theme_pgcli_{$family}_{$mode})
    mkdir -p $HOME/.config/pgcli
    rm -f $HOME/.config/pgcli/config
    sed -E "s/^syntax_style = .*/syntax_style = $style/" "$repo/pgcli/config" \
        >$HOME/.config/pgcli/config

    # --- herdr -------------------------------------------------------------
    # Native themes per family, which are more faithful to each than deriving from
    # the palette would be. The resolved name is written outright rather than left
    # to herdr's auto_switch: that asks the terminal for its background and did not
    # follow, and switching the half by hand in the UI makes herdr persist its
    # choice here as `name` with auto_switch = false — which pins it and leaves the
    # keys auto_switch had been choosing between ignored. Both keys are forced on
    # every switch so whatever the UI wrote is overwritten.
    set -l pair (eval echo \$__theme_herdr_$family)
    set -l hnames (string split ' ' $pair)
    set -l hname $hnames[1]
    test "$mode" = light; and set hname $hnames[2]
    if test -f "$repo/herdr/config.toml"
        mkdir -p $HOME/.config/herdr
        rm -f $HOME/.config/herdr/config.toml
        sed -E -e "s/^name = .*/name = \"$hname\"/" \
               -e "s/^auto_switch = .*/auto_switch = false/" \
            "$repo/herdr/config.toml" >$HOME/.config/herdr/config.toml
        # Only if a server is up; on a fresh machine there is nothing to reload.
        if command -q herdr
            herdr server reload-config >/dev/null 2>&1
        end
    end

    echo "$family $mode"
end
