#!/bin/bash
# btop - point current.theme at the active theme (live reload via USR2).
# Use kill -USR2 on exact PIDs — never `pkill -x -USR2` (parsed as -U / euid).
src="$CURRENT_LINK/.config/btop/themes/current.theme"
[[ -f "$src" ]] || exit 0

mkdir -p "$HOME/.config/btop/themes"
ln -sf "$src" "$HOME/.config/btop/themes/current.theme"

btop_conf="$HOME/.config/btop/btop.conf"
if [[ -f "$btop_conf" ]]; then
	sed -i -E "s|/home/[^/]+/.config|$HOME/.config|g" "$btop_conf"
fi

if pids=$(pgrep -x btop 2>/dev/null); then
	# shellcheck disable=SC2086
	kill -USR2 $pids 2>/dev/null || true
fi
exit 0
