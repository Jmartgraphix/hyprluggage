#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Theme Importer      |-/ /--|#
#|/ /---+---------------------+/ /---|#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(dirname "$(dirname "$(dirname "$SCRIPT_DIR")")")"
THEMES_DIR="$DOTFILES/themes"

source "$SCRIPT_DIR/init.sh"
source "$SCRIPT_DIR/terminals.sh"
source "$SCRIPT_DIR/hyprland.sh"
source "$SCRIPT_DIR/waybar.sh"
source "$SCRIPT_DIR/rofi.sh"
source "$SCRIPT_DIR/gtk.sh"
source "$SCRIPT_DIR/btop.sh"
source "$SCRIPT_DIR/cava.sh"
source "$SCRIPT_DIR/wal.sh"
source "$SCRIPT_DIR/yazi.sh"
source "$SCRIPT_DIR/rmpc.sh"
source "$SCRIPT_DIR/starship.sh"
source "$SCRIPT_DIR/vesktop.sh"
source "$SCRIPT_DIR/obsidian.sh"
source "$SCRIPT_DIR/spicetify.sh"
source "$SCRIPT_DIR/mako.sh"
source "$SCRIPT_DIR/nvim.sh"

write_configs() {
    local theme_name="$1" theme_dest="$2" theme_bg="$3" theme_fg="$4"; shift 4
    local c=("$@")
    
    # export as globals for gen_* functions
    name="$theme_name"
    dest="$theme_dest"
    bg="$theme_bg"
    fg="$theme_fg"
    
    [[ -z "$bg" ]] && bg="#0f0f0f"
    [[ -z "$fg" ]] && fg="#e0e0e0"
    
    black=${c[0]:-$bg} red=${c[1]:-#cc6666} green=${c[2]:-#b5bd68}
    yellow=${c[3]:-#f0c674} blue=${c[4]:-#81a2be} magenta=${c[5]:-#b294bb}
    cyan=${c[6]:-#8abeb7} white=${c[7]:-#c5c8c6} bblack=${c[8]:-#969896}
    bred=${c[9]:-$red} bgreen=${c[10]:-$green} byellow=${c[11]:-$yellow}
    bblue=${c[12]:-$blue} bmagenta=${c[13]:-$magenta} bcyan=${c[14]:-$cyan}
    bwhite=${c[15]:-#ffffff}
    accent=$blue
    # Hyprluggage's bar, GTK theme, and shadows are dark. A light Aether
    # palette would paint dark text on the dark bar and white shadows.
    if (( $(luminance "$bg") > $(luminance "$fg") )); then
        local swap=$bg
        bg=$fg
        fg=$swap
        swap=$black
        black=$white
        white=$swap
    fi
    surface=$(lighten "$bg" 20)
    
    gen_terminals
    gen_hyprland
    gen_waybar
    gen_rofi
    gen_gtk
    gen_btop
    gen_cava
    gen_wal
    gen_yazi
    gen_rmpc
    gen_starship
    gen_vesktop
    gen_obsidian
    gen_spicetify
    gen_mako
}

prepare_theme_dirs() {
    local dest="$1"
    mkdir -p "$dest"/{backgrounds,.cache/wal}
    mkdir -p "$dest/.config"/{alacritty,btop/themes,cava,ghostty,gtk-3.0,gtk-4.0,hypr/theme,kitty,mako,nvim,obsidian,rmpc/themes,rofi,spicetify/Themes/hyprluggage,vesktop/themes,waybar,yazi}
}

copy_wallpapers() {
    local src="$1" dest="$2" f wall
    if [[ -d "$src/backgrounds" ]]; then
        cp -a "$src/backgrounds/." "$dest/backgrounds/" 2>/dev/null || true
    fi
    shopt -s nullglob
    for f in "$src"/background*.{jpg,jpeg,png,webp}; do
        [[ -f "$f" ]] && cp "$f" "$dest/backgrounds/"
    done
    shopt -u nullglob
    wall=$(find "$dest/backgrounds" -type f 2>/dev/null | sort -V | head -1)
    [[ -n "$wall" ]] && ln -sfn "backgrounds/${wall##*/}" "$dest/wallpaper"
    return 0
}

copy_overrides() {
    local src="$1" dest="$2"
    [[ -f "$src/btop.theme" ]] && cp "$src/btop.theme" "$dest/.config/btop/themes/current.theme"
    [[ -f "$src/neovim.lua" ]] && cp "$src/neovim.lua" "$dest/.config/nvim/theme.lua"
    [[ -f "$src/mako" ]] && cp "$src/mako" "$dest/.config/mako/config"
    [[ -f "$src/.config/mako/config" ]] && cp "$src/.config/mako/config" "$dest/.config/mako/config"
    [[ -f "$src/mako.ini" ]] && cp "$src/mako.ini" "$dest/.config/mako/config"
    return 0
}

activate_theme() {
    local name="$1"
    local parent_script
    parent_script="$(dirname "$SCRIPT_DIR")/hyprluggage"
    if [[ "$(cat "$HOME/.config/hyprluggage/.current-theme" 2>/dev/null)" == "$name" ]]; then
        "$parent_script" reload
    else
        "$parent_script" switch "$name"
    fi
}

# Rebuild themes/<name> from a directory that has kitty.conf, alacritty.toml, or colors.toml.
# kind=aether ignores Aether's app templates and writes Hyprluggage's own btop, mako, and neovim.
build_theme() {
    local name="$1" src="$2" kind="${3:-import}"
    local dest="$THEMES_DIR/$name"
    local colors bg fg
    local palette

    colors=$(get_colors "$src") || { err "no kitty.conf or alacritty.toml found"; exit 1; }
    read -ra C <<< "$colors"
    bg="${C[0]}"
    fg="${C[1]}"
    palette=("${C[@]:2}")
    [[ -z "$bg" || -z "$fg" ]] && { err "no colors in $src"; exit 1; }

    info "creating $name..."
    rm -rf "$dest"
    prepare_theme_dirs "$dest"
    copy_wallpapers "$src" "$dest"
    write_configs "$name" "$dest" "$bg" "$fg" "${palette[@]}"
    if [[ "$kind" == "aether" ]]; then
        gen_nvim
    else
        copy_overrides "$src" "$dest"
    fi
}

run_import() {
    local url="$1"
    [[ -z "$url" ]] && { err "usage: hyprluggage import <url|user/repo>"; exit 1; }
    
    [[ "$url" =~ ^https?:// ]] || url="https://github.com/$url"
    url="${url%.git}"
    
    local name dest
    name=$(basename "$url" | sed 's/^omarchy-//; s/^omakub-//; s/-theme$//; s/-omarchy$//' | tr '[:upper:]' '[:lower:]')
    name="$name (omarchy)"
    dest="$THEMES_DIR/$name"
    
    if [[ -d "$dest" ]]; then
        printf 'theme "%s" exists. overwrite? [y/N] ' "$name"
        read -r ans
        [[ "$ans" == "y" ]] || exit 0
    fi
    
    local tmp="/tmp/hyprluggage-import.$$"
    trap 'rm -rf "$tmp"' EXIT
    
    info "cloning $url..."
    git clone --depth 1 --quiet "$url" "$tmp/repo" || { err "clone failed"; exit 1; }
    
    info "extracting colors..."
    build_theme "$name" "$tmp/repo"
    ok "imported $name"
    activate_theme "$name"
}

source "$SCRIPT_DIR/aether.sh"

case "${1:-}" in
    --aether)
        shift
        run_apply_aether "$@"
        ;;
    *)
        run_import "$@"
        ;;
esac
