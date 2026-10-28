#!/bin/bash
# Convert an Aether theme directory into themes/<name> (aether).

aether_source_default() {
    printf '%s\n' "$HOME/.config/aether/theme"
}

# Print the blueprint name whose 16 ANSI colors match this Aether output.
match_blueprint_name() {
    local src="$1" colors
    colors=$(get_colors "$src" 2>/dev/null || true)
    AETHER_ANSI="$colors" AETHER_BLUEPRINTS="${AETHER_BLUEPRINTS:-$HOME/.config/aether/blueprints}" \
        python3 - <<'PY'
import json, os, sys

def norm(value):
    if isinstance(value, dict):
        for key in ("hex", "value", "color"):
            if key in value:
                value = value[key]
                break
        else:
            return ""
    text = str(value).strip().lower()
    if not text:
        return ""
    if not text.startswith("#"):
        text = "#" + text
    return text

wanted = [norm(part) for part in os.environ.get("AETHER_ANSI", "").split()]
wanted = [part for part in wanted if part]
# get_colors prints background, foreground, then color0-color15.
if len(wanted) < 18:
    sys.exit(0)
wanted = wanted[2:18]

root = os.path.expanduser(os.environ.get("AETHER_BLUEPRINTS", ""))
if not root or not os.path.isdir(root):
    sys.exit(0)

best = None
for filename in os.listdir(root):
    if not filename.endswith(".json"):
        continue
    path = os.path.join(root, filename)
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        continue
    palette = data.get("palette") or {}
    colors = palette.get("colors")
    if not isinstance(colors, list) or len(colors) < 16:
        continue
    got = [norm(color) for color in colors[:16]]
    if got != wanted:
        continue
    name = data.get("name") or os.path.splitext(filename)[0]
    if not isinstance(name, str) or not name.strip():
        continue
    stamp = os.path.getmtime(path)
    if best is None or stamp > best[0]:
        best = (stamp, name.strip())

if best:
    print(best[1])
PY
}

prompt_aether_name() {
    local name=""
    if command -v rofi >/dev/null && [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
        name=$(rofi -dmenu -p "Aether theme name" <<< "") || true
    elif command -v gum >/dev/null && [[ -t 0 || -t 1 ]]; then
        name=$(gum input --placeholder "theme name") || true
    elif [[ -t 0 ]]; then
        printf 'theme name: ' >&2
        read -r name || true
    else
        err "pass a theme name: hyprluggage apply-aether [dir] <name>"
        exit 1
    fi
    printf '%s' "$name"
}

# "Forest" and "Forest (aether)" both become "Forest (aether)".
aether_dir_name() {
    local base="$1"
    base=$(printf '%s' "$base" | tr '/' '-' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
    base="${base% (aether)}"
    [[ -z "$base" || "$base" == "." || "$base" == ".." || "$base" == .* ]] && return 1
    printf '%s (aether)\n' "$base"
}

wallpaper_stem() {
    local dir="$1" file
    file=$(find "$dir/backgrounds" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort -V | head -1)
    [[ -n "$file" ]] || return 1
    basename "$file" | sed 's/\.[^.]*$//'
}

resolve_aether_name() {
    local src="$1" explicit="$2" base=""
    if [[ -n "$explicit" ]]; then
        base="$explicit"
    else
        base=$(match_blueprint_name "$src" || true)
        if [[ -z "$base" ]]; then
            base=$(wallpaper_stem "$src" || true)
        fi
        if [[ -z "$base" ]]; then
            base=$(prompt_aether_name)
        fi
    fi
    if [[ -z "$base" ]]; then
        err "could not name the Aether theme"
        command -v notify-send >/dev/null && notify-send "Hyprluggage" "Aether apply needs a blueprint or a wallpaper"
        return 1
    fi
    aether_dir_name "$base" || { err "invalid theme name"; return 1; }
}

run_apply_aether() {
    local src explicit="" name
    src="${1:-}"
    if [[ -n "$src" && -d "$src" ]]; then
        shift || true
    else
        explicit="$src"
        src="$(aether_source_default)"
        [[ -n "${1:-}" ]] && shift || true
    fi
    [[ -n "${1:-}" ]] && explicit="$1"

    [[ -d "$src" ]] || { err "no Aether theme at $src"; exit 1; }
    name=$(resolve_aether_name "$src" "$explicit") || exit 1

    # Same blueprint name replaces the existing theme, then reloads it.
    build_theme "$name" "$src" aether
    ok "applied $name"
    activate_theme "$name"
}
