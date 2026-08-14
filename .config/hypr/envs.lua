-- Environment + xwayland (from envs.conf)
-- hl.env only applies at compositor launch, not on reload.

local uid = "1000"
do
	local xrd = os.getenv("XDG_RUNTIME_DIR") or ""
	uid = xrd:match("/run/user/(%d+)") or os.getenv("UID") or "1000"
end

hl.env("MPD_HOST", "/run/user/" .. uid .. "/mpd/socket")
hl.env("EDITOR", "nvim")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.env("QT_SCALE_FACTOR", "1.5")

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},
})
