function theme -d "Switch Alacritty theme between dark and light"
    set -l mode $argv[1]

    if not contains -- $mode dark light
        echo "Usage: theme [dark|light]"
        return 1
    end

    # Update shared mode file (read by Neovim on FocusGained)
    echo $mode > "$HOME/.config/theme-mode"

    # Switch Alacritty
    set -l themes_dir "$HOME/.config/alacritty/themes"
    cp "$themes_dir/$mode.toml" "$themes_dir/current.toml"

    echo "Switched to $mode theme"
end
