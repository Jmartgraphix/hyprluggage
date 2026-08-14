-- Input / cursor / gestures (from input.conf)

hl.config({
	cursor = {
		inactive_timeout = 1,
	},
	input = {
		kb_options = "compose:ralt",
		follow_mouse = 1,
		numlock_by_default = true,
		sensitivity = 0.40,
		touchpad = {
			natural_scroll = false,
			scroll_factor = 0.4,
		},
	},
	misc = {
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = true,
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})
