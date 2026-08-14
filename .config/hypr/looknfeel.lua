-- Look and feel + layer blur (from looknfeel.conf)
-- Theme palette comes from ~/.config/hyprluggage/current/.../colors.lua

local home = os.getenv("HOME")
local colors_path = home .. "/.config/hyprluggage/current/.config/hypr/theme/colors.lua"

local colors = {
	secondary = "rgba(cba6f7aa)",
	outline_variant = "rgba(45475aaa)",
}

do
	local ok, result = pcall(dofile, colors_path)
	if ok and type(result) == "table" then
		colors = result
	end
end

local active = colors.active_border or colors.secondary
local inactive = colors.outline_variant or "rgba(45475aaa)"

local decoration = {
	rounding = 10,
	blur = {
		enabled = true,
		size = 7,
		passes = 4,
		ignore_opacity = true,
		noise = 0.0117,
		contrast = 0.8916,
		brightness = 0.8172,
		xray = false,
		popups = true,
	},
}

if type(colors.shadow) == "table" then
	decoration.shadow = colors.shadow
end

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 12,
		border_size = 2,
		col = {
			active_border = active,
			inactive_border = inactive,
		},
		resize_on_border = true,
	},
	decoration = decoration,
	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = true,
		anr_missed_pings = 3,
		on_focus_under_fullscreen = 1,
	},
})

if colors.group_border_active then
	hl.config({
		group = {
			col = {
				border_active = colors.group_border_active,
			},
		},
	})
end

-- Layer blur / animations
hl.layer_rule({ match = { namespace = "rofi" }, blur = true, ignore_alpha = 0, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "swayosd" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "mako" }, blur = true, ignore_alpha = 0, animation = "slide right" })
hl.layer_rule({ match = { namespace = "mako" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })

hl.env("GUM_CONFIRM_PROMPT_FOREGROUND", "6")
hl.env("GUM_CONFIRM_SELECTED_FOREGROUND", "0")
hl.env("GUM_CONFIRM_SELECTED_BACKGROUND", "2")
hl.env("GUM_CONFIRM_UNSELECTED_FOREGROUND", "0")
hl.env("GUM_CONFIRM_UNSELECTED_BACKGROUND", "8")
