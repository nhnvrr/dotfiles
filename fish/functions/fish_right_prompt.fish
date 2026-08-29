function fish_right_prompt --description 'Time with UTC offset'
    set_color magenta
    date '+%H:%M:%S %z'
    set_color normal
end
