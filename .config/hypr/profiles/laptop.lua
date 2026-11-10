-- Hyprluggage laptop profile overlay
-- Starts after shared autostart (which pkill's hypridle for desktop safety)

local home = os.getenv("HOME")

hl.on("hyprland.start", function()
	hl.exec_cmd("uwsm-app -- hypridle")
	hl.exec_cmd(home .. "/.config/hypr/scripts/battery-notify")
end)

hl.config({
	input = {
		touchpad = {
			tap = true,
		},
	},
	-- Lighter blur than the shared look. Desktop keeps size 7 / 4 passes.
	decoration = {
		blur = {
			size = 8,
			passes = 2,
		},
	},
})

-- Hybrid lid: suspend if no external monitor; clamshell if docked
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/lid-open"), { locked = true })

-- Built-in panel toggle (discovers eDP|LVDS|DSI; no-op if absent)
hl.bind("SUPER + ALT + H", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/laptop-panel off"), { description = "Laptop screen off" })
hl.bind("SUPER + ALT + L", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/laptop-panel on"), { description = "Laptop screen on" })
