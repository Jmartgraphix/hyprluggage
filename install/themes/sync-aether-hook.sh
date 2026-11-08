#!/bin/bash
# Copy the Aether Apply hook into ~/.config/aether/custom/hyprluggage.
# Aether ignores symlinks when scanning custom apps, so this must be a real directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hook_src="$SCRIPT_DIR/aether-hook"
hook_dest="${XDG_CONFIG_HOME:-$HOME/.config}/aether/custom/hyprluggage"

[[ -d "$hook_src" ]] || exit 0
chmod +x "$hook_src/post-apply.sh" 2>/dev/null || true

if [[ -L "$hook_dest" ]]; then
	rm "$hook_dest"
fi
mkdir -p "$hook_dest"
cp -a "$hook_src/." "$hook_dest/"
chmod +x "$hook_dest/post-apply.sh"
