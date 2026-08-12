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
cd "$DOTFILES"

# Clean stale symlinks from older installs
for f in "$HOME"/*; do
    [[ -L "$f" ]] || continue
    target="$(readlink "$f")"
    # Remove symlinks to install scripts or root-level files that shouldn't be linked
    [[ "$target" == hyprluggage/install/* || "$target" == hyprluggage/*.md || "$target" == hyprluggage/*.sh ]] && rm "$f"
done

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
        local name=$(basename "$item")
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
    # VNC active stub lives outside stow; create before Hyprland sources it
    if [[ -x "$HOME/.local/bin/hypr-vnc-mod" ]]; then
        "$HOME/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    elif [[ -x "$DOTFILES/.local/bin/hypr-vnc-mod" ]]; then
        "$DOTFILES/.local/bin/hypr-vnc-mod" ensure &>/dev/null || true
    fi
fi

# Show backup location if backups were created
if [[ -d "$BACKUP_DIR" ]]; then
    info "Your old configs: $BACKUP_DIR"
fi
