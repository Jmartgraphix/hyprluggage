#!/bin/bash
# shared helpers and color extraction

RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' RESET='\033[0m'
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${RESET} $1"; }

# Hyprluggage theme folder shape. Bump when import writers change layout.
THEME_FORMAT=1

write_theme_format() {
    local dest="$1"
    printf 'format = %s\n' "$THEME_FORMAT" >"$dest/theme.toml"
}

# Refuse themes this importer / switcher does not understand.
theme_format_of() {
    local dest="$1"
    local file="$dest/theme.toml"
    [[ -f "$file" ]] || { echo ""; return 0; }
    awk -F'=' '
        /^[[:space:]]*format[[:space:]]*=/ {
            gsub(/[[:space:]]/, "", $2)
            print $2
            exit
        }
    ' "$file"
}

require_theme_format() {
    local dest="$1"
    local name="${2:-$(basename "$dest")}"
    local got
    got=$(theme_format_of "$dest")
    if [[ -z "$got" ]]; then
        err "theme \"$name\" has no theme.toml (expected format = $THEME_FORMAT)"
        return 1
    fi
    if [[ "$got" != "$THEME_FORMAT" ]]; then
        err "theme \"$name\" uses format $got; this Hyprluggage only understands format $THEME_FORMAT"
        return 1
    fi
    return 0
}

hex() { echo "${1#\#}"; }

luminance() {
    local h="${1#\#}"
    local r=$((16#${h:0:2})) g=$((16#${h:2:2})) b=$((16#${h:4:2}))
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
}

lighten() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r + amt > 255 ? 255 : r + amt))
    g=$((g + amt > 255 ? 255 : g + amt))
    b=$((b + amt > 255 ? 255 : b + amt))
    printf "#%02x%02x%02x" $r $g $b
}

