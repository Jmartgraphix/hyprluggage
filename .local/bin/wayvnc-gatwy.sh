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
# --gpu is the right default on a real NVIDIA display.
# Under the VM profile it often fails to open a render node (passthrough
# compute cards, virt connectors). Software capture still shares the session.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprluggage"
use_gpu=1
if [[ -f "$STATE_DIR/profile" ]] && [[ "$(tr -d '[:space:]' <"$STATE_DIR/profile")" == "vm" ]]; then
  use_gpu=0
fi

# Default no-auth on LAN; put TLS/auth in ~/.config/wayvnc/config if desired
if [[ "$use_gpu" -eq 1 ]]; then
  exec /usr/bin/wayvnc --gpu --log-level info --disable-resizing 0.0.0.0
else
  exec /usr/bin/wayvnc --log-level info --disable-resizing 0.0.0.0
fi
