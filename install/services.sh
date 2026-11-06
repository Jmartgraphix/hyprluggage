#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| User Services       |-/ /--|#
#|/ /---+---------------------+/ /---|#

step "Setting up services"

# Ensure hardware stubs exist (safe if already written by install.sh / stow)
if [[ -x "$HOME/.local/bin/hyprluggage-hw-ensure" ]]; then
    "$HOME/.local/bin/hyprluggage-hw-ensure" ensure &>/dev/null || true
fi

# Resolve profile/gpu from env or saved state (desktop defaults)
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage"
HYPRLUGGAGE_PROFILE="${HYPRLUGGAGE_PROFILE:-}"
HYPRLUGGAGE_GPU="${HYPRLUGGAGE_GPU:-}"
[[ -z "$HYPRLUGGAGE_PROFILE" && -f "$STATE_DIR/profile" ]] && HYPRLUGGAGE_PROFILE=$(tr -d '[:space:]' <"$STATE_DIR/profile")
[[ -z "$HYPRLUGGAGE_GPU" && -f "$STATE_DIR/gpu" ]] && HYPRLUGGAGE_GPU=$(tr -d '[:space:]' <"$STATE_DIR/gpu")
HYPRLUGGAGE_PROFILE="${HYPRLUGGAGE_PROFILE:-desktop}"
HYPRLUGGAGE_GPU="${HYPRLUGGAGE_GPU:-other}"
info "Using profile=$HYPRLUGGAGE_PROFILE gpu=$HYPRLUGGAGE_GPU"

# ── Power Profile ─────────────────────────────────────────────────────────────
if command -v powerprofilesctl &>/dev/null; then
    if [[ "$HYPRLUGGAGE_PROFILE" == "laptop" ]]; then
        if compgen -G '/sys/class/power_supply/BAT*' >/dev/null 2>&1; then
            # Prefer balanced while on battery; performance on AC
            on_ac=false
            for adapter in /sys/class/power_supply/A{C,DP}*; do
                [[ -r "$adapter/online" ]] || continue
                [[ "$(cat "$adapter/online")" == "1" ]] && on_ac=true && break
            done
            if [[ "$on_ac" == true ]]; then
                powerprofilesctl set performance &>/dev/null && ok "power profile: performance (laptop AC)"
            else
                powerprofilesctl set balanced &>/dev/null && ok "power profile: balanced (laptop battery)"
            fi
        else
            powerprofilesctl set balanced &>/dev/null && ok "power profile: balanced (laptop)"
        fi
        # Ensure daemon is enabled on laptops
        sudo systemctl enable --now power-profiles-daemon &>/dev/null \
            && ok "power-profiles-daemon" \
            || warn "power-profiles-daemon: enable failed"
    else
        powerprofilesctl set performance &>/dev/null && ok "power profile: performance (desktop)"
    fi
fi

# ── Laptop: video group (brightnessctl) + logind lid ignore ───────────────────
if [[ "$HYPRLUGGAGE_PROFILE" == "laptop" ]]; then
    if ! id -nG "$USER" 2>/dev/null | grep -qw video; then
        sudo usermod -aG video "$USER" &>/dev/null \
            && ok "added $USER to video group (re-login for brightnessctl)" \
            || warn "video group: failed to add $USER"
    else
        ok "video group already set"
    fi

    # Resolve repo root for logind drop-in
    if [[ -n "${DOTFILES:-}" ]]; then
        DOTFILES_ROOT="$DOTFILES"
    else
        DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi
    LOGIND_SRC="$DOTFILES_ROOT/install/logind-laptop.conf"
    LOGIND_DST="/etc/systemd/logind.conf.d/hyprluggage-lid.conf"
    if [[ -f "$LOGIND_SRC" ]]; then
        sudo mkdir -p /etc/systemd/logind.conf.d
        if sudo cp "$LOGIND_SRC" "$LOGIND_DST"; then
            sudo chmod 644 "$LOGIND_DST" || true
            if sudo systemctl restart systemd-logind &>/dev/null; then
                ok "logind: lid handled by Hyprland (drop-in installed)"
            else
                warn "logind: drop-in installed; reboot recommended for lid handling"
            fi
            info "Lid close: suspend (undocked) or clamshell (external monitor)"
        else
            warn "logind: failed to install lid drop-in"
        fi
    else
        warn "logind: template missing at $LOGIND_SRC"
    fi
