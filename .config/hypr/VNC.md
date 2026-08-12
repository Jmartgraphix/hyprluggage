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

Install adds `ufw allow 5900/tcp`. On the **laptop** install profile, UFW is enabled; on **desktop** and **vm**, the installer only turns UFW on if it was already active (`sudo ufw enable` otherwise).

## Virtual machines

The **vm** install profile is optional and sits next to desktop/laptop. It keeps the same idle policy as desktop (hypridle stays off) and skips the NVIDIA gaming overlay unless you opt in.

That matters for remote sessions:

- `wayvnc --gpu` is still the default on desktop/laptop. On **vm**, wayvnc uses software capture so a missing render node does not take down the server.
- Hyprland's NVIDIA env (`LIBVA` / `GBM_BACKEND=nvidia-drm` / `__GLX_VENDOR_LIBRARY_NAME=nvidia`) is meant for a GeForce with a real display. In a VM, `lspci` may still show an NVIDIA 3D/compute device; applying that overlay can make wayvnc show a solid gray frame (compositor renders on NVIDIA, scanout is on a virt connector).
- If you *do* have a display NVIDIA in the guest and want the overlay: `hyprluggage-hw-ensure set vm nvidia`.

This is not a full headless/KVM cookbook — guest display topology (virtio, vkms, looking-glass, …) stays machine-specific.
