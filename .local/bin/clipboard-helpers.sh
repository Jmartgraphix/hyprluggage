#!/usr/bin/env bash
# Start/stop Hyprland clipboard helpers used with cliphist.
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
export PATH="/usr/bin:/bin:/usr/local/bin:$PATH"

STATE_DIR="${XDG_RUNTIME_DIR}/wayvnc-clipboard"
mkdir -p "$STATE_DIR"
STATE_FILE="$STATE_DIR/paused"

is_running() {
  pgrep -u "$(id -u)" -x wl-clip-persist >/dev/null 2>&1 \
    || pgrep -u "$(id -u)" -f "wl-paste --watch cliphist store" >/dev/null 2>&1
}

pause() {
  if [[ -f "$STATE_FILE" ]]; then
    return 0
  fi
  # Record that we paused so we only resume what we stopped
  pkill -u "$(id -u)" -x wl-clip-persist 2>/dev/null || true
  pkill -u "$(id -u)" -f "wl-paste --watch cliphist store" 2>/dev/null || true
  touch "$STATE_FILE"
  logger -t wayvnc-clipboard "paused clipboard helpers for VNC session"
}

resume() {
  if [[ ! -f "$STATE_FILE" ]]; then
    # Still ensure helpers are up for day-to-day use
    if ! is_running; then
      nohup wl-clip-persist --clipboard regular >/dev/null 2>&1 &
      nohup wl-paste --watch cliphist store >/dev/null 2>&1 &
      logger -t wayvnc-clipboard "started clipboard helpers (were not running)"
    fi
    return 0
  fi
  rm -f "$STATE_FILE"
  # Small delay so wayvnc releases data-control cleanly
  sleep 0.4
  pkill -u "$(id -u)" -x wl-clip-persist 2>/dev/null || true
  pkill -u "$(id -u)" -f "wl-paste --watch cliphist store" 2>/dev/null || true
  sleep 0.2
  nohup wl-clip-persist --clipboard regular >/dev/null 2>&1 &
  nohup wl-paste --watch cliphist store >/dev/null 2>&1 &
  logger -t wayvnc-clipboard "resumed clipboard helpers after VNC"
}

case "${1:-}" in
  pause) pause ;;
  resume) resume ;;
  status)
    if [[ -f "$STATE_FILE" ]]; then echo "paused"; else echo "active"; fi
    pgrep -u "$(id -u)" -a -x wl-clip-persist 2>/dev/null || echo "wl-clip-persist: not running"
    pgrep -u "$(id -u)" -af "wl-paste --watch cliphist" 2>/dev/null || echo "wl-paste/cliphist: not running"
    ;;
  *)
    echo "Usage: $0 {pause|resume|status}" >&2
    exit 1
    ;;
esac
