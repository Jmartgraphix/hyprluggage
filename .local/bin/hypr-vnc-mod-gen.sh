#!/usr/bin/env bash
# Unique Ctrl+Alt (+Shift) twin for every SUPER hl.bind (Gatwy/noVNC).
# Reads Lua sources; emits only vnc-mod-generated.lua.
set -euo pipefail
OUT="${1:-$HOME/.config/hypr/vnc-mod-generated.lua}"
SOURCES=(
  "$HOME/.config/hypr/bindings.lua"
  "$HOME/.config/hypr/tiling.lua"
  "$HOME/.config/hypr/media.lua"
  "$HOME/.config/hypr/monitors.lua"
)
python3 - "$OUT" "${SOURCES[@]}" << 'PY'
import re, sys
from pathlib import Path
from collections import defaultdict

out_path = Path(sys.argv[1])
if out_path.suffix != ".lua":
    out_path = out_path.with_suffix(".lua")
sources = [Path(p) for p in sys.argv[2:]]

def norm_tok(t: str) -> str:
    u = t.upper()
    if u in ("CONTROL", "CTRL"):
        return "CTRL"
    if u in ("SUPER", "ALT", "SHIFT"):
        return u
    return u

def orig_mod_key(tokens) -> str:
    n = {norm_tok(t) for t in tokens}
    parts = ["SUPER"]
    for m in ("CTRL", "ALT", "SHIFT"):
        if m in n:
            parts.append(m)
    return " ".join(parts)

def super_priority(tokens) -> int:
    extras = {norm_tok(t) for t in tokens} - {"SUPER"}
    if not extras:
        return 100
    if extras == {"SHIFT"}:
        return 80
    if "ALT" in extras and "CTRL" not in extras:
        return 60
    if "CTRL" in extras and "ALT" not in extras and "SHIFT" not in extras:
        return 40
    if "CTRL" in extras and "SHIFT" in extras and "ALT" not in extras:
        return 35
    if "CTRL" in extras and "ALT" in extras:
        return 30
    return 10

def preferred_vnc(tokens):
    extras = {norm_tok(t) for t in tokens} - {"SUPER"}
    mods = ["CTRL", "ALT"]
    if extras:
        mods.append("SHIFT")
    return mods

# Hyprland Lua does not parse conf-style code:N; map to keysyms for twins.
CODE_TO_KEY = {
    "10": "1", "11": "2", "12": "3", "13": "4", "14": "5",
    "15": "6", "16": "7", "17": "8", "18": "9", "19": "0",
    "20": "minus", "21": "equal",
}

def normalize_key(key: str) -> str:
    m = re.fullmatch(r"code:(\d+)", key.strip(), flags=re.IGNORECASE)
    if m and m.group(1) in CODE_TO_KEY:
        return CODE_TO_KEY[m.group(1)]
    return key

def parse_chord(chord: str):
    """Split 'SUPER + SHIFT + LEFT' into mod tokens + key."""
    parts = [p.strip() for p in chord.split("+")]
    parts = [p for p in parts if p]
    if not parts:
        return None
    mods_known = {"SUPER", "CTRL", "CONTROL", "ALT", "SHIFT"}
    tokens = []
    key = None
    for i, p in enumerate(parts):
        if norm_tok(p) in ("SUPER", "CTRL", "ALT", "SHIFT") and i < len(parts) - 1:
            tokens.append(p)
        else:
            key = "+".join(parts[i:]).strip()
            break
    if key is None:
        return None
    if not any(norm_tok(t) == "SUPER" for t in tokens):
        return None
    return tokens, normalize_key(key)

