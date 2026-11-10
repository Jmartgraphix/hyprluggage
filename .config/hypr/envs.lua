-- Environment + xwayland
-- hl.env only applies at compositor launch, not on reload.
-- Per-machine QT/HiDPI overrides: ~/.local/state/hyprluggage/envs-local.lua
-- (see: hyprluggage host envs)

local home = os.getenv("HOME") or ""

hl.env("MPD_HOST", home .. "/.config/mpd/socket")
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
