#!/bin/bash
# starship - symlink config
src="$CURRENT_LINK/.config/starship.toml"
[[ -f "$src" ]] || exit 0
src="$(readlink -f "$src")"
ln -sfn "$src" "$HOME/.config/starship.toml"