fi

# ── NVIDIA laptop: suspend/resume helpers ─────────────────────────────────────
if [[ "$HYPRLUGGAGE_PROFILE" == "laptop" && "$HYPRLUGGAGE_GPU" == "nvidia" ]]; then
    for unit in nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service; do
        if systemctl list-unit-files "$unit" &>/dev/null; then
            sudo systemctl enable "$unit" &>/dev/null \
                && ok "$unit" \
                || warn "$unit: enable failed"
        fi
    done
fi

# ── Bluetooth ──────────────────────────────────────────────────────────────────
if pkg_installed bluez; then
    sudo systemctl enable --now bluetooth &>/dev/null && ok "bluetooth" || warn "bluetooth failed"
fi

# ── Tray Applets / distro welcome ─────────────────────────────────────────────
# Disable blueman/nm-applet (waybar handles these). Hide CachyOS Hello from
# /etc/skel autostart so a fresh ISO user does not get it on every login.
mkdir -p ~/.config/autostart
for app in blueman nm-applet cachyos-hello; do
    if [[ -f "/etc/xdg/autostart/${app}.desktop" || -f "$HOME/.config/autostart/${app}.desktop" || -f "/etc/skel/.config/autostart/${app}.desktop" ]]; then
        printf '[Desktop Entry]\nHidden=true\n' >"$HOME/.config/autostart/${app}.desktop"
        ok "Disabled ${app} autostart"
    fi
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

# Keyring follows the greetd autologin choice below.
# Autologin gets an unlocked plaintext keyring. A password login unlocks an encrypted one.

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

        # Spicetify edits Spotify's files. A root-owned install gets group write
        # for the installing user, not write access for every account.
        if [[ ! -w "$spotify_path" ]] || [[ -d "$spotify_path/Apps" && ! -w "$spotify_path/Apps" ]]; then
            info "Spicetify needs write access to Spotify"
            if ! getent group spicetify >/dev/null; then
                sudo groupadd spicetify || warn "spicetify: failed to create group"
            fi
            if ! id -nG "$USER" 2>/dev/null | grep -qw spicetify; then
                sudo usermod -aG spicetify "$USER" \
                    && info "added $USER to spicetify" \
                    || warn "spicetify: failed to add $USER to the group"
            fi
            sudo chgrp spicetify "$spotify_path" 2>/dev/null
            sudo chmod g+w,o-w "$spotify_path" 2>/dev/null
            if [[ -d "$spotify_path/Apps" ]]; then
                sudo chgrp -R spicetify "$spotify_path/Apps" 2>/dev/null
                sudo chmod -R g+w,o-w "$spotify_path/Apps" 2>/dev/null
            fi
        fi

        mkdir -p "$(dirname "$prefs_path")"
        touch "$prefs_path"

        spicetify config spotify_path "$spotify_path" &>/dev/null
        spicetify config prefs_path "$prefs_path" &>/dev/null
        spicetify config spotify_launch_flags "--ozone-platform=wayland" &>/dev/null
        spicetify config current_theme hyprluggage color_scheme base &>/dev/null
        spicetify config inject_css 1 replace_colors 1 &>/dev/null

        # A group added in this run is not on the current shell yet. sg picks it up.
        apply_ok=false
        if id -nG | grep -qw spicetify; then
            spicetify backup apply &>/dev/null && apply_ok=true
        elif getent group spicetify 2>/dev/null | grep -qw "$USER"; then
            sg spicetify -c "spicetify backup apply" &>/dev/null && apply_ok=true
        else
            spicetify backup apply &>/dev/null && apply_ok=true
        fi
        if [[ "$apply_ok" == true ]]; then
            ok "spicetify"
        else
            warn "spicetify: launch Spotify once, then run 'spicetify backup apply'"
        fi
    else
        warn "spicetify: install Spotify first, then re-run this script"
    fi
