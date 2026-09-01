# Hyprluggage over VNC (wayvnc + browser gateways)

Super/Win is often swallowed by the local OS, browser, or Moonlight client. Hyprluggage ships a **Ctrl+Alt** twin of every Super bind for remote sessions.

## How it works
1. **wayvnc** shares the Hyprland session (systemd user: `wayvnc.service`).
2. On a real VNC client connect, **wayvnc-clipboard-bridge**:
   - pauses `cliphist` / `wl-clip-persist` (avoids Wayland data-device crashes)
   - runs `hypr-vnc-mod apply vnc` → loads `vnc-mod-generated.conf` via `vnc-mod-active.conf`
3. On VNC disconnect: restores clipboard helpers and drops the VNC hold. Hyprland reloads only if Sunshine is also idle.
4. **Sunshine** (Moonlight): `sunshine-mod-bridge` watches GameStream `/serverinfo` and runs `hypr-vnc-mod apply sunshine` while a stream is busy, then `clear sunshine` when it goes free. Same Ctrl+Alt twins as VNC.

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
Included in `install.sh` via packages (`wayvnc`) + `install/services.sh` (enable units). Sunshine's Ctrl+Alt twins are enabled when `sunshine` is installed. Install also adds `ufw allow 5900/tcp` (UFW is enabled only if it was already active). Units are `WantedBy=graphical-session.target` so they start with Hyprland, not at boot — binding them to `default.target` pulled in an empty graphical session and made UWSM/greetd refuse to start.

Manual:
```bash
hypr-vnc-mod ensure
systemctl --user enable wayvnc wayvnc-clipboard-bridge
systemctl --user enable sunshine-mod-bridge   # if Sunshine/Moonlight is installed
```

After changing Super binds:
```bash
hypr-vnc-mod generate   # refresh vnc-mod-generated.conf
# next VNC or Sunshine apply will also regenerate
```

## Files
| Path | Role |
|------|------|
| `~/.local/bin/hypr-vnc-mod` | apply / clear / generate / ensure (`vnc` or `sunshine` holders) |
| `~/.local/bin/hypr-vnc-mod-gen.sh` | generator |
| `~/.local/bin/sunshine-mod-bridge.sh` | load twins while a Moonlight stream is busy |
| `~/.config/hypr/vnc-mod-generated.conf` | committed seed map |
| `~/.local/state/hyprluggage/vnc-mod-active.conf` | runtime toggle (created by `ensure` / apply / clear; outside stow so git stays clean) |
| `~/.config/wayvnc/config` | listen `0.0.0.0:5900` |

`install/services.sh` runs `hypr-vnc-mod ensure` so the active stub exists before Hyprland sources it.

Install adds `ufw allow 5900/tcp`. On the **laptop** install profile, UFW is enabled; on **desktop**, the installer only turns UFW on if it was already active (`sudo ufw enable` otherwise).

## Virtual machines

Throwaway guests use the normal **Desktop** (or Laptop) profile — there is no separate VM profile.

Virt-specific defaults:

- **NVIDIA overlay** is not auto-applied under a hypervisor (`systemd-detect-virt`). A guest may still show NVIDIA in `lspci` (passthrough/compute) without that being Hyprland's display GPU; applying the overlay can gray out wayvnc. Opt in with `hyprluggage-hw-ensure set desktop nvidia` when you truly have a display NVIDIA in the guest.
- **wayvnc** skips `--gpu` when virt is detected and uses software capture so a missing render node does not take down the server. Bare metal keeps `--gpu`.

This is not a full headless/KVM cookbook — guest display topology stays machine-specific.
