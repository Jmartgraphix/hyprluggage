# Hyprluggage over VNC (wayvnc + browser gateways)

Super/Win is often swallowed by the local OS or browser. Hyprluggage ships a **Ctrl+Alt** twin of every Super bind for remote sessions.

## How it works
1. **wayvnc** shares the Hyprland session (systemd user: `wayvnc.service`).
2. On a real client connect, **wayvnc-clipboard-bridge**:
   - pauses `cliphist` / `wl-clip-persist` (avoids Wayland data-device crashes)
   - runs `hypr-vnc-mod apply` → loads `vnc-mod-generated.conf` via `vnc-mod-active.conf`
3. On disconnect: restores clipboard helpers and clears VNC binds (`hyprctl reload`).

## Keys (remote)
| Action | Keys |
|--------|------|
| Super (generic) | **Ctrl+Alt** + same key |
| Keybind list | **Ctrl+Alt+K** |
| Launcher | **Ctrl+Alt+Space** |
| Theme switcher | **Ctrl+Alt+Shift+Y** (Super+Ctrl+Shift+Space) |
| Theme Matugen apply | **Ctrl+Alt+Shift+T** (Super+Ctrl+Space) |
| Theme wallpaper picker | **Ctrl+Alt+Shift+Space** (Super+Alt+Space) |
| Theme random wallpaper | **Ctrl+Alt+Shift+G** (Super+Ctrl+Alt+Space) |
| Theme browse | **Ctrl+Alt+Shift+U** (Super+Alt+I) |
| Theme Hyprluggage TUI | **Ctrl+Alt+I** (Super+I) |
| Theme wallpapers cycle | **Ctrl+Alt+Shift+Up/Left/Right** (Super+Alt+arrows) |

Space-family Super chords collide under Ctrl+Alt, so several theme binds are **remapped** to letter keys. Search **theme** in Ctrl+Alt+K to list them all.

At the physical keyboard, Super is unchanged.

## Fresh install
Included in `install.sh` via packages (`wayvnc`) + `install/services.sh` (enable units). Install also adds `ufw allow 5900/tcp` (UFW is enabled only if it was already active).

Manual:
```bash
hypr-vnc-mod ensure
systemctl --user enable --now wayvnc wayvnc-clipboard-bridge
```

After changing Super binds:
```bash
hypr-vnc-mod generate   # refresh vnc-mod-generated.conf
# next VNC session apply will also regenerate
```

## Files
| Path | Role |
|------|------|
| `~/.local/bin/hypr-vnc-mod` | apply / clear / generate / ensure |
| `~/.local/bin/hypr-vnc-mod-gen.sh` | generator |
| `~/.config/hypr/vnc-mod-generated.conf` | committed seed map |
| `~/.local/state/hyprluggage/vnc-mod-active.conf` | runtime toggle (created by `ensure` / apply / clear; outside stow so git stays clean) |
| `~/.config/wayvnc/config` | listen `0.0.0.0:5900` |

`install/services.sh` runs `hypr-vnc-mod ensure` so the active stub exists before Hyprland sources it.

Install adds `ufw allow 5900/tcp`. Enable UFW yourself if you want that rule enforced (`sudo ufw enable`); the installer only turns UFW on if it was already active.
