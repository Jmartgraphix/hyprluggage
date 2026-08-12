#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Installer           |-/ /--|#
#|/ /---+---------------------+/ /---|#

set -e

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
source "$DOTFILES/install/utils.sh"

# Banner
clear
show_banner
echo

# Existing install warning
[[ -d "$HOME/.config/hyprluggage" ]] && warn "Existing installation detected"

warn "This will install packages and modify your configs."
echo
confirm "Continue?" || exit 0

# ── Hardware profile (desktop vs laptop) + GPU overlay ───────────────────────
step "Hardware profile"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage"
mkdir -p "$STATE_DIR"

# Prefer already-linked ensure, else repo copy
HW_ENSURE=""
if [[ -x "$HOME/.local/bin/hyprluggage-hw-ensure" ]]; then
    HW_ENSURE="$HOME/.local/bin/hyprluggage-hw-ensure"
elif [[ -x "$DOTFILES/.local/bin/hyprluggage-hw-ensure" ]]; then
    HW_ENSURE="$DOTFILES/.local/bin/hyprluggage-hw-ensure"
fi

detect_form=desktop
compgen -G '/sys/class/power_supply/BAT*' >/dev/null 2>&1 && detect_form=laptop
detect_gpu=other
lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | grep -qi nvidia && detect_gpu=nvidia

saved_profile=""
[[ -f "$STATE_DIR/profile" ]] && saved_profile=$(tr -d '[:space:]' <"$STATE_DIR/profile")

if [[ -n "$saved_profile" ]]; then
    info "Saved profile: $saved_profile (detected default: $detect_form)"
    if confirm "Keep hardware profile '$saved_profile'?"; then
        HYPRLUGGAGE_PROFILE="$saved_profile"
    else
        choice=$(choose "Install profile:" "Desktop" "Laptop")
        case "$choice" in
            Laptop) HYPRLUGGAGE_PROFILE=laptop ;;
            *) HYPRLUGGAGE_PROFILE=desktop ;;
        esac
    fi
else
    info "Detected: $detect_form form factor, GPU=$detect_gpu"
    default_label="Desktop"
    [[ "$detect_form" == "laptop" ]] && default_label="Laptop"
    choice=$(choose "Install profile (detected: $default_label):" "Desktop" "Laptop")
    case "$choice" in
        Laptop) HYPRLUGGAGE_PROFILE=laptop ;;
        *) HYPRLUGGAGE_PROFILE=desktop ;;
    esac
fi

HYPRLUGGAGE_GPU="$detect_gpu"
saved_gpu=""
[[ -f "$STATE_DIR/gpu" ]] && saved_gpu=$(tr -d '[:space:]' <"$STATE_DIR/gpu")
if [[ -n "$saved_gpu" && "$saved_gpu" != "$detect_gpu" ]]; then
    info "Saved GPU overlay: $saved_gpu (detected: $detect_gpu)"
    if confirm "Keep saved GPU overlay '$saved_gpu'?"; then
        HYPRLUGGAGE_GPU="$saved_gpu"
    fi
fi

if [[ -n "$HW_ENSURE" ]]; then
    "$HW_ENSURE" set "$HYPRLUGGAGE_PROFILE" "$HYPRLUGGAGE_GPU"
else
    # Fallback if ensure binary not present yet (pre-stow)
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$HYPRLUGGAGE_PROFILE" >"$STATE_DIR/profile"
    printf '%s\n' "$HYPRLUGGAGE_GPU" >"$STATE_DIR/gpu"
    printf '# Managed by install.sh — form factor: %s\nsource = %s/.config/hypr/profiles/%s.conf\n' \
        "$HYPRLUGGAGE_PROFILE" "$HOME" "$HYPRLUGGAGE_PROFILE" >"$STATE_DIR/profile.conf"
    if [[ "$HYPRLUGGAGE_GPU" == "nvidia" ]]; then
        printf '# Managed by install.sh — GPU: nvidia\nsource = %s/.config/hypr/profiles/nvidia.conf\n' \
            "$HOME" >"$STATE_DIR/gpu.conf"
    else
        printf '# Managed by install.sh — no NVIDIA GPU overlay\n' >"$STATE_DIR/gpu.conf"
    fi
fi
export HYPRLUGGAGE_PROFILE HYPRLUGGAGE_GPU
ok "profile=$HYPRLUGGAGE_PROFILE gpu=$HYPRLUGGAGE_GPU"

# Check core dependencies
step "Checking dependencies"
missing=()
for dep in git stow; do
    pkg_installed "$dep" && ok "$dep" || { err "$dep"; missing+=("$dep"); }
done

if [[ ${#missing[@]} -gt 0 ]]; then
    echo
    err "Missing: ${missing[*]}"
    info "Run: sudo pacman -S ${missing[*]}"
    exit 1
fi

# Install packages
source "$DOTFILES/install/packages.sh"

# Symlink dotfiles
source "$DOTFILES/install/stow.sh"

# Setup desktop entries
source "$DOTFILES/install/desktop-entries.sh"

# Enable user services
source "$DOTFILES/install/services.sh"

# Choose default shell
echo
"$DOTFILES/scripts/choose-shell"

# Remove any stale first-run marker (fresh installs should run first-run)
rm -f ~/.local/state/hyprluggage/first-run-done

# Install themes (skip logo since we already showed banner)
HYPRLUGGAGE_INSTALLING=1 "$DOTFILES/install/themes/install.sh"

# Done
echo
ok "Installation complete"
info "Log out and back in for changes to take effect"
info "Run 'hyprluggage help' to get started"
echo
