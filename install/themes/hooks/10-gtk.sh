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
    # Small delay to let any popups from theme reload appear
    sleep 0.15
    # Dismiss any system tray popups that may appear during theme reload
    # This works for most system tray popups that respond to Escape
    if command -v wtype &>/dev/null; then
        wtype -k Escape &>/dev/null || true
    elif command -v xdotool &>/dev/null; then
        xdotool key Escape &>/dev/null || true
    fi
    # Small delay to ensure popup is dismissed
    sleep 0.05
fi

command -v nwg-look &>/dev/null && nwg-look -a &>/dev/null
exit 0
