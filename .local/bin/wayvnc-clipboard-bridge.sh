#!/usr/bin/env bash
# On real VNC sessions (debounced):
#   - pause clipboard helpers (avoid wayvnc data-device crash with cliphist)
#   - load CTRL+ALT twins of SUPER Hyprland binds (Super often blocked in browser)
# On disconnect: reverse both (Sunshine can keep the same binds held).
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export PATH="$HOME/.local/bin:/usr/bin:/bin:$PATH"
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  for d in wayland-1 wayland-0; do
    [[ -S "${XDG_RUNTIME_DIR}/${d}" ]] && export WAYLAND_DISPLAY="$d" && break
  done
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
fi

DEBOUNCE_SEC=2
HELPERS="$HOME/.local/bin/clipboard-helpers.sh"
VNCMOD="$HOME/.local/bin/hypr-vnc-mod"
pending_pid=""

cancel_pending() {
  if [[ -n "${pending_pid}" ]] && kill -0 "$pending_pid" 2>/dev/null; then
    kill "$pending_pid" 2>/dev/null || true
    wait "$pending_pid" 2>/dev/null || true
  fi
  pending_pid=""
}

client_count() {
  wayvncctl --json client-list 2>/dev/null | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
except Exception:
    print(0); raise SystemExit
if isinstance(d, list):
    print(len(d))
elif isinstance(d, dict):
    if "clients" in d and isinstance(d["clients"], list):
        print(len(d["clients"]))
    else:
        print(int(d.get("connection_count") or d.get("count") or 0))
else:
    print(0)
' 2>/dev/null || echo 0
}

enter_vnc_mode() {
  "$HELPERS" pause || true
  "$VNCMOD" apply vnc || true
}

leave_vnc_mode() {
  "$VNCMOD" clear vnc || true
  "$HELPERS" resume || true
}

schedule_enter() {
  cancel_pending
  (
    sleep "$DEBOUNCE_SEC"
    count="$(client_count)"
    if [[ "${count:-0}" =~ ^[0-9]+$ ]] && [[ "$count" -gt 0 ]]; then
      enter_vnc_mode
    fi
  ) &
  pending_pid=$!
}

# Ensure generator seed + desktop mode on bridge start
"$VNCMOD" ensure || true
leave_vnc_mode || true

if ! command -v wayvncctl >/dev/null 2>&1; then
  logger -t wayvnc-clipboard "wayvncctl not found; bridge idle"
  # Keep unit running so Restart= doesn't spin
  exec sleep infinity
fi

wayvncctl --json --wait --reconnect event-receive | while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  method="$(printf '%s' "$line" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("method",""))' 2>/dev/null || true)"
  count="$(printf '%s' "$line" | python3 -c 'import sys,json; p=json.load(sys.stdin).get("params") or {}; print(p.get("connection_count",""))' 2>/dev/null || true)"

  case "$method" in
    client-connected)
      if [[ "${count:-0}" =~ ^[0-9]+$ ]] && [[ "$count" -ge 1 ]]; then
        schedule_enter
      fi
      ;;
    client-disconnected)
      cancel_pending
      if [[ "${count:-0}" =~ ^[0-9]+$ ]] && [[ "$count" -eq 0 ]]; then
        leave_vnc_mode
      fi
      ;;
    wayvnc-shutdown|wayvnc-startup)
      cancel_pending
      leave_vnc_mode
      ;;
  esac
done
