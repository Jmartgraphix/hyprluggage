#!/usr/bin/env bash
# Start/stop Hyprland clipboard helpers used with cliphist (systemd --user units).
# cliphist skips copies marked sensitive (x-kde-passwordManagerHint). The
# cliphist.service ExecStart keeps wl-paste unwrapped so CLIPBOARD_STATE reaches cliphist.
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

STATE_DIR="${XDG_RUNTIME_DIR}/wayvnc-clipboard"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/paused"

UNITS=(wl-clip-persist.service cliphist.service)

units_active() {
  local u
  for u in "${UNITS[@]}"; do
    systemctl --user is-active --quiet "$u" 2>/dev/null && return 0
  done
  return 1
}

pause() {
  if [[ -f "$STATE_FILE" ]]; then
    return 0
  fi
  systemctl --user stop "${UNITS[@]}" 2>/dev/null || true
  touch "$STATE_FILE"
  logger -t wayvnc-clipboard "paused clipboard helpers for VNC session"
}

resume() {
  if [[ ! -f "$STATE_FILE" ]]; then
    if ! units_active; then
      systemctl --user start "${UNITS[@]}" 2>/dev/null || true
      logger -t wayvnc-clipboard "started clipboard helpers (were not running)"
    fi
    return 0
  fi
  rm -f "$STATE_FILE"
  # Small delay so wayvnc releases data-control cleanly
  sleep 0.4
  systemctl --user stop "${UNITS[@]}" 2>/dev/null || true
  sleep 0.2
  systemctl --user start "${UNITS[@]}" 2>/dev/null || true
  logger -t wayvnc-clipboard "resumed clipboard helpers after VNC"
}

case "${1:-}" in
  pause) pause ;;
  resume) resume ;;
  status)
    if [[ -f "$STATE_FILE" ]]; then echo "paused"; else echo "active"; fi
    for u in "${UNITS[@]}"; do
      if systemctl --user is-active --quiet "$u" 2>/dev/null; then
        echo "$u: active"
      else
        echo "$u: inactive"
      fi
    done
    ;;
  *)
    echo "Usage: $0 {pause|resume|status}" >&2
    exit 1
    ;;
esac
