#!/bin/bash
# Hyprland - reload config so looknfeel picks up the new colors.lua
if ! pgrep -x Hyprland &>/dev/null; then
	exit 0
fi

if hyprctl reload &>/dev/null; then
	exit 0
fi

# Bind/hook contexts can inherit a stale HYPRLAND_INSTANCE_SIGNATURE after
# compositor restarts; pick a live instance.
runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"
[[ -d "$runtime" ]] || exit 0
for inst in "$runtime"/*; do
	[[ -d "$inst" ]] || continue
	sig=$(basename "$inst")
	if HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl reload &>/dev/null; then
		exit 0
	fi
done
exit 0
