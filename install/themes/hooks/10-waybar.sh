#!/bin/bash
# waybar - symlink colors and restart
src="$CURRENT_LINK/.config/waybar/colors.css"
[[ -f "$src" ]] || exit 0
ln -sf "$src" "$HOME/.config/waybar/colors.css"

systemctl --user try-restart waybar.service 2>/dev/null \
  || systemctl --user restart waybar.service 2>/dev/null \
  || true
exit 0
