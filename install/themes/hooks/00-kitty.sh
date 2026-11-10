#!/bin/bash
# Kitty - reload colors on long-lived instances only.
# Do not signal one-shot `kitty -e …` windows (Activity/btop, yazi, etc.):
# SIGUSR1 there can tear down the child and close the OS window.
pgrep -x kitty &>/dev/null || exit 0

while read -r pid; do
	[[ -r "/proc/$pid/cmdline" ]] || continue
	cmdline=$(tr '\0' ' ' <"/proc/$pid/cmdline")
	# Match `kitty … -e cmd` / `kitty -e cmd` one-shot windows
	case " $cmdline " in
	*" -e "* | *" --hold -e "* ) continue ;;
	esac
	kill -USR1 "$pid" 2>/dev/null || true
done < <(pgrep -x kitty)

exit 0
