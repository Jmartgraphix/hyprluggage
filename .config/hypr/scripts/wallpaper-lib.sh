#!/bin/bash
# Shared awww helpers for hyprluggage wallpaper scripts

ensure_awww_daemon() {
	if awww query &>/dev/null; then
		return 0
	fi
	# Prefer the user unit when present (session install); else start a one-off daemon.
	if systemctl --user restart awww.service 2>/dev/null; then
		:
	else
		awww-daemon &
	fi
	local i=0
	while ! awww query &>/dev/null && (( i++ < 30 )); do
		sleep 0.1
	done
}

awww_current_image() {
	awww query 2>/dev/null | grep "currently displaying" | head -1 | sed 's/.*image: //'
}

# Hyprlock reads this path. Keep it outside the theme symlink so picker/dynamic
# updates do not rewrite themes/<name>/wallpaper.
hyprlock_wallpaper_link() {
	printf '%s\n' "$HOME/.config/hyprluggage/wallpaper"
}

sync_hyprlock_wallpaper() {
	local path="${1:-$(awww_current_image)}"
	[[ -n "$path" && -e "$path" ]] || return 1
	mkdir -p "$HOME/.config/hyprluggage"
	ln -sfn "$path" "$(hyprlock_wallpaper_link)"
}

hyprluggage_repo_dir() {
	if [[ -x "$HOME/.config/hypr/scripts/hyprluggage-dir" ]]; then
		"$HOME/.config/hypr/scripts/hyprluggage-dir"
	else
		printf '%s\n' "$HOME/hyprluggage"
	fi
}

current_hyprluggage_theme() {
	cat "$HOME/.config/hyprluggage/.current-theme" 2>/dev/null || echo "dynamic"
}

# Apply a wallpaper path. If the active theme is dynamic, also regenerate colors.
# Returns 0 on success, 1 if the file is missing (caller reports it), 2 if
# matugen failed (already reported here; mako and hyprluggage are not reloaded).
apply_wallpaper() {
	local wp="$1"
	shift || true
	[[ -f "$wp" ]] || return 1

	ensure_awww_daemon
	awww img "$wp" "$@"

	sync_hyprlock_wallpaper "$wp" || true

	local theme repo log
	theme=$(current_hyprluggage_theme)
	repo=$(hyprluggage_repo_dir)
	if [[ "$theme" == "dynamic" ]]; then
		# Output paths in the matugen config are absolute from /. Matugen
		# resolves a relative path against the config file first, then --prefix
		# pastes the repo in front, which writes home/<user>/hyprluggage/...
		# inside the clone. The leading slash lets --prefix land in this repo,
		# including a clone that is not ~/hyprluggage. Those outputs are
		# gitignored. baseline/ is the seed.
		# A keybind has no terminal. Without --source-color-index, matugen 4.x
		# asks which source color to use and exits. 0 = top-ranked (3.x behavior).
		# stderr goes to a small log so a keybind failure can be read later.
		log="${XDG_CACHE_HOME:-$HOME/.cache}/hyprluggage-matugen.log"
		mkdir -p "$(dirname "$log")"
		if [[ -f "$log" ]] && (($(stat -c %s "$log" 2>/dev/null || echo 0) > 262144)); then
			: >"$log"
		fi
		printf '\n== %s %s\n' "$(date '+%F %T')" "$wp" >>"$log"
		if ! matugen image "$wp" -m dark --source-color-index 0 -p "$repo" 2>>"$log"; then
			notify-send -u critical "Matugen failed" "Colors unchanged for $(basename "$wp"). Details: ${log/#"$HOME"/\~}"
			return 2
		fi
		ln -sfn "$wp" "$repo/themes/dynamic/wallpaper"
		pgrep -x mako &>/dev/null && makoctl reload 2>/dev/null || true
		"$repo/install/themes/hyprluggage" reload || true
	fi
}
