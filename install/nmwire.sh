#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| nmwire installer    |-/ /--|#
#|/ /---+---------------------+/ /---|#

# Pin: bump this tag after releasing a new nmwire version.
NMWIRE_REPO="${NMWIRE_REPO:-https://github.com/Jmartgraphix/nmwire.git}"
NMWIRE_REF="${NMWIRE_REF:-v0.1.0}"
NMWIRE_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}/hyprluggage/nmwire"
NMWIRE_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}/nmwire"
NMWIRE_DESKTOP="${XDG_DATA_HOME:-$HOME/.local/share}/applications/nmwire.desktop"

_nmwire_checkout_pin() {
	local dir="$1"
	git -C "$dir" fetch --tags --force --depth 1 origin "refs/tags/${NMWIRE_REF}:refs/tags/${NMWIRE_REF}" 2>/dev/null \
		|| git -C "$dir" fetch --tags --force origin "refs/tags/${NMWIRE_REF}:refs/tags/${NMWIRE_REF}" \
		|| git -C "$dir" fetch --tags --force origin "$NMWIRE_REF"
	# Annotated tags peel to the commit; plain checkout of the tag name works once fetched.
	git -C "$dir" checkout -q --detach "$NMWIRE_REF"
}

# True when an AUR or local package owns nmwire, so the pinned checkout must step aside.
_nmwire_pacman_owned() {
	command -v pacman &>/dev/null || return 1
	pacman -Qq nmwire &>/dev/null || pacman -Qq nmwire-git &>/dev/null
}

# Stow links the whole nmgui folder. Ignored bytecode keeps that link alive after
# the tracked files are gone, so remove the link and the leftover folder here.
_nmwire_retire_nmgui() {
	local config_link resolved dest_dir dest_css tracked
	[[ -n "${DOTFILES:-}" ]] || return 0
	config_link="${XDG_CONFIG_HOME:-$HOME/.config}/nmgui"
	[[ -L "$config_link" ]] || return 0

	if [[ -e "$config_link" ]]; then
		resolved=$(readlink -f "$config_link" 2>/dev/null || true)
		[[ "$resolved" == "$DOTFILES/.config/nmgui" ]] || return 0
	fi

	dest_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nmwire"
	dest_css="$dest_dir/style.css"
	if [[ -f "$DOTFILES/.config/nmgui/style.css" && ! -f "$dest_css" ]]; then
		mkdir -p "$dest_dir"
		mv "$DOTFILES/.config/nmgui/style.css" "$dest_css"
	fi

	rm -f "$config_link"

	if [[ -d "$DOTFILES/.git" ]] && tracked=$(git -C "$DOTFILES" ls-files -- .config/nmgui); then
		if [[ -z "$tracked" ]]; then
			rm -rf "$DOTFILES/.config/nmgui"
		fi
	fi
}

# Drop only the copies this installer created. A package file with a different Exec= stays.
_nmwire_drop_managed_copy() {
	local target=""
	if [[ -L "$NMWIRE_BIN" ]]; then
		target=$(readlink -f "$NMWIRE_BIN" 2>/dev/null || true)
		if [[ -z "$target" ]]; then
			target=$(readlink "$NMWIRE_BIN" 2>/dev/null || true)
		fi
		if [[ "$target" == "$NMWIRE_SHARE" || "$target" == "$NMWIRE_SHARE"/* ]]; then
			rm -f "$NMWIRE_BIN"
		fi
	fi
	if [[ -f "$NMWIRE_DESKTOP" ]] && grep -qx 'Exec=nmwire' "$NMWIRE_DESKTOP"; then
		rm -f "$NMWIRE_DESKTOP"
	fi
}

install_nmwire() {
	step "Installing nmwire ($NMWIRE_REF)"

	if _nmwire_pacman_owned; then
		_nmwire_retire_nmgui
		_nmwire_drop_managed_copy
		ok "nmwire from pacman"
		return 0
	fi

	mkdir -p "$(dirname "$NMWIRE_SHARE")"
	mkdir -p "$(dirname "$NMWIRE_BIN")"
	mkdir -p "$(dirname "$NMWIRE_DESKTOP")"

	if [[ -d "$NMWIRE_SHARE/.git" ]]; then
		info "Updating existing checkout"
		_nmwire_checkout_pin "$NMWIRE_SHARE" || {
			err "Failed to update nmwire to $NMWIRE_REF"
			return 1
		}
	else
		rm -rf "$NMWIRE_SHARE"
		mkdir -p "$NMWIRE_SHARE"
		git -C "$NMWIRE_SHARE" init -q
		git -C "$NMWIRE_SHARE" remote add origin "$NMWIRE_REPO"
		if ! _nmwire_checkout_pin "$NMWIRE_SHARE"; then
			err "Failed to clone nmwire $NMWIRE_REF"
			rm -rf "$NMWIRE_SHARE"
			return 1
		fi
	fi

	if [[ ! -x "$NMWIRE_SHARE/nmwire" ]]; then
		chmod +x "$NMWIRE_SHARE/nmwire" 2>/dev/null || true
	fi
	if [[ ! -f "$NMWIRE_SHARE/nmwire" ]]; then
		err "nmwire entry missing after install"
		return 1
	fi
	chmod +x "$NMWIRE_SHARE/nmwire"

	ln -sfn "$NMWIRE_SHARE/nmwire" "$NMWIRE_BIN" || {
		err "Failed to link nmwire"
		return 1
	}

	if [[ ! -f "$NMWIRE_SHARE/nmwire.desktop" ]]; then
		err "nmwire desktop file missing after install"
		return 1
	fi
	cat "$NMWIRE_SHARE/nmwire.desktop" >"$NMWIRE_DESKTOP" || {
		err "Failed to install nmwire desktop entry"
		return 1
	}
	update-desktop-database "$(dirname "$NMWIRE_DESKTOP")" 2>/dev/null || true
	rm -f "$HOME/.cache/rofi"* 2>/dev/null || true

	_nmwire_retire_nmgui
	ok "nmwire → $NMWIRE_BIN"
}

# Allow: bash install/nmwire.sh
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
	# shellcheck source=/dev/null
	source "$DOTFILES/install/utils.sh"
	install_nmwire
fi
