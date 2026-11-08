#!/bin/bash
# mako - symlink theme-specific config and reload

command -v makoctl &>/dev/null || exit 0

# Static themes: symlink theme config.
# Dynamic: matugen writes themes/dynamic/.../mako/config (and may also
# have written a plain file under ~/.config/mako/config historically).
src="$CURRENT_LINK/.config/mako/config"
if [[ -f "$src" ]]; then
	src="$(readlink -f "$src")"
	ln -sfn "$src" "$HOME/.config/mako/config"
fi

pgrep -x mako &>/dev/null && makoctl reload 2>/dev/null || true
exit 0