fi

# Unlock the login keyring with the greetd password. Does not rewrite an existing keyring file.
enable_gnome_keyring_pam() {
    local pam="/etc/pam.d/greetd"
    local tmp
    if [[ -f "$pam" ]] && ! grep -q 'pam_gnome_keyring\.so' "$pam"; then
        tmp="$(mktemp)"
        awk '
            { print }
            $1 == "auth" && $2 == "include" && $3 == "system-local-login" {
                print "auth       optional     pam_gnome_keyring.so"
            }
            $1 == "session" && $2 == "include" && $3 == "system-local-login" {
                print "session    optional     pam_gnome_keyring.so auto_start"
            }
        ' "$pam" >"$tmp"
        if grep -q 'pam_gnome_keyring\.so' "$tmp"; then
            sudo cp "$tmp" "$pam"
            sudo chmod 644 "$pam"
            ok "keyring: unlocks with the login password"
        else
            warn "greetd: could not add pam_gnome_keyring"
        fi
        rm -f "$tmp"
    elif [[ -f "$pam" ]]; then
        ok "keyring: unlocks with the login password"
    fi

    pam="/etc/pam.d/passwd"
    if [[ -f "$pam" ]] && ! grep -q 'pam_gnome_keyring\.so' "$pam"; then
        tmp="$(mktemp)"
        awk '
            { print }
            $1 == "password" && $2 == "include" && $3 == "system-auth" {
                print "password\toptional\tpam_gnome_keyring.so"
            }
        ' "$pam" >"$tmp"
        if grep -q 'pam_gnome_keyring\.so' "$tmp"; then
            sudo cp "$tmp" "$pam"
            sudo chmod 644 "$pam"
        fi
        rm -f "$tmp"
    fi

    if [[ -f "$HOME/.local/share/keyrings/Default_keyring.keyring" ]]; then
        info "Leaving the existing keyring file in place."
    fi
}

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
        # System-wide session wrapper so greetd does not depend on ~/.local/bin stow
        SESSION_SRC="$DOTFILES_ROOT/.local/bin/hyprluggage-session"
        if [[ -f "$SESSION_SRC" ]]; then
            sudo install -Dm755 "$SESSION_SRC" /etc/greetd/hyprluggage-session \
                && ok "hyprluggage-session → /etc/greetd" \
                || warn "failed to install /etc/greetd/hyprluggage-session"
            sudo install -Dm755 "$SESSION_SRC" /usr/local/bin/hyprluggage-session || true
        fi

        TUIGREET_SRC="$DOTFILES_ROOT/install/tuigreet-config.toml"
        if [[ -f "$TUIGREET_SRC" ]]; then
            sudo mkdir -p /etc/tuigreet
            sudo install -Dm644 "$TUIGREET_SRC" /etc/tuigreet/config.toml \
                && ok "tuigreet config" \
                || warn "failed to install /etc/tuigreet/config.toml"
        fi

        # Create greetd config directory (don't fail if it already exists)
        sudo mkdir -p /etc/greetd || true
        
        # Desktop (streaming box) defaults to autologin. Laptop defaults to the greeter.
        # Idle lock is unchanged either way.
        want_autologin=no
        [[ "${HYPRLUGGAGE_PROFILE:-desktop}" != "laptop" ]] && want_autologin=yes
        if [[ -t 0 && -t 1 ]]; then
            autologin_prompt="Log in automatically at boot?"
            [[ "$want_autologin" == yes ]] && autologin_prompt="$autologin_prompt Recommended for a streaming box."
            autologin_prompt="$autologin_prompt Saved passwords will sit unencrypted."
            if confirm_default "$autologin_prompt" "$want_autologin"; then
                want_autologin=yes
            else
                want_autologin=no
            fi
        fi
        mkdir -p "$STATE_DIR"
        printf '%s\n' "$want_autologin" >"$STATE_DIR/autologin"

        if pkg_installed gnome-keyring; then
            if [[ "$want_autologin" == yes ]]; then
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
                    ok "keyring: unencrypted (autologin)"
                else
                    ok "keyring: unencrypted (already present)"
                fi
            else
                enable_gnome_keyring_pam
            fi
        fi

        # Render template for the user running the installer.
        # Drop [initial_session] when autologin is declined so tuigreet shows.
        greetd_rendered="$(sed "s/{{USER}}/$USER/g" "$GREETD_TEMPLATE")"
        if [[ "$want_autologin" != yes ]]; then
            greetd_rendered="$(printf '%s\n' "$greetd_rendered" | awk '
                /^\[initial_session\]/ { skip=1; next }
                /^\[/ { skip=0 }
                skip { next }
                { print }
            ')"
        fi
        if printf '%s\n' "$greetd_rendered" | sudo tee "$GREETD_CONFIG" >/dev/null; then
            if [[ "$want_autologin" == yes ]]; then
                ok "greetd: autologin"
            else
                ok "greetd: tuigreet login"
            fi
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

# ── wayvnc + VNC Hyprland mod (browser remote / Gatwy) ─────────────────
# Super is often blocked in browsers; hypr-vnc-mod loads Ctrl+Alt twins while clients are connected.
if command -v wayvnc &>/dev/null || pkg_installed wayvnc 2>/dev/null; then
    # Ensure PATH scripts exist (stow) and seed conf
    if [[ -x "$HOME/.local/bin/hypr-vnc-mod" ]]; then
        "$HOME/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    fi
    if systemctl --user daemon-reload &>/dev/null; then
        # Older installs used WantedBy=default.target + Wants=graphical-session.target,
        # which left an empty graphical session active and made uwsm/greetd refuse to start.
        systemctl --user disable wayvnc.service wayvnc-clipboard-bridge.service &>/dev/null || true
        systemctl --user daemon-reload &>/dev/null || true
        systemctl --user enable wayvnc.service wayvnc-clipboard-bridge.service &>/dev/null \
            && ok "wayvnc + vnc-mod bridge (with graphical session)" \
            || warn "wayvnc: enable failed (after login: systemctl --user enable wayvnc wayvnc-clipboard-bridge)"
        if systemctl --user is-active -q graphical-session.target; then
            systemctl --user start wayvnc.service wayvnc-clipboard-bridge.service &>/dev/null || true
        fi
    else
        warn "wayvnc: systemd --user not available yet (enable after first graphical login)"
    fi
else
    info "wayvnc not installed — skip remote desktop services"
fi

# ── Sunshine Hyprland mod (Moonlight) ──────────────────────────────────
# Super is often missing on Moonlight clients; same Ctrl+Alt twins as VNC.
if command -v sunshine &>/dev/null || pkg_installed sunshine 2>/dev/null; then
    if [[ -x "$HOME/.local/bin/hypr-vnc-mod" ]]; then
        "$HOME/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    fi
    if systemctl --user daemon-reload &>/dev/null; then
        systemctl --user enable sunshine-mod-bridge.service &>/dev/null \
            && ok "sunshine-mod-bridge (Ctrl+Alt Super twins)" \
            || warn "sunshine-mod-bridge: enable failed (after login: systemctl --user enable sunshine-mod-bridge)"
        if systemctl --user is-active -q graphical-session.target; then
            systemctl --user start sunshine-mod-bridge.service &>/dev/null || true
        fi
    else
        warn "sunshine-mod-bridge: systemd --user not available yet (enable after first graphical login)"
    fi
else
    info "sunshine not installed — skip Sunshine Ctrl+Alt Super twins"
fi

# ── SSH ──────────────────────────────────────────────────────────────────────
# Opt-in. A yes writes the keys-only drop-in and enables sshd. A no on a
# terminal disables it. A non-interactive run leaves the service alone.
if pkg_installed openssh; then
    want_sshd=no
    if [[ -t 0 && -t 1 ]]; then
        if confirm_default "Enable SSH? Password login will be turned off. Use an SSH key." no; then
            want_sshd=yes
        fi
    fi

    if [[ -n "${DOTFILES:-}" ]]; then
        DOTFILES_ROOT="$DOTFILES"
    else
        DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    fi

    if [[ "$want_sshd" == yes ]]; then
        SSHD_SRC="$DOTFILES_ROOT/install/sshd-hyprluggage.conf"
        SSHD_DST="/etc/ssh/sshd_config.d/hyprluggage.conf"
        if [[ -f "$SSHD_SRC" ]]; then
            sudo mkdir -p /etc/ssh/sshd_config.d
            if sudo cp "$SSHD_SRC" "$SSHD_DST"; then
                sudo chmod 644 "$SSHD_DST" || true
                ok "sshd: keys only"
            else
                warn "sshd: failed to install drop-in"
            fi
        else
            warn "sshd: drop-in missing at $SSHD_SRC"
        fi
        if sudo sshd -t; then
            if sudo systemctl enable --now sshd &>/dev/null; then
                sudo systemctl reload sshd &>/dev/null || true
                ok "sshd"
            else
                warn "sshd failed"
            fi
        else
            warn "sshd: config test failed; service left unchanged"
        fi
    elif [[ -t 0 && -t 1 ]]; then
        if systemctl is-enabled --quiet sshd; then
            sudo systemctl disable --now sshd &>/dev/null \
                && ok "sshd: disabled" \
                || warn "sshd: disable failed"
        else
            ok "sshd: not enabled"
        fi
    else
        info "sshd: not asked; leaving the service as it is"
    fi
fi

# ── Firewall (ufw) ───────────────────────────────────────────────────────────
# Do not add an unrestricted 5900 allow. wayvnc has no RFB auth, and Gatwy/noVNC
# cannot complete wayvnc's TLS auth, so VNC stays limited to explicit source rules.
# LocalSend, KDE Connect, and Steam Remote Play are added for the connected IPv4 LAN only.
if pkg_installed ufw && command -v ufw &>/dev/null; then
    ufw_was_active=false
    if sudo ufw status 2>/dev/null | grep -qi "Status: active"; then
        ufw_was_active=true
    fi
    lan_cidr="$(ip -4 route show scope link 2>/dev/null | awk '/proto kernel/ {print $1; exit}')"
    [[ -n "$lan_cidr" ]] || lan_cidr="192.168.0.0/16"
    sudo ufw allow 22/tcp &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 53317 proto tcp comment "localsend lan" &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 53317 proto udp comment "localsend lan" &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 27036:27037 proto tcp comment "steam remote play lan" &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 27031:27036 proto udp comment "steam remote play lan" &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 1714:1764 proto tcp comment "kdeconnect lan" &>/dev/null || true
    sudo ufw allow from "$lan_cidr" to any port 1714:1764 proto udp comment "kdeconnect lan" &>/dev/null || true
    if [[ "$HYPRLUGGAGE_PROFILE" == "laptop" ]]; then
        sudo ufw --force enable &>/dev/null \
            && ok "ufw: enabled (ssh; localsend, kdeconnect, and steam remote play from $lan_cidr)" \
            || warn "ufw: enable failed"
    elif [[ "$ufw_was_active" == true ]]; then
        sudo ufw --force enable &>/dev/null \
            && ok "ufw: localsend, kdeconnect, and steam remote play from $lan_cidr (kept enabled)" \
            || warn "ufw: rules may not have applied"
    else
        ok "ufw: localsend, kdeconnect, and steam remote play from $lan_cidr (left inactive)"
    fi
    info "wayvnc port 5900 is not opened by the installer; add a source-limited allow for Gatwy"
fi
