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
| Theme switcher | **Ctrl+Alt+Shift+Y** |
| Wallpaper picker | **Ctrl+Alt+Shift+Space** |

At the physical keyboard, Super is unchanged.

## Fresh install
Included in `install.sh` via packages (`wayvnc`) + `install/services.sh` (enable units).

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
| `~/.config/hypr/vnc-mod-active.conf` | empty in git; toggled at runtime |
| `~/.config/wayvnc/config` | listen `0.0.0.0:5900` |

Firewall port **5900** if the host is not only on a trusted LAN or reverse proxy.
