#!/usr/bin/env bash
# Unique Ctrl+Alt (+Shift) twin for every SUPER bind (Gatwy/noVNC).
set -euo pipefail
OUT="${1:-$HOME/.config/hypr/vnc-mod-generated.conf}"
SOURCES=(
  "$HOME/.config/hypr/bindings.conf"
  "$HOME/.config/hypr/tiling.conf"
  "$HOME/.config/hypr/media.conf"
  "$HOME/.config/hypr/monitors.conf"
)
python3 - "$OUT" "${SOURCES[@]}" << 'PY'
import re, sys
from pathlib import Path

out_path = Path(sys.argv[1])
sources = [Path(p) for p in sys.argv[2:]]

def norm_tok(t: str) -> str:
    u = t.upper()
    if u in ("CONTROL", "CTRL"):
        return "CTRL"
    if u in ("SUPER", "ALT", "SHIFT"):
        return u
    return u

def parse_bind_line(line: str):
    m = re.match(r"^(\s*)(bind[a-z]*)\s*=\s*([^,]*),(.*)$", line.rstrip("\n"), re.I)
    if not m:
        return None
    indent, kw, mods_raw, rest = m.groups()
    tokens = [t for t in re.split(r"\s+", mods_raw.strip()) if t]
    if not any(norm_tok(t) == "SUPER" for t in tokens):
        return None
    return indent, kw, tokens, rest

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

def key_token(rest: str) -> str:
    return rest.split(",")[0].strip()

def preferred_vnc(tokens):
    extras = {norm_tok(t) for t in tokens} - {"SUPER"}
    mods = ["CTRL", "ALT"]
    if extras:
        mods.append("SHIFT")
    return mods

