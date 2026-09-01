#!/usr/bin/env bash
# On Sunshine/Moonlight streams:
#   - load CTRL+ALT twins of SUPER Hyprland binds (Super often missing on clients)
# On disconnect: drop the Sunshine hold (VNC can keep the same binds).
set -euo pipefail
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export PATH="$HOME/.local/bin:/usr/bin:/bin:$PATH"
if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
  for d in wayland-1 wayland-0; do
    [[ -S "${XDG_RUNTIME_DIR}/${d}" ]] && export WAYLAND_DISPLAY="$d" && break
  done
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"
fi

VNCMOD="$HOME/.local/bin/hypr-vnc-mod"
SUNSHINE_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/sunshine/sunshine.conf"
POLL_SEC=1
CLEAR_AFTER=2

sunshine_port() {
  local p
  p="$(awk -F= '/^[[:space:]]*port[[:space:]]*=/{gsub(/[[:space:]]/,"",$2); print $2; exit}' "$SUNSHINE_CONF" 2>/dev/null || true)"
  printf '%s\n' "${p:-47989}"
}

# GameStream /serverinfo: FREE when idle, BUSY while a Moonlight session is up.
sunshine_busy() {
  local xml
  xml="$(curl -fsS -m 1 --noproxy '*' "http://127.0.0.1:$(sunshine_port)/serverinfo" 2>/dev/null || true)"
  [[ "$xml" == *"<state>SUNSHINE_SERVER_BUSY</state>"* ]]
}

if [[ ! -x "$VNCMOD" ]]; then
  logger -t sunshine-vncmod "hypr-vnc-mod not found; bridge idle"
  exec sleep infinity
fi

"$VNCMOD" ensure || true

prev=""
idle=0
if sunshine_busy; then
  "$VNCMOD" apply sunshine || true
  logger -t sunshine-vncmod "applied CTRL+ALT Sunshine mod binds"
  prev="busy"
else
  # Drop a stale Sunshine hold from a previous bridge instance without touching VNC.
  "$VNCMOD" clear sunshine || true
  prev="free"
fi

while true; do
  if sunshine_busy; then
    idle=0
    if [[ "$prev" != "busy" ]]; then
      "$VNCMOD" apply sunshine || true
      logger -t sunshine-vncmod "applied CTRL+ALT Sunshine mod binds"
      prev="busy"
    fi
  elif [[ "$prev" == "busy" ]]; then
    idle=$((idle + 1))
    if [[ "$idle" -ge "$CLEAR_AFTER" ]]; then
      "$VNCMOD" clear sunshine || true
      logger -t sunshine-vncmod "cleared Sunshine hold on remote binds"
      prev="free"
      idle=0
    fi
  else
    prev="free"
  fi
  sleep "$POLL_SEC"
done
