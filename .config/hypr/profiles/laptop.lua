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
})

-- Hybrid lid: suspend if no external monitor; clamshell if docked
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd(home .. "/.config/hypr/scripts/lid-open"), { locked = true })
