#!/bin/bash
# waybar - symlink colors; prefer reload over restart
src="$CURRENT_LINK/.config/waybar/colors.css"
[[ -f "$src" ]] || exit 0
# Resolve through ~/.config/hyprluggage/current so the link target string
# changes on every theme switch (reload_style_on_change + inotify).
src="$(readlink -f "$src")"
[[ -f "$src" ]] || exit 0
ln -sfn "$src" "$HOME/.config/waybar/colors.css"

# Full `restart` kills everything in waybar.service's cgroup (KillMode=
# control-group), including themePicker → hyprluggage switch started from
# an on-click — so the post-switch notification never ran. Reload (SIGUSR2)
# + reload_style_on_change is enough for colors.css.
if systemctl --user reload waybar.service 2>/dev/null; then
	exit 0
fi
if pgrep -x waybar &>/dev/null; then
	pkill -SIGUSR2 waybar 2>/dev/null || true
	exit 0
fi
if systemctl --user start waybar.service 2>/dev/null; then
	exit 0
fi
waybar >/dev/null 2>&1 &
disown
exit 0
