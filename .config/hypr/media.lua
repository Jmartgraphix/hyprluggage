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


-- One bind per knob key. Lua's extra-mod matching was firing volume AND brightness
-- together (Super+Alt hit swayosd + wpctl, and often ddcutil too).
-- hl.is_key_down() takes XKB keysyms (Super_L), not bind masks (SUPER).
local function super_down()
	return hl.is_key_down("Super_L") or hl.is_key_down("Super_R")
end

local function alt_down()
	return hl.is_key_down("Alt_L") or hl.is_key_down("Alt_R")
end

local function osd(args)
	local mon = hl.get_active_monitor()
	local name = mon and mon.name
	local cmd
	if type(name) == "string" and name ~= "" then
		cmd = string.format("swayosd-client --monitor %s %s", name, args)
	else
		cmd = "swayosd-client " .. args
	end
	hl.dispatch(hl.dsp.exec_cmd(cmd))
end

local function ddc(dir)
	local mon = hl.get_active_monitor()
	local name = (mon and mon.name) or ""
	local sign = dir > 0 and "+" or "-"
	hl.dispatch(hl.dsp.exec_cmd(string.format("%s/ddc-brightness %s %s", scrDir, sign, name)))
end

local function knob(dir)
	local super = super_down()
	local alt = alt_down()
	-- Super or Super+Alt: DDC on the focused monitor (no laptop backlight here).
	-- Alt alone stays precise volume.
	if super then
		ddc(dir)
	elseif alt then
		osd(dir > 0 and "--output-volume +1" or "--output-volume -1")
	else
		osd(dir > 0 and "--output-volume raise" or "--output-volume lower")
	end
end

hl.bind("XF86AudioRaiseVolume", function()
	knob(1)
end, {
	description = "Volume / brightness up",
	ignore_mods = true,
	repeating = true,
	locked = true,
	dont_inhibit = true,
	allow_input_capture = true,
})
hl.bind("XF86AudioLowerVolume", function()
	knob(-1)
end, {
	description = "Volume / brightness down",
	ignore_mods = true,
	repeating = true,
	locked = true,
	dont_inhibit = true,
	allow_input_capture = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(string.format("%s --output-volume mute-toggle", osdclient)), { description = "Mute", repeating = true, locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(string.format("%s --input-volume mute-toggle", osdclient)), { description = "Mute microphone", repeating = true, locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(string.format("%s --brightness raise", osdclient)), { description = "Brightness up", repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(string.format("%s --brightness lower", osdclient)), { description = "Brightness down", repeating = true, locked = true })
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
