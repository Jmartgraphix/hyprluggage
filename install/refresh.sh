#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Noninteractive refresh |--/ |-|#
#|/ /---+---------------------+/ /---|#
#
# Used by `hyprluggage update` / `rollback`: core packages, stow, and pinned apps.
# Skips Cursor, shell chooser, optional apps, services prompts, themes.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/install/utils.sh"

export HYPRLUGGAGE_REFRESH=1
source "$DOTFILES/install/packages.sh"
source "$DOTFILES/install/stow.sh"

# Pinned apps from their own repos (pin lives in each installer)
source "$DOTFILES/install/hyprmath.sh"
install_hyprmath || warn "hyprmath refresh failed"
source "$DOTFILES/install/nmwire.sh"
install_nmwire || warn "nmwire refresh failed"

# Aether's custom apps dir cannot be a symlink — keep the Apply hook in sync
# on update/rollback (themes/install.sh also runs this on first install).
if [[ -x "$DOTFILES/install/themes/sync-aether-hook.sh" ]]; then
	"$DOTFILES/install/themes/sync-aether-hook.sh" || true
fi
