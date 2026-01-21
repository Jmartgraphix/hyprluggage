#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| User Services       |-/ /--|#
#|/ /---+---------------------+/ /---|#

step "Setting up services"

# ── Power Profile ─────────────────────────────────────────────────────────────
if command -v powerprofilesctl &>/dev/null; then
    if ls /sys/class/power_supply/BAT* &>/dev/null; then
        powerprofilesctl set balanced &>/dev/null && ok "power profile: balanced (laptop)"
    else
        powerprofilesctl set performance &>/dev/null && ok "power profile: performance (desktop)"
    fi
fi

# ── Bluetooth ──────────────────────────────────────────────────────────────────
if pkg_installed bluez; then
    sudo systemctl enable --now bluetooth &>/dev/null && ok "bluetooth" || warn "bluetooth failed"
fi

# ── Tray Applets ──────────────────────────────────────────────────────────────
# Disable blueman/nm-applet (waybar handles these)
for app in blueman nm-applet; do
    [[ -f "/etc/xdg/autostart/${app}.desktop" ]] || continue
    mkdir -p ~/.config/autostart
    echo -e "[Desktop Entry]\nHidden=true" > ~/.config/autostart/${app}.desktop
    ok "Disabled ${app} tray (waybar module used instead)"
done

# ── GTK ───────────────────────────────────────────────────────────────────────
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    ok "GTK dark theme"
fi

# ── MPD ───────────────────────────────────────────────────────────────────────
if pkg_installed mpd; then
    mkdir -p ~/.config/systemd/user/mpd.service.d
    echo -e "[Service]\nRuntimeDirectory=mpd" > ~/.config/systemd/user/mpd.service.d/override.conf
    # Check if systemd --user is available before trying to use it
    if systemctl --user daemon-reload &>/dev/null; then
        systemctl --user enable --now mpd &>/dev/null && ok "mpd" || warn "mpd failed"
    else
        warn "mpd: systemd --user not available (will be enabled on next login)"
    fi
fi

# ── mpdscribble ───────────────────────────────────────────────────────────────
# Last.fm scrobbler for MPD
if pkg_installed mpdscribble; then
    if grep -q "YOUR_USERNAME" ~/.config/mpdscribble/mpdscribble.conf 2>/dev/null; then
        warn "mpdscribble: Edit ~/.config/mpdscribble/mpdscribble.conf with your Last.fm credentials"
    else
        if systemctl --user enable --now mpdscribble &>/dev/null; then
            ok "mpdscribble"
        else
            warn "mpdscribble: systemd --user not available (will be enabled on next login)"
        fi
    fi
fi

# ── GNOME Keyring ─────────────────────────────────────────────────────────────
# Prevents browser logout after suspend by creating an auto-unlock keyring
if pkg_installed gnome-keyring; then
    keyring_dir="$HOME/.local/share/keyrings"
    keyring_file="$keyring_dir/Default_keyring.keyring"

    if [[ ! -f "$keyring_file" ]]; then
        mkdir -p "$keyring_dir"

        cat > "$keyring_file" << EOF
[keyring]
display-name=Default keyring
ctime=$(date +%s)
mtime=0
lock-on-idle=false
lock-after=false
EOF

        echo "Default_keyring" > "$keyring_dir/default"

        chmod 700 "$keyring_dir"
        chmod 600 "$keyring_file"
        chmod 644 "$keyring_dir/default"

        ok "gnome-keyring"
    else
        ok "gnome-keyring (already configured)"
    fi
fi

# ── Spotify ───────────────────────────────────────────────────────────────────
# Configures spicetify for Hyprluggage theming
if pkg_installed spicetify-cli; then
    spotify_path=""
    prefs_path=""
    share_dir="${XDG_DATA_HOME:-$HOME/.local/share}"

    # Detect install location
    if [[ -d "$share_dir/spotify-launcher/install/usr/share/spotify" ]]; then
        spotify_path="$share_dir/spotify-launcher/install/usr/share/spotify"
        prefs_path="$HOME/.config/spotify/prefs"
    elif [[ -d /opt/spotify ]]; then
        spotify_path="/opt/spotify"
        prefs_path="$HOME/.config/spotify/prefs"
    elif [[ -d "$share_dir/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify" ]]; then
        spotify_path="$share_dir/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
        prefs_path="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
    elif [[ -d /var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify ]]; then
        spotify_path="/var/lib/flatpak/app/com.spotify.Client/x86_64/stable/active/files/extra/share/spotify"
        prefs_path="$HOME/.var/app/com.spotify.Client/config/spotify/prefs"
    fi

    if [[ -n "$spotify_path" ]]; then
        spicetify &>/dev/null

        # Set write permissions
        if [[ ! -w "$spotify_path" ]] || [[ -d "$spotify_path/Apps" && ! -w "$spotify_path/Apps" ]]; then
            info "Spicetify needs write access to Spotify"
            sudo chmod a+wr "$spotify_path" 2>/dev/null
            sudo chmod a+wr -R "$spotify_path/Apps" 2>/dev/null
        fi

        mkdir -p "$(dirname "$prefs_path")"
        touch "$prefs_path"

        spicetify config spotify_path "$spotify_path" &>/dev/null
        spicetify config prefs_path "$prefs_path" &>/dev/null
        spicetify config spotify_launch_flags "--ozone-platform=wayland" &>/dev/null
        spicetify config current_theme hyprluggage color_scheme base &>/dev/null
        spicetify config inject_css 1 replace_colors 1 &>/dev/null

        if spicetify backup apply &>/dev/null; then
            ok "spicetify"
        else
            warn "spicetify: launch Spotify once, then run 'spicetify backup apply'"
        fi
    else
        warn "spicetify: install Spotify first, then re-run this script"
    fi
fi

# ── Greetd (Display Manager) ───────────────────────────────────────────────
if pkg_installed greetd; then
    # Resolve repo root (use $DOTFILES from install.sh if available, otherwise resolve from script location)
    if [[ -n "$DOTFILES" ]]; then
        DOTFILES_ROOT="$DOTFILES"
    else
        DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    GREETD_TEMPLATE="$DOTFILES_ROOT/install/greetd-config.toml"
    GREETD_CONFIG="/etc/greetd/config.toml"
    
    if [[ -f "$GREETD_TEMPLATE" ]]; then
        # Create greetd config directory (don't fail if it already exists)
        sudo mkdir -p /etc/greetd || true
        
        # Render template for the user running the installer
        # Use || true to prevent set -e from killing the script if sudo fails
        if sed "s/{{USER}}/$USER/g" "$GREETD_TEMPLATE" | sudo tee "$GREETD_CONFIG" >/dev/null; then
            sudo chown root:root "$GREETD_CONFIG" || warn "greetd: failed to set ownership"
            sudo chmod 644 "$GREETD_CONFIG" || warn "greetd: failed to set permissions"
            
            # Enable greetd service but DON'T start it (would logout current session)
            if sudo systemctl enable greetd &>/dev/null; then
                ok "greetd (enabled - will start on next boot)"
            else
                warn "greetd: failed to enable service"
            fi
        else
            warn "greetd: failed to write config file"
        fi
    else
        warn "greetd: template not found at $GREETD_TEMPLATE"
        # Still try to enable greetd if it's installed
        sudo systemctl enable --now greetd &>/dev/null && ok "greetd (no config)" || warn "greetd failed"
    fi
fi
