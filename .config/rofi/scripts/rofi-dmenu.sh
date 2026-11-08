#!/bin/bash
# Reliable rofi -dmenu for Hyprluggage pickers (unique pidfile, no focus fights).

pidfile="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyprluggage-rofi.pid"

if [[ -f "$pidfile" ]]; then
	old=$(cat "$pidfile" 2>/dev/null || true)
	if [[ -n "${old:-}" ]] && kill -0 "$old" 2>/dev/null; then
		if [[ "$(ps -p "$old" -o comm= 2>/dev/null)" == "rofi" ]]; then
			kill "$old" 2>/dev/null || true
			sleep 0.1
		fi
	fi
	rm -f "$pidfile"
fi

exec rofi -dmenu -i -show-icons -pid "$pidfile" "$@"
