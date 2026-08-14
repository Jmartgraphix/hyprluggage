-- Hyprluggage Hyprland config (Lua)
-- https://wiki.hypr.land/Configuring/Start/
--
-- If this file exists at compositor start, hyprland.conf is ignored.
-- To revert: rename/remove this file and restart Hyprland (logout).

hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")

require("monitors")
require("input")
require("bindings")
require("envs")
require("looknfeel")
require("autostart")
require("animations")
require("windowsrules")
require("tiling")
require("media")

-- Form factor + GPU overlays (stubs under ~/.local/state/hyprluggage/)
local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hyprluggage"
pcall(dofile, state .. "/profile.lua")
pcall(dofile, state .. "/gpu.lua")

-- VNC: Ctrl+Alt Super twins (hypr-vnc-mod); stub lives outside stow
pcall(dofile, state .. "/vnc-mod-active.lua")
