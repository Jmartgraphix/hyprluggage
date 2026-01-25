#!/bin/bash
# gtk - symlink colors for gtk3 and gtk4
for ver in "gtk-3.0" "gtk-4.0"; do
    src="$CURRENT_LINK/.config/$ver/colors.css"
    [[ -f "$src" ]] || continue
    mkdir -p "$HOME/.config/$ver"
    ln -sf "$src" "$HOME/.config/$ver/colors.css"
done

# refresh gtk apps
# Kill nautilus (it doesn't auto-reload themes, needs restart)
killall nautilus 2>/dev/null

# Trigger GTK theme reload for running GTK apps (including Thunar)
# This forces GTK apps to reload their CSS without restarting
# Thunar will stay open and update its colors immediately
if command -v gsettings &>/dev/null; then
    current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || echo "'adw-gtk3-dark'")
    # Setting the theme to itself triggers a reload event that GTK apps monitor
    gsettings set org.gnome.desktop.interface gtk-theme "$(echo "$current_theme" | tr -d "'")" &>/dev/null || true
fi

command -v nwg-look &>/dev/null && nwg-look -a &>/dev/null
exit 0
