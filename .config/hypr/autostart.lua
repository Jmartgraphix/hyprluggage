-- Autostart
-- Session daemons (waybar, mako, swayosd, awww, cliphist, wl-clip-persist,
-- polkit agent, KDE Connect) run as systemd --user units via
-- hyprluggage-session.target. Keep only env bootstrap + one-shots here.

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd('systemctl --user import-environment $(env | cut -d\'=\' -f1)')

	-- Idle off on login (streaming-safe desktop default). Laptop profile starts hypridle after.
	hl.exec_cmd("pkill hypridle")

	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/first-run")
end)
