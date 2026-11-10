#!/bin/bash
# ghostty - reload colors without killall (helpers ignore USR2 and die)
pgrep -x ghostty &>/dev/null || exit 0

# Prefer D-Bus action (reloads config; does not broadcast USR2 to helpers)
if gdbus call --session \
	--dest com.mitchellh.ghostty \
	--object-path /com/mitchellh/ghostty \
	--method org.gtk.Actions.Activate reload-config '[]' '{}' &>/dev/null; then
	exit 0
fi

# Fallback: signal only processes whose name is exactly "ghostty"
while read -r pid; do
	[[ -n "$pid" ]] || continue
	kill -USR2 "$pid" 2>/dev/null || true
done < <(pgrep -x ghostty)

exit 0
