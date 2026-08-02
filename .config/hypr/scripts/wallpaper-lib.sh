#!/bin/bash
# Shared awww helpers for hyprluggage wallpaper scripts

ensure_awww_daemon() {
	awww query &>/dev/null && return 0
	awww-daemon &
	local i=0
	while ! awww query &>/dev/null && (( i++ < 20 )); do
		sleep 0.1
	done
}

awww_current_image() {
	awww query 2>/dev/null | grep "currently displaying" | head -1 | sed 's/.*image: //'
}

sync_hyprlock_wallpaper() {
	local path="${1:-$(awww_current_image)}"
	[[ -n "$path" && -e "$path" ]] || return 1
	mkdir -p "$HOME/.config/hyprluggage/current"
	ln -sf "$path" "$HOME/.config/hyprluggage/current/wallpaper"
}
