#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Stow Symlinks       |-/ /--|#
#|/ /---+---------------------+/ /---|#

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Backup dir: dotfiles-backup, dotfiles-backup-2, etc.
BACKUP_DIR="$HOME/dotfiles-backup"
i=2; while [[ -d "$BACKUP_DIR" ]]; do BACKUP_DIR="$HOME/dotfiles-backup-$i"; ((i++)); done

step "Linking hyprluggage"
cd "$DOTFILES" || exit 1

# Clean stale symlinks from older installs
for f in "$HOME"/*; do
    [[ -L "$f" ]] || continue
    target="$(readlink "$f")"
    # Remove symlinks to install scripts or root-level files that shouldn't be linked
    [[ "$target" == hyprluggage/install/* || "$target" == hyprluggage/*.md || "$target" == hyprluggage/*.sh ]] && rm "$f"
done

# update-cursor runs as root. On a new account, mkdir leaves
# ~/.local/share/applications owned by root. Renaming that directory needs
# write permission on it, so the backup mv below used to abort the install
# with "Permission denied". Hand those directories back to the desktop user.
reclaim_root_owned() {
    local dir="$1"
    local recursive="${2:-}"
    [[ -d "$dir" && ! -L "$dir" ]] || return 0
    [[ "$(stat -c '%u' "$dir")" -eq 0 ]] || return 0
    info "Reclaiming root-owned directory: $dir"
    if [[ "$recursive" == "-R" ]]; then
        sudo chown -R "$(id -un):$(id -gn)" -- "$dir"
    else
        sudo chown "$(id -un):$(id -gn)" -- "$dir"
    fi
}

reclaim_root_owned "$HOME/.local"
reclaim_root_owned "$HOME/.local/share"
reclaim_root_owned "$HOME/.local/share/applications" -R
reclaim_root_owned "$HOME/.cursor" -R
reclaim_root_owned "$HOME/.config"

# Prevent stow from symlinking ~/.config itself
mkdir -p "$HOME/.config" "$HOME/.local/share" "$HOME/.local/bin"

# Create directories needed by scripts
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Wallpapers"
mkdir -p "$HOME/Scripts"      # For nvim dashboard "Browse scripts"
mkdir -p "$HOME/Projects"     # For nvim dashboard "Projects"

# Backup existing configs so stow creates clean directory symlinks
backup_if_exists() {
    local source_dir="$DOTFILES/$1"
    local target_dir="$2"
    
    # Only process if source directory exists in dotfiles
    [[ -d "$source_dir" ]] || return 0
    
    for item in "$source_dir"/*; do
        [[ -e "$item" ]] || continue
        local name
        name=$(basename "$item")
        # Not stowed (.stow-local-ignore). desktop-entries.sh copies files
        # into the live directory. Moving it throws away launchers and is
        # what aborted a new VM install when the directory was root-owned.
        [[ "$1/$name" == ".local/share/applications" ]] && continue
        local target="$target_dir/$name"
        [[ -e "$target" && ! -L "$target" ]] || continue
        mkdir -p "$BACKUP_DIR/$1"
        mv "$target" "$BACKUP_DIR/$1/$name"
        info "Backed up: $1/$name"
    done
}

backup_if_exists ".config" "$HOME/.config"
backup_if_exists ".local/share" "$HOME/.local/share"
backup_if_exists ".local/bin" "$HOME/.local/bin"

# Try stow with better error reporting
stow_output=$(stow . 2>&1)
stow_exit=$?

if [[ $stow_exit -ne 0 ]]; then
    # Save error to log file (for error handler to read)
    echo "$stow_output" > /tmp/stow-error.log
    
    err "Stow failed:"
    echo
    echo "$stow_output" | head -20
    echo
    err "Common causes:"
    info "  - Conflicting files/directories in ~/.config or ~/.local/share"
    info "  - Permission issues"
    info "  - Missing parent directories"
    echo
    info "Full error saved to: /tmp/stow-error.log"
    info "Try manually removing conflicting items or check the error above"
    exit 1
else
    ok "Hyprluggage linked"
    rm -f /tmp/stow-error.log
    # Hardware profile + GPU stubs (must exist before Hyprland sources them)
    if [[ -x "$HOME/.local/bin/hyprluggage-hw-ensure" ]]; then
        "$HOME/.local/bin/hyprluggage-hw-ensure" ensure &>/dev/null || true
    elif [[ -x "$DOTFILES/.local/bin/hyprluggage-hw-ensure" ]]; then
        "$DOTFILES/.local/bin/hyprluggage-hw-ensure" ensure &>/dev/null || true
    fi
    # VNC active stub lives outside stow; create before Hyprland sources it
    if [[ -x "$HOME/.local/bin/hypr-vnc-mod" ]]; then
        "$HOME/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    elif [[ -x "$DOTFILES/.local/bin/hypr-vnc-mod" ]]; then
        "$DOTFILES/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    fi
    # Hyprlock logo (hyprlock.conf cannot call hyprluggage-dir)
    mkdir -p "$HOME/.config/hyprluggage"
    if [[ -f "$DOTFILES/assets/luggage_open.png" ]]; then
        ln -sfn "$DOTFILES/assets/luggage_open.png" "$HOME/.config/hyprluggage/luggage_open.png"
    fi
    # Matugen rewrites themes/dynamic/.config and .cache (gitignored).
    # Copy any missing file from themes/dynamic/baseline.
    if [[ -f "$DOTFILES/install/themes/dynamic-seed.sh" ]]; then
        # shellcheck disable=SC1091
        source "$DOTFILES/install/themes/dynamic-seed.sh"
        ensure_dynamic_seed "$DOTFILES"
    fi
    # mako/config is untracked; the theme hook (hooks/10-mako.sh) owns it.
    # Seed it from the current theme, or dynamic, if it is missing.
    if [[ ! -e "$HOME/.config/mako/config" ]]; then
        mako_src="$HOME/.config/hyprluggage/current/.config/mako/config"
        [[ -f "$mako_src" ]] || mako_src="$DOTFILES/themes/dynamic/.config/mako/config"
        if [[ -f "$mako_src" ]]; then
            mkdir -p "$HOME/.config/mako"
            ln -sfn "$(readlink -f "$mako_src")" "$HOME/.config/mako/config"
            pgrep -x mako &>/dev/null && makoctl reload 2>/dev/null || true
        fi
    fi
fi

# Show backup location if backups were created
if [[ -d "$BACKUP_DIR" ]]; then
    info "Your old configs: $BACKUP_DIR"
fi
