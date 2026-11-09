#!/bin/bash
# Thin theme smoke: layout + colors.toml parsing. No Hyprland, no hooks.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
THEMES_DIR="${THEMES_DIR:-$ROOT/themes}"
IMPORT_INIT="$SCRIPT_DIR/hyprluggage-import/init.sh"
FIXTURES="$SCRIPT_DIR/hyprluggage-import/testdata"
THEME_FORMAT=1

errors=0
checked=0

fail() {
	echo "FAIL: $*" >&2
	errors=$((errors + 1))
}

ok() {
	echo "OK: $*"
}

theme_format_of() {
	local file="$1"
	[[ -f "$file" ]] || { echo ""; return 0; }
	awk -F'=' '
		/^[[:space:]]*format[[:space:]]*=/ {
			gsub(/[[:space:]]/, "", $2)
			print $2
			exit
		}
	' "$file"
}

check_theme() {
	local dest="$1" name got req
	name="$(basename "$dest")"
	checked=$((checked + 1))

	if [[ ! -f "$dest/theme.toml" ]]; then
		fail "$name: missing theme.toml"
		return
	fi
	got=$(theme_format_of "$dest/theme.toml")
	if [[ "$got" != "$THEME_FORMAT" ]]; then
		fail "$name: theme.toml format='$got' (want $THEME_FORMAT)"
	fi

	# themes/*/wallpaper is gitignored (user preference). Static themes must
	# ship at least one image under backgrounds/; dynamic uses ~/Wallpapers.
	if [[ "$name" != "dynamic" ]]; then
		if ! find "$dest/backgrounds" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | grep -q .; then
			fail "$name: no images in backgrounds/"
		fi
	fi

	for req in \
		.config/hypr/theme/colors.lua \
		.config/waybar/colors.css \
		.config/mako/config; do
		if [[ ! -f "$dest/$req" ]]; then
			fail "$name: missing $req"
		fi
	done
}

check_colors_fixtures() {
	local td words accent palette
	td=$(mktemp -d)
	# shellcheck disable=SC2064
	trap "rm -rf '$td'" EXIT

	mkdir -p "$td/semantic" "$td/ansi"
	cp "$FIXTURES/omarchy-semantic.colors.toml" "$td/semantic/colors.toml"
	cp "$FIXTURES/aether-ansi.colors.toml" "$td/ansi/colors.toml"

	# shellcheck source=/dev/null
	source "$IMPORT_INIT"

	words=$(get_colors "$td/semantic" | wc -w)
	[[ "$words" -eq 18 ]] || fail "semantic colors.toml: got $words fields (want 18)"
	accent=$(read_toml_accent "$td/semantic" || true)
	[[ "$accent" == "#d9a56c" ]] || fail "semantic accent: got '$accent' (want #d9a56c)"
	palette=$(get_colors "$td/semantic")
	[[ "$palette" == *"#e85f6f"* ]] || fail "semantic palette missing red #e85f6f"
	[[ "$palette" == *"#d9a56c"* ]] || fail "semantic palette missing blue/accent #d9a56c"

	words=$(get_colors "$td/ansi" | wc -w)
	[[ "$words" -eq 18 ]] || fail "ansi colors.toml: got $words fields (want 18)"
	palette=$(get_colors "$td/ansi")
	# Explicit color1 must win over semantic red when both exist.
	[[ "$palette" == *"#111111"* ]] || fail "ansi palette missing explicit color1 #111111"

	ok "colors.toml fixtures"
	trap - EXIT
	rm -rf "$td"
}

echo "Theme smoke under $THEMES_DIR"
shopt -s nullglob
for dest in "$THEMES_DIR"/*/; do
	name="$(basename "$dest")"
	[[ "$name" == "Wallpapers" || "$name" == ".git" ]] && continue
	check_theme "$dest"
done
shopt -u nullglob

[[ "$checked" -gt 0 ]] || fail "no themes found under $THEMES_DIR"
ok "$checked themes checked"

if [[ -f "$IMPORT_INIT" && -f "$FIXTURES/omarchy-semantic.colors.toml" && -f "$FIXTURES/aether-ansi.colors.toml" ]]; then
	check_colors_fixtures
else
	fail "import fixtures missing under $FIXTURES"
fi

if [[ "$errors" -gt 0 ]]; then
	echo "Theme smoke: $errors failure(s)" >&2
	exit 1
fi
echo "Theme smoke: all good"
