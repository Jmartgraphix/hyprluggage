#!/usr/bin/env bash
# wayvnc for browser remote (Gatwy/noVNC). Clipboard managed by wayvnc-clipboard-bridge.
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  for d in wayland-1 wayland-0; do
    if [[ -S "${XDG_RUNTIME_DIR}/${d}" ]]; then
      export WAYLAND_DISPLAY="$d"
      break
    fi
  done
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
fi

# --gpu is the right default on a real display GPU.
# Under virt it often fails to open a render node (or paints gray when Hyprland
# and scanout disagree). Software capture still shares the session.
in_vm=0
if command -v systemd-detect-virt >/dev/null 2>&1 && systemd-detect-virt -q; then
  in_vm=1
elif grep -q hypervisor /proc/cpuinfo 2>/dev/null; then
  in_vm=1
fi

# Default no-auth on LAN; put TLS/auth in ~/.config/wayvnc/config if desired
if [[ "$in_vm" -eq 1 ]]; then
  exec /usr/bin/wayvnc --log-level info --disable-resizing 0.0.0.0
else
  exec /usr/bin/wayvnc --gpu --log-level info --disable-resizing 0.0.0.0
fi
