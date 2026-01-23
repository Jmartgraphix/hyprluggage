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

# Try stow with better error reporting
# Write error to file immediately so error handler can read it
stow_output=$(stow . 2>&1)
stow_exit=$?

# Always write output to log for debugging
echo "=== Stow execution at $(date) ===" >> /tmp/stow-debug.log
echo "Exit code: $stow_exit" >> /tmp/stow-debug.log
echo "Output:" >> /tmp/stow-debug.log
echo "$stow_output" >> /tmp/stow-debug.log
echo "---" >> /tmp/stow-debug.log

if [[ $stow_exit -ne 0 ]]; then
    # Save error to log file (for error handler to read)
    echo "$stow_output" > /tmp/stow-error.log
    echo "Stow failed with exit code: $stow_exit" >> /tmp/stow-debug.log
    
    # Also write to stderr so it's visible before error handler clears screen
    err "Stow failed (exit code: $stow_exit):" >&2
    echo >&2
    echo "$stow_output" | head -20 >&2
    echo >&2
    err "Common causes:" >&2
    info "  - Conflicting files/directories in ~/.config or ~/.local/share" >&2
    info "  - Permission issues" >&2
    info "  - Missing parent directories" >&2
    echo >&2
    info "Full error saved to: /tmp/stow-error.log" >&2
    info "Debug log: /tmp/stow-debug.log" >&2
    info "Try manually removing conflicting items or check the error above" >&2
    exit 1
else
    echo "Stow succeeded, entering else branch" >> /tmp/stow-debug.log
    ok "Hyprluggage linked" || { echo "ok() function failed" >> /tmp/stow-debug.log; exit 1; }
    echo "ok() function succeeded" >> /tmp/stow-debug.log
    rm -f /tmp/stow-error.log || { echo "rm failed" >> /tmp/stow-debug.log; exit 1; }
    echo "rm succeeded" >> /tmp/stow-debug.log
fi

echo "After if/else block" >> /tmp/stow-debug.log
[[ -d "$BACKUP_DIR" ]] && info "Your old configs: $BACKUP_DIR" || echo "backup_dir check/info failed" >> /tmp/stow-debug.log
echo "End of stow.sh script" >> /tmp/stow-debug.log
