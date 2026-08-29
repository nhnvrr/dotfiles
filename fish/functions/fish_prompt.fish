function fish_prompt --description 'pwd, git, and a red chevron when the last command failed'
    # First line: anything run before this overwrites it.
    set -l last $status

    set_color white
    echo -n (prompt_pwd --full-length-dirs=2)
    set_color normal

    # fish_git_prompt colours only %s; the branch glyph inherits the green set here.
    set_color green
    fish_git_prompt " \uf126 %s"
    set_color normal

    test $last -ne 0; and set_color red; or set_color white
    echo -n ' ❯ '
    set_color normal
end