def find_hl_binds(text: str):
    """Yield (chord, dispatch_expr, opts_expr|None, src_snippet) for each hl.bind call."""
    i = 0
    n = len(text)
    while True:
        j = text.find("hl.bind(", i)
        if j < 0:
            break
        # skip comments
        line_start = text.rfind("\n", 0, j) + 1
        if text[line_start:j].lstrip().startswith("--"):
            i = j + 8
            continue
        k = j + len("hl.bind(")
        # first arg must be a string
        while k < n and text[k] in " \t\n":
            k += 1
        if k >= n or text[k] != '"':
            i = j + 8
            continue
        k += 1
        chord_chars = []
        while k < n:
            c = text[k]
            if c == "\\" and k + 1 < n:
                chord_chars.append(text[k + 1])
                k += 2
                continue
            if c == '"':
                k += 1
                break
            chord_chars.append(c)
            k += 1
        chord = "".join(chord_chars)
        while k < n and text[k] in " \t\n":
            k += 1
        if k >= n or text[k] != ",":
            i = j + 8
            continue
        k += 1
        while k < n and text[k] in " \t\n":
            k += 1
        # parse dispatch expression with nested parens/braces/brackets/strings
        start_disp = k
        depth_paren = 0
        depth_brace = 0
        depth_brack = 0
        in_str = None
        while k < n:
            c = text[k]
            if in_str:
                if c == "\\" and k + 1 < n:
                    k += 2
                    continue
                if c == in_str:
                    in_str = None
                k += 1
                continue
            if c in ('"', "'"):
                in_str = c
                k += 1
                continue
            if c == "(":
                depth_paren += 1
            elif c == ")":
                if depth_paren == 0 and depth_brace == 0 and depth_brack == 0:
                    break
                depth_paren -= 1
            elif c == "{":
                depth_brace += 1
            elif c == "}":
                depth_brace -= 1
            elif c == "[":
                depth_brack += 1
            elif c == "]":
                depth_brack -= 1
            elif c == "," and depth_paren == 0 and depth_brace == 0 and depth_brack == 0:
                break
            k += 1
        dispatch = text[start_disp:k].strip()
        opts = None
        while k < n and text[k] in " \t\n":
            k += 1
        if k < n and text[k] == ",":
            k += 1
            while k < n and text[k] in " \t\n":
                k += 1
            start_opts = k
            depth_paren = depth_brace = depth_brack = 0
            in_str = None
            while k < n:
                c = text[k]
                if in_str:
                    if c == "\\" and k + 1 < n:
                        k += 2
                        continue
                    if c == in_str:
                        in_str = None
                    k += 1
                    continue
                if c in ('"', "'"):
                    in_str = c
                    k += 1
                    continue
                if c == "(":
                    depth_paren += 1
                elif c == ")":
                    if depth_paren == 0 and depth_brace == 0 and depth_brack == 0:
                        break
                    depth_paren -= 1
                elif c == "{":
                    depth_brace += 1
                elif c == "}":
                    depth_brace -= 1
                elif c == "[":
                    depth_brack += 1
                elif c == "]":
                    depth_brack -= 1
                k += 1
            opts = text[start_opts:k].strip()
        # consume closing )
        while k < n and text[k] in " \t\n":
            k += 1
        end = k + 1 if k < n and text[k] == ")" else k
        snippet = text[j:end].strip()
        # collapse whitespace for comment
        src = re.sub(r"\s+", " ", snippet)
        yield chord, dispatch, opts, src
        i = end

def set_description(opts: str | None, force_desc: str | None) -> str | None:
    if force_desc is None:
        return opts
    lit = '"' + force_desc.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if not opts:
        return "{ description = %s }" % lit
    # replace existing description = "..." or insert into table
    if re.search(r"description\s*=", opts):
        return re.sub(
            r'description\s*=\s*(?:"(?:\\.|[^"])*"|\'(?:\\.|[^\'])*\')',
            f"description = {lit}",
            opts,
            count=1,
        )
    inner = opts.strip()
    if inner.startswith("{") and inner.endswith("}"):
        body = inner[1:-1].strip()
        if body:
            return "{ description = %s, %s }" % (lit, body)
        return "{ description = %s }" % lit
    return "{ description = %s }" % lit

