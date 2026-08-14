-- Hyprluggage NVIDIA GPU overlay (desktop or laptop)
-- Applied on bare-metal NVIDIA display GPUs. Virtual machines leave this off by
-- default (passthrough/compute cards are often not Hyprland's scanout device).
-- Force it with: hyprluggage-hw-ensure set <desktop|laptop> nvidia

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("WLR_NO_HARDWARE_CURSORS", "1")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("__GL_MaxFramesAllowed", "1")
hl.env("__GL_SHADER_DISK_CACHE", "1")

hl.config({
	cursor = {
		no_hardware_cursors = true,
	},
})