# (orig_mod_key, KEY.upper()) -> (mods, new_key|None, description|None)
# new_key None = keep original key token
EXPLICIT = {
    # Space family
    ("SUPER", "SPACE"): (["CTRL", "ALT"], None, None),  # launcher
    ("SUPER SHIFT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "W", "Toggle waybar (VNC)"),
    ("SUPER CTRL", "SPACE"): (["CTRL", "ALT", "SHIFT"], "T", "Matugen Themes (VNC)"),
    ("SUPER ALT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "SPACE", "Wallpaper Picker (VNC)"),
    ("SUPER CTRL SHIFT", "SPACE"): (["CTRL", "ALT", "SHIFT"], "Y", "Theme Switcher (VNC)"),

    # Apps / collide with Super-only or Super+Shift
    ("SUPER CTRL", "A"): (["CTRL", "ALT", "SHIFT"], "F6", "Gemini (VNC)"),
    ("SUPER CTRL", "B"): (["CTRL", "ALT", "SHIFT"], "B", "Power Profiles (VNC)"),
    ("SUPER ALT", "M"): (["CTRL", "ALT", "SHIFT"], "E", "EasyEffects (VNC)"),
    ("SUPER CTRL", "F12"): (["CTRL", "ALT", "SHIFT"], "F12", "Restart Sunshine (VNC)"),
    ("SUPER CTRL", "BACKSPACE"): (["CTRL", "ALT", "SHIFT"], "BACKSPACE", "Toggle focus/vibe (VNC)"),
    ("SUPER", "I"): (["CTRL", "ALT"], None, None),
    ("SUPER SHIFT", "I"): (["CTRL", "ALT", "SHIFT"], "I", "Web App Install (VNC)"),
    ("SUPER ALT", "I"): (["CTRL", "ALT", "SHIFT"], "U", "Browse Themes (VNC)"),
    ("SUPER CTRL", "I"): (["CTRL", "ALT", "SHIFT"], "O", "Toggle Idle/Lock (VNC)"),
    ("SUPER CTRL", "N"): (["CTRL", "ALT", "SHIFT"], "F5", "Nightlight (VNC)"),

    # Share
    ("SUPER SHIFT", "S"): (["CTRL", "ALT", "SHIFT"], "S", "Share clipboard (VNC)"),
    ("SUPER ALT", "S"): (["CTRL", "ALT", "SHIFT"], "F", "Share file (VNC)"),
    ("SUPER CTRL", "S"): (["CTRL", "ALT", "SHIFT"], "D", "Share folder (VNC)"),

    # Wallpaper arrows
    ("SUPER ALT", "LEFT"): (["CTRL", "ALT", "SHIFT"], "left", "Previous Wallpaper (VNC)"),
    ("SUPER ALT", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "right", "Next Wallpaper (VNC)"),
    ("SUPER ALT", "UP"): (["CTRL", "ALT", "SHIFT"], "up", "Theme Wallpapers (VNC)"),

    # Swap Super+Shift+arrows → vim keys on Shift tier
    ("SUPER SHIFT", "LEFT"): (["CTRL", "ALT", "SHIFT"], "H", "Swap window left (VNC)"),
    ("SUPER SHIFT", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "L", "Swap window right (VNC)"),
    ("SUPER SHIFT", "UP"): (["CTRL", "ALT", "SHIFT"], "K", "Swap window up (VNC)"),
    ("SUPER SHIFT", "DOWN"): (["CTRL", "ALT", "SHIFT"], "J", "Swap window down (VNC)"),

    # Workspace Super+Ctrl+arrows
    ("SUPER CTRL", "LEFT"): (["CTRL", "ALT", "SHIFT"], "comma", "Previous workspace (VNC)"),
    ("SUPER CTRL", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "period", "Next workspace (VNC)"),
    ("SUPER CONTROL", "LEFT"): (["CTRL", "ALT", "SHIFT"], "comma", "Previous workspace (VNC)"),
    ("SUPER CONTROL", "RIGHT"): (["CTRL", "ALT", "SHIFT"], "period", "Next workspace (VNC)"),

    ("SUPER CTRL", "UP"): (["CTRL", "ALT", "SHIFT"], "Escape", "Reboot (VNC)"),

    # Monitors / lock
    ("SUPER ALT", "H"): (["CTRL", "ALT", "SHIFT"], "F1", "Laptop screen off (VNC)"),
    ("SUPER ALT", "L"): (["CTRL", "ALT", "SHIFT"], "F2", "Laptop screen on (VNC)"),
    ("SUPER SHIFT", "L"): (["CTRL", "ALT", "SHIFT"], "F3", "Lock screen (VNC)"),

    # Record
    ("SUPER SHIFT", "R"): (["CTRL", "ALT", "SHIFT"], "R", "Record + Mic (VNC)"),
    ("SUPER ALT", "R"): (["CTRL", "ALT", "SHIFT"], "V", "Record mic+webcam (VNC)"),

    # Tmux
    ("SUPER SHIFT", "RETURN"): (["CTRL", "ALT", "SHIFT"], "RETURN", "Attach tmux (VNC)"),
    ("SUPER ALT", "RETURN"): (["CTRL", "ALT", "SHIFT"], "apostrophe", "New tmux session (VNC)"),

    # Brightness media extras
    ("SUPER ALT", "XF86AUDIORAISEVOLUME"): (["CTRL", "ALT", "SHIFT"], "XF86AudioRaiseVolume", None),
    ("SUPER ALT", "XF86AUDIOLOWERVOLUME"): (["CTRL", "ALT", "SHIFT"], "XF86AudioLowerVolume", None),
}

candidates = []
for src in sources:
    if not src.is_file():
        continue
    for line in src.read_text(encoding="utf-8", errors="replace").splitlines():
        parsed = parse_bind_line(line)
        if not parsed:
            continue
        indent, kw, tokens, rest = parsed
        key = key_token(rest)
        candidates.append({
            "indent": indent, "kw": kw, "tokens": tokens, "rest": rest, "key": key,
            "prio": super_priority(tokens), "src_line": line.strip(), "file": src.name,
            "orig_mod": orig_mod_key(tokens),
        })

def chord_id(mods, key):
    return (tuple(mods), (key or "").upper())

def apply_desc(kw, rest, new_key, force_desc):
    parts = [p.strip() for p in rest.split(",")]
    if not parts:
        return rest
    parts[0] = new_key if new_key is not None else parts[0]
    if force_desc and kw.lower().startswith("bindd"):
        dispatchers = {
            "exec", "workspace", "movetoworkspace", "movefocus", "movewindow",
            "swapwindow", "togglefloating", "fullscreen", "pseudo", "killactive",
            "exit", "resizeactive", "bringactivetotop", "focusmonitor",
        }
        if len(parts) >= 2:
            first = parts[1].split()[0].lower() if parts[1] else ""
            if first in dispatchers:
                parts.insert(1, force_desc)
            else:
                parts[1] = force_desc
        else:
            parts.append(force_desc)
    return ", ".join(parts)

used = {}
output = []
failed = []

# Pass 1: EXPLICIT first (reserve chords)
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
    new_rest = apply_desc(c["kw"], c["rest"], new_key, force_desc)
    output.append({
        "line": f"{c['indent']}{c['kw']} = {' '.join(mods)}, {new_rest}",
        "comment": c["src_line"],
        "note": f"{c['orig_mod']} + {c['key']} → {' '.join(mods)} + {new_key}",
        "explicit": True,
    })

# Pass 2: remaining by priority
auto_items.sort(key=lambda c: (-c["prio"], c["file"], c["src_line"]))
POOL = list("QZXPVMN1234567890")

for c in auto_items:
    mods = preferred_vnc(c["tokens"])
    new_key = c["key"]
    cid = chord_id(mods, new_key)
    if cid in used:
        # try SHIFT tier same key
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
                continue
    used[cid] = c["src_line"]
    new_rest = apply_desc(c["kw"], c["rest"], new_key, None)
    note = None
    if new_key.upper() != c["key"].upper() or mods != preferred_vnc(c["tokens"]):
        note = f"{c['orig_mod']} + {c['key']} → {' '.join(mods)} + {new_key}"
    output.append({
        "line": f"{c['indent']}{c['kw']} = {' '.join(mods)}, {new_rest}",
        "comment": c["src_line"],
        "note": note,
        "explicit": False,
    })

lines = [
    "# AUTO-GENERATED by hypr-vnc-mod-gen.sh — do not edit",
    f"# {len(output)} unique VNC binds | failed: {len(failed)}",
    "# Super-only → Ctrl+Alt; Super+… → Ctrl+Alt+Shift or explicit remap (see notes).",
    "# During VNC: Super+K / Ctrl+Alt+K shows only these (keyhints).",
    "",
]
for o in output:
    lines.append(f"# from: {o['comment']}")
    if o.get("note"):
        lines.append(f"# VNC: {o['note']}")
    lines.append(o["line"])
    lines.append("")

if failed:
    lines.append("# --- FAILED ---")
    for c, why in failed:
        lines.append(f"# FAIL ({why}): {c['src_line'] if isinstance(c, dict) else c}")

out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"wrote {out_path}: {len(output)} binds, {len(failed)} failed")
for c, why in failed:
    print(" FAIL", why, c.get("src_line") if isinstance(c, dict) else c)

# verify no collisions + important chords
from collections import defaultdict
by = defaultdict(list)
text = out_path.read_text()
for line in text.splitlines():
    m = re.match(r"\s*bind[a-z]*\s*=\s*([^,]+),\s*([^,]+),(.*)$", line, re.I)
    if m:
        by[(m.group(1).strip().upper(), m.group(2).strip().upper())].append(line.strip()[:100])
cols = {k: v for k, v in by.items() if len(v) > 1}
print(f"collisions: {len(cols)}")
for k, v in cols.items():
    print(k, v)

print("\nKey map:")
for label, pat in [
    ("Launcher", r"CTRL ALT, SPACE,"),
    ("Browser", r"CTRL ALT, B,"),
    ("Theme switcher", r"Theme Switcher \(VNC\)"),
    ("Matugen", r"Matugen Themes \(VNC\)"),
    ("Wall picker", r"Wallpaper Picker \(VNC\)"),
    ("Waybar", r"Toggle waybar \(VNC\)|toggle-waybar"),
    ("Gemini", r"Gemini \(VNC\)"),
    ("EasyEffects", r"EasyEffects \(VNC\)"),
    ("Wall prev", r"Previous Wallpaper \(VNC\)"),
    ("Swap left", r"Swap window left \(VNC\)"),
    ("Lock", r"Lock screen \(VNC\)"),
    ("Reboot", r"Reboot \(VNC\)"),
]:
    hits = [ln.strip() for ln in text.splitlines() if re.search(pat, ln, re.I) and not ln.strip().startswith("#")]
    print(f"  {label}: {hits[0][:95] if hits else 'MISSING'}")
PY
