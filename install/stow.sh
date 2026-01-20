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
mkdir -p "$HOME/.config" "$HOME/.local/share"

# Create directories needed by scripts
mkdir -p "$HOME/Pictures/Screenshots"
mkdir -p "$HOME/Wallpapers"
mkdir -p "$HOME/Scripts"      # For nvim dashboard "Browse scripts"
mkdir -p "$HOME/Projects"     # For nvim dashboard "Projects"

# Backup existing configs so stow creates clean directory symlinks
backup_if_exists() {
    for item in "$1"/*; do
        [[ -e "$item" ]] || continue
        local name=$(basename "$item")
        local target="$2/$name"
        [[ -e "$target" && ! -L "$target" ]] || continue
        mkdir -p "$BACKUP_DIR/$1"
        mv "$target" "$BACKUP_DIR/$1/$name"
        info "Backed up: $1/$name"
    done
}

backup_if_exists ".config" "$HOME/.config"
backup_if_exists ".local/share" "$HOME/.local/share"

if stow . 2>/dev/null; then
    ok "Hyprluggage linked"
else
    err "Stow failed:"
    stow -v . 2>&1 | head -5
    exit 1
fi

[[ -d "$BACKUP_DIR" ]] && info "Your old configs: $BACKUP_DIR"
