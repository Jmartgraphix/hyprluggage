# Hyprluggage over VNC (wayvnc + browser gateways)

Super/Win is often swallowed by the local OS, browser, or Moonlight client. Hyprluggage ships a **Ctrl+Alt** twin of every Super bind for remote sessions.

## How it works
1. **wayvnc** shares the Hyprland session (systemd user: `wayvnc.service`).
2. **Ctrl+Alt twins stay loaded** for the whole session (`hypr-vnc-mod ensure` at login sources `vnc-mod-generated.lua`). Reloading Hyprland on each Gatwy connect was breaking wayvnc’s virtual keyboard.
3. On a real VNC client connect, **wayvnc-clipboard-bridge** pauses the `cliphist` / `wl-clip-persist` **user units** and marks a VNC holder (no compositor reload).
4. On VNC disconnect: starts those clipboard units again. Twins stay loaded.
5. **Sunshine** (Moonlight): `sunshine-mod-bridge` marks/clears a Sunshine holder the same way. Same Ctrl+Alt chords.

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

## Multiple monitors

wayvnc shows **one** Hyprland output at a time. If Cursor (or another window) is on a different monitor than Gatwy is capturing, you will not see it remotely.

```bash
wayvncctl output-list          # which output is captured
wayvncctl output-set DP-1      # capture a named output
wayvncctl output-cycle         # next output
```

On startup, [wayvnc-gatwy.sh](../../.local/bin/wayvnc-gatwy.sh) prefers the **focused** monitor.

## Fresh install
Included in `install.sh` via packages (`wayvnc`) + `install/services.sh` (enable units). Sunshine's Ctrl+Alt twins are enabled when `sunshine` is installed. The installer does not add a world-open `ufw allow 5900/tcp`; wayvnc has no RFB auth and Gatwy cannot complete wayvnc's TLS auth, so allow 5900 only from the Gatwy host. Units are `WantedBy=graphical-session.target` so they start with Hyprland, not at boot — binding them to `default.target` pulled in an empty graphical session and made UWSM/greetd refuse to start.

Manual:
```bash
hypr-vnc-mod ensure
systemctl --user enable wayvnc wayvnc-clipboard-bridge
systemctl --user enable --now sunshine-mod-bridge   # if Sunshine/Moonlight is installed
```

After changing Super binds:
```bash
hypr-vnc-mod generate   # refresh vnc-mod-generated.lua from bindings/tiling/media/monitors.lua
# eDP Super+Alt laptop binds stay in shared monitors.lua (host layout is monitors-local.lua)
# next VNC or Sunshine apply will also regenerate
```

## Files
| Path | Role |
|------|------|
| `~/.local/bin/hypr-vnc-mod` | apply / clear / generate / ensure (`vnc` or `sunshine` holders) |
| `~/.local/bin/hypr-vnc-mod-gen.sh` | generator (reads Lua Super binds) |
| `~/.local/bin/sunshine-mod-bridge.sh` | load twins while a Moonlight stream is busy |
| `~/.config/hypr/vnc-mod-generated.lua` | committed seed map |
| `~/.local/state/hyprluggage/vnc-mod-active.lua` | runtime toggle (created by `ensure` / apply / clear; outside stow so git stays clean) |
| `~/.config/wayvnc/config` | listen `0.0.0.0:5900` |

`install/services.sh` runs `hypr-vnc-mod ensure` so the active stub exists before Hyprland sources it.

The installer does not open port 5900. On the **laptop** install profile, UFW is enabled; on **desktop**, the installer only turns UFW on if it was already active (`sudo ufw enable` otherwise).

## Virtual machines

Throwaway guests use the normal **Desktop** (or Laptop) profile — there is no separate VM profile.

Virt-specific defaults:

- **NVIDIA overlay** is not auto-applied under a hypervisor (`systemd-detect-virt`). A guest may still show NVIDIA in `lspci` (passthrough/compute) without that being Hyprland's display GPU; applying the overlay can gray out wayvnc. Opt in with `hyprluggage-hw-ensure set desktop nvidia` when you truly have a display NVIDIA in the guest.
- **wayvnc** skips `--gpu` when virt is detected and uses software capture so a missing render node does not take down the server. Bare metal keeps `--gpu`.

This is not a full headless/KVM cookbook — guest display topology stays machine-specific.
