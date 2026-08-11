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
# Default no-auth on LAN; put TLS/auth in ~/.config/wayvnc/config if desired
exec /usr/bin/wayvnc --gpu --log-level info --disable-resizing 0.0.0.0
