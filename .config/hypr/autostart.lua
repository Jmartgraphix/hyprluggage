-- Autostart (from autostart.conf)
-- exec-once → hyprland.start; bare exec → top-level (every reload)

hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	hl.exec_cmd('systemctl --user import-environment $(env | cut -d\'=\' -f1)')
	hl.exec_cmd("wl-clip-persist --clipboard regular")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("awww-daemon")

	-- Idle off on login (streaming-safe desktop default). Laptop profile starts hypridle after.
	hl.exec_cmd("pkill hypridle")

	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
	hl.exec_cmd("kdeconnect-indicator")
	hl.exec_cmd("/usr/lib/kdeconnectd")

	-- Delay waybar until Hyprland IPC is ready
	hl.exec_cmd("sleep 1 && uwsm app -- waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd(os.getenv("HOME") .. "/.config/hypr/scripts/first-run")
end)

-- Runs on every config reload (old `exec =`)
hl.exec_cmd("nextcloud")
