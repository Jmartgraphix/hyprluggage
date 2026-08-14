-- Converted from monitors.conf
local home = os.getenv("HOME")
local terminal = "kitty"
local browser = home .. "/.config/hypr/scripts/launch-browser"
local browser2 = "zen-browser"
local webapp = home .. "/.config/hypr/scripts/launch-webapp"
local focus = home .. "/.config/hypr/scripts/focus"
local osdclient = "swayosd-client --monitor \"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')\""
local rofiDir = home .. "/.config/rofi/scripts"
local scrDir = home .. "/.config/hypr/scripts"


hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "DP-1", mode = "preferred", position = "auto-left", scale = 1.6 })
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto-right", scale = 1.6 })
hl.monitor({ output = "HDMI-A-2", mode = "preferred", position = "auto", scale = 1.6, mirror = "DP-1" })
hl.monitor({ output = "DVI-I-1", disabled = true })

hl.bind("SUPER + ALT + H", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1,disable\""), { description = "Laptop screen off" })
hl.bind("SUPER + ALT + l", hl.dsp.exec_cmd("hyprctl keyword monitor \"eDP-1,preferred,0x0,1\""), { description = "Laptop screen on" })
hl.window_rule({ match = { class = "^(chrome-perplexity.ai__-Default)$" }, workspace = 3 })
hl.window_rule({ match = { class = "^(chrome-web.whatsapp.com__-Default)$" }, workspace = 5 })
hl.window_rule({ match = { class = "^(chrome-netflix.com__in-Default)$" }, workspace = 6 })
hl.window_rule({ match = { class = "(org.telegram.desktop)" }, workspace = 6 })
hl.window_rule({ match = { class = "^(chrome-app.todoist.com__-Default)$" }, workspace = 7 })
hl.window_rule({ match = { class = "(obsidian)" }, workspace = 8 })
hl.window_rule({ match = { class = "(spotify)" }, workspace = 9 })
hl.window_rule({ match = { class = "(vesktop)" }, workspace = 10 })