darken() {
    local hex="${1#\#}" amt="${2:-20}"
    local r=$((16#${hex:0:2})) g=$((16#${hex:2:2})) b=$((16#${hex:4:2}))
    r=$((r - amt < 0 ? 0 : r - amt))
    g=$((g - amt < 0 ? 0 : g - amt))
    b=$((b - amt < 0 ? 0 : b - amt))
    printf "#%02x%02x%02x" $r $g $b
}

read_kitty_colors() {
    awk '/^background / {bg=$2} /^foreground / {fg=$2}
         /^color[0-9]+ / {c[$1]=$2}
         END {
             if(!bg) bg=c["color0"]
             if(!fg) fg=c["color7"]
             if(bg == "" || fg == "") exit 1
             printf "%s %s ", bg, fg
             for(i=0;i<16;i++) printf "%s ", c["color"i]
         }' "$1"
}

# Omarchy/Aether colors.toml: prefer explicit color0-15, else map semantic names.
read_colors_toml() {
    awk '
        /^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*=/ {
            key = $1
            rest = $0
            sub(/^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*=[[:space:]]*/, "", rest)
            gsub(/"/, "", rest)
            # Only strip " # comment" — hex values are #rrggbb.
            sub(/[[:space:]]+#.*$/, "", rest)
            gsub(/[[:space:]]/, "", rest)
            kv[key] = rest
        }
        END {
            bg = kv["background"]
            fg = kv["foreground"]
            if (bg == "" || fg == "") exit 1

            # ANSI slots when present (Aether writes both).
            for (i = 0; i < 16; i++) c[i] = kv["color" i]

            # Modern Omarchy themes only ship semantic names.
            if (c[0] == "") c[0] = bg
            if (c[1] == "") c[1] = kv["red"]
            if (c[2] == "") c[2] = kv["green"]
            if (c[3] == "") c[3] = kv["yellow"]
            if (c[4] == "") c[4] = (kv["blue"] != "" ? kv["blue"] : kv["accent"])
            if (c[5] == "") c[5] = kv["magenta"]
            if (c[6] == "") c[6] = kv["cyan"]
            if (c[7] == "") c[7] = fg
            if (c[8] == "") c[8] = (kv["muted"] != "" ? kv["muted"] : kv["dark_foreground"])
            if (c[9] == "") c[9] = (kv["bright_red"] != "" ? kv["bright_red"] : c[1])
            if (c[10] == "") c[10] = (kv["bright_green"] != "" ? kv["bright_green"] : c[2])
            if (c[11] == "") c[11] = (kv["bright_yellow"] != "" ? kv["bright_yellow"] : c[3])
            if (c[12] == "") c[12] = (kv["bright_blue"] != "" ? kv["bright_blue"] : c[4])
            if (c[13] == "") c[13] = (kv["bright_magenta"] != "" ? kv["bright_magenta"] : c[5])
            if (c[14] == "") c[14] = (kv["bright_cyan"] != "" ? kv["bright_cyan"] : c[6])
            if (c[15] == "") c[15] = (kv["bright_foreground"] != "" ? kv["bright_foreground"] : fg)

            printf "%s %s ", bg, fg
            for (i = 0; i < 16; i++) printf "%s ", c[i]
        }
    ' "$1"
}

read_alacritty_colors() {
    awk -F"[\"']" '
        /^\[colors\.primary\]/ {sec="primary"}
        /^\[colors\.normal\]/ {sec="normal"}
        /^\[colors\.bright\]/ {sec="bright"}
        /^\[/ && !/colors\.(primary|normal|bright)/ {sec=""}
        sec=="primary" && /background/ {bg=$2}
        sec=="primary" && /foreground/ {fg=$2}
        sec=="normal" && /black/ {c[0]=$2} sec=="normal" && /red/ {c[1]=$2}
        sec=="normal" && /green/ {c[2]=$2} sec=="normal" && /yellow/ {c[3]=$2}
        sec=="normal" && /blue/ {c[4]=$2} sec=="normal" && /magenta/ {c[5]=$2}
        sec=="normal" && /cyan/ {c[6]=$2} sec=="normal" && /white/ {c[7]=$2}
        sec=="bright" && /black/ {c[8]=$2} sec=="bright" && /red/ {c[9]=$2}
        sec=="bright" && /green/ {c[10]=$2} sec=="bright" && /yellow/ {c[11]=$2}
        sec=="bright" && /blue/ {c[12]=$2} sec=="bright" && /magenta/ {c[13]=$2}
        sec=="bright" && /cyan/ {c[14]=$2} sec=="bright" && /white/ {c[15]=$2}
        END {
            if(bg == "" || fg == "") exit 1
            printf "%s %s ", bg, fg
            for(i=0;i<16;i++) printf "%s ", c[i]
        }' "$1"
}

# Prints: background foreground color0 ... color15
# Accepts an Aether output directory or a hyprluggage theme directory.
get_colors() {
    local src="$1" file

    for file in "$src/kitty.conf" "$src/.config/kitty/colors.conf"; do
        [[ -f "$file" ]] || continue
        read_kitty_colors "$file" && return
    done

    for file in "$src/alacritty.toml" "$src/.config/alacritty/colors.toml"; do
        [[ -f "$file" ]] || continue
        read_alacritty_colors "$file" && return
    done

    file="$src/colors.toml"
    [[ -f "$file" ]] && read_colors_toml "$file" && return
    return 1
}

# Semantic accent from colors.toml (Omarchy / Aether). Empty when absent.
read_toml_accent() {
    local file="$1/colors.toml" v
    [[ -f "$file" ]] || return 1
    v=$(awk '
        /^[[:space:]]*accent[[:space:]]*=/ {
            rest = $0
            sub(/^[[:space:]]*accent[[:space:]]*=[[:space:]]*/, "", rest)
            gsub(/"/, "", rest)
            sub(/[[:space:]]+#.*$/, "", rest)
            gsub(/[[:space:]]/, "", rest)
            print rest
            exit
        }
    ' "$file")
    [[ -n "$v" ]] || return 1
    printf '%s\n' "$v"
}

# Back-compat name used by aether apply.
read_aether_accent() { read_toml_accent "$@"; }
