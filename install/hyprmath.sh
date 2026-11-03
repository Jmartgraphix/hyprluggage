#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| hyprmath installer  |-/ /--|#
#|/ /---+---------------------+/ /---|#

# Pin: bump this tag after releasing a new hyprmath version.
HYPRMATH_REPO="${HYPRMATH_REPO:-https://github.com/Jmartgraphix/hyprmath.git}"
HYPRMATH_REF="${HYPRMATH_REF:-v0.1.0}"
HYPRMATH_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/hyprluggage/hyprmath"
HYPRMATH_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}/hyprmath"

_hyprmath_checkout_pin() {
	local dir="$1"
	git -C "$dir" fetch --tags --force --depth 1 origin "refs/tags/${HYPRMATH_REF}:refs/tags/${HYPRMATH_REF}" 2>/dev/null \
		|| git -C "$dir" fetch --tags --force origin "refs/tags/${HYPRMATH_REF}:refs/tags/${HYPRMATH_REF}" \
		|| git -C "$dir" fetch --tags --force origin "$HYPRMATH_REF"
	# Annotated tags peel to the commit; plain checkout of the tag name works once fetched.
	git -C "$dir" checkout -q --detach "$HYPRMATH_REF"
}

install_hyprmath() {
	step "Installing hyprmath ($HYPRMATH_REF)"

	mkdir -p "$(dirname "$HYPRMATH_SHARE")"
	mkdir -p "$(dirname "$HYPRMATH_BIN")"

	if [[ -d "$HYPRMATH_SHARE/.git" ]]; then
		info "Updating existing checkout"
		_hyprmath_checkout_pin "$HYPRMATH_SHARE" || {
			err "Failed to update hyprmath to $HYPRMATH_REF"
			return 1
		}
	else
		rm -rf "$HYPRMATH_SHARE"
		mkdir -p "$HYPRMATH_SHARE"
		git -C "$HYPRMATH_SHARE" init -q
		git -C "$HYPRMATH_SHARE" remote add origin "$HYPRMATH_REPO"
		if ! _hyprmath_checkout_pin "$HYPRMATH_SHARE"; then
			err "Failed to clone hyprmath $HYPRMATH_REF"
			rm -rf "$HYPRMATH_SHARE"
			return 1
		fi
	fi

	if [[ ! -x "$HYPRMATH_SHARE/hyprmath" ]]; then
		chmod +x "$HYPRMATH_SHARE/hyprmath" 2>/dev/null || true
	fi
	if [[ ! -f "$HYPRMATH_SHARE/hyprmath" ]]; then
		err "hyprmath entry missing after install"
		return 1
	fi
	chmod +x "$HYPRMATH_SHARE/hyprmath"

	ln -sfn "$HYPRMATH_SHARE/hyprmath" "$HYPRMATH_BIN"
	ok "hyprmath → $HYPRMATH_BIN"
}

# Allow: bash install/hyprmath.sh
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	# shellcheck source=/dev/null
	source "$DOTFILES/install/utils.sh"
	install_hyprmath
fi
