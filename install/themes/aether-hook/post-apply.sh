#!/bin/bash
# Aether runs this after Apply writes ~/.config/aether/theme/.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
hypr=""

# Inside the repo this sits next to the hyprluggage command.
# Once copied into ~/.config/aether/custom/hyprluggage, that relative path is the hook directory.
if [[ -f "$here/../hyprluggage" && -x "$here/../hyprluggage" ]]; then
    hypr="$(cd "$here/.." && pwd)/hyprluggage"
elif [[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage/dir" ]]; then
    cand="$(<"${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage/dir")/install/themes/hyprluggage"
    [[ -x "$cand" ]] && hypr="$cand"
fi
if [[ -z "$hypr" && -x "$HOME/hyprluggage/install/themes/hyprluggage" ]]; then
    hypr="$HOME/hyprluggage/install/themes/hyprluggage"
fi
if [[ -z "$hypr" ]] && command -v hyprluggage >/dev/null 2>&1; then
    hypr="$(command -v hyprluggage)"
fi
if [[ -z "$hypr" ]]; then
    echo "hyprluggage not found" >&2
    exit 1
fi

log="${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage/aether-apply.log"
mkdir -p "$(dirname "$log")"
exec "$hypr" apply-aether >>"$log" 2>&1
