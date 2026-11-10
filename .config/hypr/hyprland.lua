-- Hyprluggage Hyprland config (Lua)
-- https://wiki.hypr.land/Configuring/Start/
--
-- Hyprland entry (Lua-only). Rollback to a tagged release if you need an older tree.

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

-- Host overlays under ~/.local/state/hyprluggage/ (never written by update/stow)
local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hyprluggage"
-- Per-machine monitor layout (after shared catch-all in monitors.lua)
pcall(dofile, state .. "/monitors-local.lua")
-- Per-machine env/HiDPI (after shared envs.lua); see: hyprluggage host envs
pcall(dofile, state .. "/envs-local.lua")
pcall(dofile, state .. "/profile.lua")
pcall(dofile, state .. "/gpu.lua")

-- VNC/Sunshine: Ctrl+Alt Super twins (hypr-vnc-mod); stub lives outside stow
pcall(dofile, state .. "/vnc-mod-active.lua")
