-- Hyprland injects the global `hl` API into config Lua.
std = "lua54"
globals = { "hl" }
-- Bind / exec_cmd lines are intentionally long one-liners.
max_line_length = false
files[".config/hypr/"] = { std = "lua54" }
-- Generated VNC twins: preamble locals mirror sources; unused is expected.
files[".config/hypr/vnc-mod-generated.lua"] = { ignore = { "211", "212" } }
exclude_files = { "themes/", "**/node_modules/" }
