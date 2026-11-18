#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| hyprmath installer  |-/ /--|#
#|/ /---+---------------------+/ /---|#

# Newest v* tag unless HYPRMATH_REF is set (tag, branch, or commit).
HYPRMATH_REPO="${HYPRMATH_REPO:-https://github.com/Jmartgraphix/hyprmath.git}"
HYPRMATH_REF="${HYPRMATH_REF:-}"
HYPRMATH_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/hyprluggage/hyprmath"
HYPRMATH_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}/hyprmath"

_hyprmath_resolve_ref() {
	if [[ -n "$HYPRMATH_REF" ]]; then
		printf '%s\n' "$HYPRMATH_REF"
		return 0
	fi
	local refs tag
	if ! refs=$(git ls-remote --tags --refs "$HYPRMATH_REPO" 'v*' 2>/dev/null); then
		err "cannot reach $HYPRMATH_REPO (git ls-remote failed); check the network or set HYPRMATH_REF=vX.Y.Z" >&2
		return 1
	fi
	# Releases only: vMAJOR.MINOR.PATCH, no -rc/-beta suffixes.
	tag=$(printf '%s\n' "$refs" | awk -F/ '{print $NF}' \
		| grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1 || true)
	if [[ -z "$tag" ]]; then
		err "no hyprmath release tags (vX.Y.Z) at $HYPRMATH_REPO" >&2
		return 1
	fi
	printf '%s\n' "$tag"
}

_hyprmath_checkout_pin() {
	local dir="$1"
	local ref="$2"
	git -C "$dir" fetch --tags --force --depth 1 origin "refs/tags/${ref}:refs/tags/${ref}" 2>/dev/null \
		|| git -C "$dir" fetch --tags --force origin "refs/tags/${ref}:refs/tags/${ref}" \
		|| git -C "$dir" fetch --tags --force origin "$ref"
	# Annotated tags peel to the commit; plain checkout of the tag name works once fetched.
	git -C "$dir" checkout -q --detach "$ref"
}

install_hyprmath() {
	local ref
	ref=$(_hyprmath_resolve_ref) || return 1
	step "Installing hyprmath ($ref)"

	mkdir -p "$(dirname "$HYPRMATH_SHARE")"
	mkdir -p "$(dirname "$HYPRMATH_BIN")"

	if [[ -d "$HYPRMATH_SHARE/.git" ]]; then
		info "Updating existing checkout"
		_hyprmath_checkout_pin "$HYPRMATH_SHARE" "$ref" || {
			err "Failed to update hyprmath to $ref"
			return 1
		}
	else
		rm -rf "$HYPRMATH_SHARE"
		mkdir -p "$HYPRMATH_SHARE"
		git -C "$HYPRMATH_SHARE" init -q
		git -C "$HYPRMATH_SHARE" remote add origin "$HYPRMATH_REPO"
		if ! _hyprmath_checkout_pin "$HYPRMATH_SHARE" "$ref"; then
			err "Failed to clone hyprmath $ref"
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
