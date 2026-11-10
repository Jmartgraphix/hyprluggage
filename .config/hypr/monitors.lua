-- Shared monitor defaults (stowed). Per-machine layout lives in
-- ~/.local/state/hyprluggage/monitors-local.lua — see: hyprluggage monitors path
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Laptop: toggle built-in eDP (shared binds; safe no-ops on desktop without eDP)
hl.bind("SUPER + ALT + H", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1,disable"'), { description = "Laptop screen off" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd('hyprctl keyword monitor "eDP-1,preferred,auto,1"'), { description = "Laptop screen on" })
