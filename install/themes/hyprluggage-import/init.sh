#!/bin/bash
# shared helpers and color extraction

RED='\033[0;31m' GREEN='\033[0;32m' BLUE='\033[0;34m' RESET='\033[0m'
ok()   { echo -e "${GREEN}[OK]${RESET} $1"; }
err()  { echo -e "${RED}[ERROR]${RESET} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${RESET} $1"; }

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

read_colors_toml() {
    awk '
        /^[[:space:]]*background[[:space:]]*=/ { bg=$3 }
        /^[[:space:]]*foreground[[:space:]]*=/ { fg=$3 }
        /^[[:space:]]*color[0-9]+[[:space:]]*=/ { c[$1]=$3 }
        END {
            gsub(/"/, "", bg)
            gsub(/"/, "", fg)
            if (bg == "" || fg == "") exit 1
            printf "%s %s ", bg, fg
            for (i = 0; i < 16; i++) {
                v = c["color" i]
                gsub(/"/, "", v)
                printf "%s ", v
            }
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

    for file in "$src/colors.toml"; do
        [[ -f "$file" ]] || continue
        read_colors_toml "$file" && return
    done
    return 1
}