# (orig_mod_key, KEY.upper()) -> (mods, new_key|None, description|None)
EXPLICIT = {
    ("SUPER", "SPACE"): (["CTRL", "ALT"], None, None),
    ("SUPER SHIFT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "W", "Toggle waybar (Super+Shift+Space)"),
    ("SUPER CTRL", "SPACE"): (["CTRL", "ALT", "SHIFT"], "T", "Theme Matugen apply (Super+Ctrl+Space)"),
    ("SUPER ALT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "SPACE", "Theme wallpaper picker (Super+Alt+Space)"),
    ("SUPER CTRL SHIFT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "Y", "Theme switcher (Super+Ctrl+Shift+Space)"),
    ("SUPER CTRL ALT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "G", "Theme random wallpaper (Super+Ctrl+Alt+Space)"),

    ("SUPER CTRL", "A"): (["CTRL", "ALT", "SHIFT"], "F6", "Gemini (VNC)"),
    ("SUPER CTRL", "B"): (["CTRL", "ALT", "SHIFT"], "B", "Power Profiles (VNC)"),
    ("SUPER ALT", "M"): (["CTRL", "ALT", "SHIFT"], "E", "EasyEffects (VNC)"),
    ("SUPER CTRL", "F12"): (["CTRL", "ALT", "SHIFT"], "F12", "Restart Sunshine (VNC)"),
    ("SUPER CTRL", "BACKSPACE"): (["CTRL", "ALT", "SHIFT"], "BACKSPACE", "Toggle focus/vibe (VNC)"),
    ("SUPER", "I"): (["CTRL", "ALT"], None, "Theme Hyprluggage TUI"),
    ("SUPER SHIFT", "I"): (["CTRL", "ALT", "SHIFT"], "I", "Web App Install (VNC)"),
    ("SUPER ALT", "I"): (["CTRL", "ALT", "SHIFT"], "U", "Theme browse (Super+Alt+I)"),
    ("SUPER CTRL", "I"): (["CTRL", "ALT", "SHIFT"], "O", "Toggle Idle/Lock (VNC)"),
    ("SUPER CTRL", "N"): (["CTRL", "ALT", "SHIFT"], "F5", "Nightlight (VNC)"),

    ("SUPER SHIFT", "S"): (["CTRL", "ALT", "SHIFT"], "S", "Share clipboard (VNC)"),
    ("SUPER ALT", "S"): (["CTRL", "ALT", "SHIFT"], "F", "Share file (VNC)"),
    ("SUPER CTRL", "S"): (["CTRL", "ALT", "SHIFT"], "D", "Share folder (VNC)"),

    ("SUPER ALT", "LEFT"): (["CTRL", "ALT", "SHIFT"], "left", "Theme previous wallpaper (Super+Alt+Left)"),
    ("SUPER ALT", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "right", "Theme next wallpaper (Super+Alt+Right)"),
    ("SUPER ALT", "UP"): (["CTRL", "ALT", "SHIFT"], "up", "Theme wallpapers cycle (Super+Alt+Up)"),

    ("SUPER SHIFT", "LEFT"): (["CTRL", "ALT", "SHIFT"], "H", "Move window left (VNC)"),
    ("SUPER SHIFT", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "L", "Move window right (VNC)"),
    ("SUPER SHIFT", "UP"): (["CTRL", "ALT", "SHIFT"], "K", "Move window up (VNC)"),
    ("SUPER SHIFT", "DOWN"): (["CTRL", "ALT", "SHIFT"], "J", "Move window down (VNC)"),

    ("SUPER CTRL", "LEFT"): (["CTRL", "ALT", "SHIFT"], "comma", "Previous workspace (VNC)"),
    ("SUPER CTRL", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "period", "Next workspace (VNC)"),
    ("SUPER CONTROL", "LEFT"): (["CTRL", "ALT", "SHIFT"], "comma", "Previous workspace (VNC)"),
    ("SUPER CONTROL", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "period", "Next workspace (VNC)"),

    ("SUPER CTRL", "UP"): (["CTRL", "ALT", "SHIFT"], "Escape", "Reboot (VNC)"),

    ("SUPER ALT", "H"): (["CTRL", "ALT", "SHIFT"], "F1", "Laptop screen off (VNC)"),
    ("SUPER ALT", "L"): (["CTRL", "ALT", "SHIFT"], "F2", "Laptop screen on (VNC)"),
    ("SUPER SHIFT", "L"): (["CTRL", "ALT", "SHIFT"], "F3", "Lock screen (VNC)"),

    ("SUPER", "R"): (["CTRL", "ALT"], None, "Screen recording"),
    ("SUPER SHIFT", "R"): (["CTRL", "ALT", "SHIFT"], "R", "Screen recording + mic (VNC)"),
    # F9: free V/C/N for floating / calculator / DND
    ("SUPER ALT", "R"): (["CTRL", "ALT", "SHIFT"], "F9", "Screen recording + mic + webcam (VNC)"),

    ("SUPER SHIFT", "RETURN"): (["CTRL", "ALT", "SHIFT"], "RETURN", "Attach tmux (VNC)"),
    ("SUPER ALT", "RETURN"): (["CTRL", "ALT", "SHIFT"], "apostrophe", "New tmux session (VNC)"),

    # Keep Ctrl+Alt(+Shift)+0-9 free for workspace switch/move (never steal digits).
    ("SUPER SHIFT", "P"): (["CTRL", "ALT", "SHIFT"], "F7", "Color picker (VNC)"),
    ("SUPER SHIFT", "O"): (["CTRL", "ALT", "SHIFT"], "F8", "Pop window out (VNC)"),

    # Prefer mnemonic remotes for common actions; displace prior occupants.
    ("SUPER SHIFT", "V"): (["CTRL", "ALT", "SHIFT"], "V", "Toggle floating"),
    ("SUPER ALT", "C"): (["CTRL", "ALT", "SHIFT"], "C", "Calculator"),
    ("SUPER ALT", "N"): (["CTRL", "ALT", "SHIFT"], "N", "Do Not Disturb"),
    ("SUPER SHIFT", "C"): (["CTRL", "ALT", "SHIFT"], "F10", "Cava visualizer (VNC)"),
    ("SUPER SHIFT", "N"): (["CTRL", "ALT", "SHIFT"], "F11", "Wifi Menu (VNC)"),
}

candidates = []
for src in sources:
    if not src.is_file():
        continue
    text = src.read_text(encoding="utf-8", errors="replace")
    for chord, dispatch, opts, src_line in find_hl_binds(text):
        parsed = parse_chord(chord)
        if not parsed:
            continue
        tokens, key = parsed
        if key.upper() in ("XF86AUDIORAISEVOLUME", "XF86AUDIOLOWERVOLUME"):
            continue
        # skip multiline function() volume ignore_mods handlers (no Super chord twin needed)
        if dispatch.lstrip().startswith("function"):
            continue
        candidates.append({
            "tokens": tokens,
            "key": key,
            "dispatch": dispatch,
            "opts": opts,
            "prio": super_priority(tokens),
            "src_line": src_line,
            "file": src.name,
            "orig_mod": orig_mod_key(tokens),
        })

def chord_id(mods, key):
    return (tuple(mods), (key or "").upper())

def emit_keys(mods, key):
    return " + ".join(list(mods) + [key])

def L(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

used = {}
output = []
failed = []

explicit_items = []
auto_items = []
for c in candidates:
    key = EXPLICIT.get((c["orig_mod"], c["key"].upper()))
    if key is None:
        auto_items.append(c)
    else:
        explicit_items.append((c, key))

for c, (mods, key_ov, force_desc) in explicit_items:
    new_key = key_ov if key_ov is not None else c["key"]
    cid = chord_id(mods, new_key)
    if cid in used:
        failed.append((c, f"explicit chord taken by {used[cid]}"))
        continue
    used[cid] = c["src_line"]
    opts = set_description(c["opts"], force_desc)
    output.append({
        "mods": mods,
        "key": new_key,
        "dispatch": c["dispatch"],
        "opts": opts,
        "comment": c["src_line"],
        "note": f"{c['orig_mod']} + {c['key']} → {' '.join(mods)} + {new_key}",
    })

# Digits 0-9 are reserved for workspace switch (Ctrl+Alt+N) and move
# (Ctrl+Alt+Shift+N). Place those first; never remap them off the digit;
# never use digits as fallback remaps for other binds.
DIGIT_KEYS = set("0123456789")
POOL = list("QZXYUWFEABCDGHJKLM")  # letters only — no 0-9

def append_bind(c, mods, new_key, note=None):
    used[chord_id(mods, new_key)] = c["src_line"]
    output.append({
        "mods": mods,
        "key": new_key,
        "dispatch": c["dispatch"],
        "opts": c["opts"],
        "comment": c["src_line"],
        "note": note,
    })

def place_digit(c):
    """Keep Super(+Shift)+N → Ctrl+Alt(+Shift)+N exactly."""
    mods = preferred_vnc(c["tokens"])
    new_key = c["key"]
    cid = chord_id(mods, new_key)
    if cid in used:
        failed.append((c, f"digit chord taken by {used[cid]}"))
        return
    note = None
    if mods != preferred_vnc(c["tokens"]):
        note = f"{c['orig_mod']} + {c['key']} → {' '.join(mods)} + {new_key}"
    append_bind(c, mods, new_key, note)

def place_auto(c):
    mods = preferred_vnc(c["tokens"])
    new_key = c["key"]
    cid = chord_id(mods, new_key)
    if cid in used:
        mods2 = ["CTRL", "ALT", "SHIFT"]
        cid2 = chord_id(mods2, new_key)
        if cid2 not in used:
            mods, cid = mods2, cid2
        else:
            placed = False
            for letter in POOL:
                cid3 = chord_id(["CTRL", "ALT", "SHIFT"], letter)
                if cid3 not in used:
                    mods = ["CTRL", "ALT", "SHIFT"]
                    new_key = letter
                    cid = cid3
                    placed = True
                    break
            if not placed:
                failed.append((c, "no free chord"))
                return
    note = None
    if new_key.upper() != c["key"].upper() or mods != preferred_vnc(c["tokens"]):
        note = f"{c['orig_mod']} + {c['key']} → {' '.join(mods)} + {new_key}"
    append_bind(c, mods, new_key, note)

digit_items = [c for c in auto_items if c["key"] in DIGIT_KEYS]
other_items = [c for c in auto_items if c["key"] not in DIGIT_KEYS]
digit_items.sort(key=lambda c: (-c["prio"], c["key"], c["file"], c["src_line"]))
other_items.sort(key=lambda c: (-c["prio"], c["file"], c["src_line"]))

# Claim workspace digit chords before letter remaps can touch them.
# (Explicit remaps above must not use 0-9.)
for c in digit_items:
    place_digit(c)
for c in other_items:
    place_auto(c)

# Keep the same locals preamble as hand-written sources expect
lua_lines = [
    "-- AUTO-GENERATED by hypr-vnc-mod-gen.sh — do not edit",
    f"-- {len(output)} unique VNC binds | failed: {len(failed)}",
    "-- Super-only → Ctrl+Alt; Super+… → Ctrl+Alt+Shift or explicit remap (see notes).",
    "-- During VNC: Super+K / Ctrl+Alt+K shows only these (keyhints).",
    "",
    'local home = os.getenv("HOME")',
    'local terminal = "kitty"',
    'local browser = home .. "/.config/hypr/scripts/launch-browser"',
    'local browser2 = "zen-browser"',
    'local webapp = home .. "/.config/hypr/scripts/launch-webapp"',
    'local focus = home .. "/.config/hypr/scripts/focus"',
    'local osdclient = "swayosd-client --monitor \\"$(hyprctl monitors -j | jq -r \'.[] | select(.focused == true).name\')\\""',
    'local rofiDir = home .. "/.config/rofi/scripts"',
    'local scrDir = home .. "/.config/hypr/scripts"',
    "",
]

for o in output:
    keys = emit_keys(o["mods"], o["key"])
    lua_lines.append(f"-- from: {o['comment']}")
    if o.get("note"):
        lua_lines.append(f"-- VNC: {o['note']}")
    if o["opts"]:
        lua_lines.append(f"hl.bind({L(keys)}, {o['dispatch']}, {o['opts']})")
    else:
        lua_lines.append(f"hl.bind({L(keys)}, {o['dispatch']})")
    lua_lines.append("")

if failed:
    lua_lines.append("-- --- FAILED ---")
    for c, why in failed:
        lua_lines.append(f"-- FAIL ({why}): {c['src_line']}")

out_path.write_text("\n".join(lua_lines) + "\n", encoding="utf-8")
print(f"wrote {out_path}: {len(output)} binds, {len(failed)} failed")
for c, why in failed:
    print(" FAIL", why, c.get("src_line") if isinstance(c, dict) else c)

by = defaultdict(list)
for o in output:
    by[chord_id(o["mods"], o["key"])].append(emit_keys(o["mods"], o["key"]))
cols = {k: v for k, v in by.items() if len(v) > 1}
print(f"collisions: {len(cols)}")
for k, v in cols.items():
    print(k, v)

text = out_path.read_text()
print("\nKey map:")
for label, pat in [
    ("Launcher", r'CTRL \+ ALT \+ SPACE'),
    ("Browser", r'CTRL \+ ALT \+ B"'),
    ("Theme switcher", r"Theme switcher"),
    ("Matugen", r"Theme Matugen"),
    ("Wall picker", r"Theme wallpaper picker"),
    ("Random wallpaper", r"Theme random wallpaper"),
    ("Theme browse", r"Theme browse"),
    ("Waybar", r"Toggle waybar"),
    ("Gemini", r"Gemini \(VNC\)"),
    ("EasyEffects", r"EasyEffects \(VNC\)"),
    ("Wall prev", r"Theme previous wallpaper"),
    ("Move left", r"Move window left \(VNC\)"),
    ("Lock", r"Lock screen \(VNC\)"),
    ("Reboot", r"Reboot \(VNC\)"),
]:
    hits = [ln.strip() for ln in text.splitlines() if re.search(pat, ln) and ln.strip().startswith("hl.bind")]
    # also match description lines via previous comment or inline
    if not hits:
        hits = [ln.strip() for ln in text.splitlines() if re.search(pat, ln) and not ln.strip().startswith("-- ---")]
    print(f"  {label}: {hits[0][:95] if hits else 'MISSING'}")
PY
