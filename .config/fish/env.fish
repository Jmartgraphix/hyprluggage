# MPD_HOST
export MPD_HOST="/run/user/$(id -u)/mpd/socket"

#SCRIPTS
export PATH="$HOME/Scripts/:$PATH"
set -l hl_state "$HOME/.local/state/hyprluggage/dir"
if set -q XDG_STATE_HOME; and test -n "$XDG_STATE_HOME"
    set hl_state "$XDG_STATE_HOME/hyprluggage/dir"
end
set -l hl_dir "$HOME/hyprluggage"
if test -f "$hl_state"
    set hl_dir (string trim (cat "$hl_state"))
end
fish_add_path "$hl_dir/scripts"
fish_add_path "$hl_dir/install"
fish_add_path "$hl_dir/install/themes"
export PATH="$HOME/.config/hypr/scripts:$PATH"
export PATH="$HOME/.config/waybar/scripts/:$PATH"
export PATH="$HOME/.config/rofi/scripts/:$PATH"
