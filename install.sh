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

# ── Hardware profile (desktop / laptop / vm) + GPU overlay ───────────────────
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

# Detect form factor. Desktop and laptop stay the existing defaults;
# VMs are an extra option so virt guests are not treated as gaming NVIDIA boxes.
detect_form=desktop
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt -q; then
    detect_form=vm
elif grep -q hypervisor /proc/cpuinfo 2>/dev/null; then
    detect_form=vm
elif compgen -G '/sys/class/power_supply/BAT*' >/dev/null 2>&1; then
    detect_form=laptop
fi
detect_gpu=other
if [[ "$detect_form" != "vm" ]] && lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | grep -qi nvidia; then
    detect_gpu=nvidia
fi

profile_from_label() {
    case "$1" in
        Laptop) printf 'laptop\n' ;;
        "Virtual machine") printf 'vm\n' ;;
        *) printf 'desktop\n' ;;
    esac
}

choose_profile() {
    local prompt="$1"
    local choice
    # Put the detected option first so the numbered/gum default matches detection.
    case "$detect_form" in
        laptop) choice=$(choose "$prompt" "Laptop" "Desktop" "Virtual machine") ;;
        vm)     choice=$(choose "$prompt" "Virtual machine" "Desktop" "Laptop") ;;
        *)      choice=$(choose "$prompt" "Desktop" "Laptop" "Virtual machine") ;;
    esac
    profile_from_label "$choice"
}

saved_profile=""
[[ -f "$STATE_DIR/profile" ]] && saved_profile=$(tr -d '[:space:]' <"$STATE_DIR/profile")

if [[ -n "$saved_profile" ]]; then
    info "Saved profile: $saved_profile (detected default: $detect_form)"
    if confirm "Keep hardware profile '$saved_profile'?"; then
        HYPRLUGGAGE_PROFILE="$saved_profile"
    else
        HYPRLUGGAGE_PROFILE=$(choose_profile "Install profile:")
    fi
else
    info "Detected: $detect_form form factor, GPU=$detect_gpu"
    default_label="Desktop"
    [[ "$detect_form" == "laptop" ]] && default_label="Laptop"
    [[ "$detect_form" == "vm" ]] && default_label="Virtual machine"
    HYPRLUGGAGE_PROFILE=$(choose_profile "Install profile (detected: $default_label):")
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
