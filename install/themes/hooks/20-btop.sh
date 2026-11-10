#!/bin/bash
# btop - point current.theme at the active theme (live reload via USR2).
# Do not sed the stowed btop.conf (that dirties git / blocks hyprluggage update).
# color_theme = "current" matches ~/.config/btop/themes/current.theme by stem.
src="$CURRENT_LINK/.config/btop/themes/current.theme"
[[ -f "$src" ]] || exit 0

mkdir -p "$HOME/.config/btop/themes"
ln -sf "$src" "$HOME/.config/btop/themes/current.theme"

if pids=$(pgrep -x btop 2>/dev/null); then
	# shellcheck disable=SC2086
	kill -USR2 $pids 2>/dev/null || true
fi
exit 0
