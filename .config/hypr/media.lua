-- Converted from media.conf (keep .conf as revert backup)
local home = os.getenv("HOME")
local terminal = "kitty"
local browser = home .. "/.config/hypr/scripts/launch-browser"
local browser2 = "zen-browser"
local webapp = home .. "/.config/hypr/scripts/launch-webapp"
local focus = home .. "/.config/hypr/scripts/focus"
local osdclient = "swayosd-client --monitor \"$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')\""
local rofiDir = home .. "/.config/rofi/scripts"
local scrDir = home .. "/.config/hypr/scripts"


hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(string.format("%s --output-volume raise", osdclient)), { description = "Volume up", repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(string.format("%s --output-volume lower", osdclient)), { description = "Volume down", repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(string.format("%s --output-volume mute-toggle", osdclient)), { description = "Mute", repeating = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(string.format("%s --input-volume mute-toggle", osdclient)), { description = "Mute microphone", repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(string.format("%s --brightness raise", osdclient)), { description = "Brightness up", repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(string.format("%s --brightness lower", osdclient)), { description = "Brightness down", repeating = true, locked = true })
hl.bind("ALT + XF86AudioRaiseVolume", hl.dsp.exec_cmd(string.format("%s --output-volume +1", osdclient)), { description = "Volume up precise", repeating = true, locked = true })
hl.bind("ALT + XF86AudioLowerVolume", hl.dsp.exec_cmd(string.format("%s --output-volume -1", osdclient)), { description = "Volume down precise", repeating = true, locked = true })
hl.bind("ALT + XF86MonBrightnessUp", hl.dsp.exec_cmd(string.format("%s --brightness +1", osdclient)), { description = "Brightness up precise", repeating = true, locked = true })
hl.bind("ALT + XF86MonBrightnessDown", hl.dsp.exec_cmd(string.format("%s --brightness -1", osdclient)), { description = "Brightness down precise", repeating = true, locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(string.format("%s --playerctl next", osdclient)), { description = "Next track", locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd(string.format("%s --playerctl play-pause", osdclient)), { description = "Pause", locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(string.format("%s --playerctl play-pause", osdclient)), { description = "Play", locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(string.format("%s --playerctl previous", osdclient)), { description = "Previous track", locked = true })
hl.bind("SUPER + XF86AudioMute", hl.dsp.exec_cmd(string.format("%s/audio-switch", scrDir)), { description = "Switch audio output", locked = true })
hl.bind("SUPER + F9", hl.dsp.exec_cmd("mpc pause"), { description = "mpc pause" })
hl.bind("SUPER + F10", hl.dsp.exec_cmd("mpc prev"), { description = "mpc prev" })
hl.bind("SUPER + F11", hl.dsp.exec_cmd("mpc play"), { description = "mpc play" })
hl.bind("SUPER + F12", hl.dsp.exec_cmd("mpc next"), { description = "MPC next track" })
