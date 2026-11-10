-- Input / cursor / gestures

hl.config({
	cursor = {
		inactive_timeout = 1,
	},
	input = {
		kb_options = "compose:ralt",
		follow_mouse = 1,
		numlock_by_default = true,
		sensitivity = 0.0,
		touchpad = {
			natural_scroll = false,
			scroll_factor = 0.4,
		},
		-- wayvnc/Gatwy: client disconnect mid-chord leaves mods held on the
		-- virtual keyboard. Release them on close, and don't merge VKBD key
		-- state into physical keyboards (avoids seat-wide sticky Super/Ctrl).
		virtualkeyboard = {
			release_pressed_on_close = true,
			share_states = false,
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
