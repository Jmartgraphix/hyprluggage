#!/bin/bash
# rofi - symlink colors
src="$CURRENT_LINK/.config/rofi/colors.rasi"
[[ -f "$src" ]] || exit 0
src="$(readlink -f "$src")"
ln -sfn "$src" "$HOME/.config/rofi/colors.rasi"
