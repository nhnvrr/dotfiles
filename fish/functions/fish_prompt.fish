function fish_prompt --description 'pwd, git, and a red chevron when the last command failed'
    # First line: anything run before this overwrites it.
    set -l last $status

    # Double-width glyph: the space after it is what keeps the cursor column
    # in step with what the terminal actually drew.
    echo -n '🧉 '
    set_color white
    echo -n (prompt_pwd --full-length-dirs=2)
    set_color normal

    set_color green
    fish_git_prompt " %s"
    set_color normal

    test $last -ne 0; and set_color red; or set_color white
    echo -n ' ❯ '
    set_color normal
end
