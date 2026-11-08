#!/bin/bash
# gtk - symlink colors for gtk3 and gtk4
for ver in "gtk-3.0" "gtk-4.0"; do
	src="$CURRENT_LINK/.config/$ver/colors.css"
	[[ -f "$src" ]] || continue
	src="$(readlink -f "$src")"
	mkdir -p "$HOME/.config/$ver"
	ln -sfn "$src" "$HOME/.config/$ver/colors.css"
done

# Kill nautilus (it doesn't auto-reload themes, needs restart)
killall nautilus 2>/dev/null || true

# Trigger GTK theme reload for running GTK apps (including Thunar)
if command -v gsettings &>/dev/null; then
	current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'adw-gtk3-dark'")
	gsettings set org.gnome.desktop.interface gtk-theme "$(echo "$current_theme" | tr -d "'")" &>/dev/null || true
	sleep 0.15
	if command -v wtype &>/dev/null; then
		wtype -k Escape &>/dev/null || true
	elif command -v xdotool &>/dev/null; then
		xdotool key Escape &>/dev/null || true
	fi
	sleep 0.05
fi

command -v nwg-look &>/dev/null && nwg-look -a &>/dev/null || true
exit 0
