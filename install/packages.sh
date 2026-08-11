#!/bin/bash
#|---/ /+---------------------+---/ /|#
#|--/ /-| Hyprluggage         |--/ /-|#
#|-/ /--| Package Installer   |-/ /--|#
#|/ /---+---------------------+/ /---|#

# ╭───────────────────────────────────────────────────────────────────────╮
# │ Core Packages                                                         │
# ╰───────────────────────────────────────────────────────────────────────╯

packages=(
	# Build
	base-devel git stow

	# Hyprland
	hyprland hypridle hyprlock hyprpicker hyprsunset
	xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
	qt5-wayland qt6-wayland uwsm

	# Desktop
	waybar rofi mako swayosd awww wlogout brave-bin wayvnc

	# Terminal & Shell
	kitty alacritty fish starship tmux

	# CLI Tools
	eza bat fd ripgrep fzf zoxide jq

	# Files
	yazi thunar tumbler thunar-volman thunar-archive-plugin

	# Editor
	neovim lazygit

	# Screenshot & Recording
	grim slurp satty wl-clipboard gpu-screen-recorder ffmpeg v4l-utils

	# Clipboard
	cliphist wl-clip-persist

	# Audio
	pipewire pipewire-alsa pipewire-pulse wireplumber
	pamixer wiremix

	# Music
	mpd mpc rmpc cava playerctl mpdscribble
	spotify-launcher spicetify-cli

	# Network & Bluetooth
	networkmanager nmgui-bin kdeconnect
	bluez bluez-utils blueman

	# System
	polkit-gnome brightnessctl ddcutil power-profiles-daemon upower
	libnotify xdg-utils xdg-user-dirs inotify-tools
	gnome-keyring libsecret xorg-xhost libappindicator

	# Theming
	matugen-bin nwg-look adw-gtk-theme bibata-cursor-theme-bin imagemagick

	# Rofi Extras
	rofimoji wtype

	# Monitoring
	btop fastfetch chafa

	# Fonts
	ttf-jetbrains-mono-nerd ttf-cascadia-mono-nerd noto-fonts-emoji

	# Display Manager
	greetd greetd-tuigreet

	# Utilities
	python-terminaltexteffects gum wget curl unzip localsend deno npm keyd 
)

# ╭───────────────────────────────────────────────────────────────────────╮
# │ Optional Applications                                                 │
# ╰───────────────────────────────────────────────────────────────────────╯

applications=(
	 zen-browser-bin firefox chromium
	obsidian bitwarden code visual-studio-code-bin
	vesktop-bin discord keychain zed opencode
	mpv yt-dlp steam lutris gamemode mangohud typora
)

# ╭───────────────────────────────────────────────────────────────────────╮
# │ Functions                                                             │
# ╰───────────────────────────────────────────────────────────────────────╯

setup_aur() {
	aur_installed && return 0
	
	# Ensure base-devel and git are installed first
	info "Ensuring build dependencies are installed..."
	if ! pkg_installed "base-devel"; then
		info "Installing base-devel..."
		sudo pacman -S --needed --noconfirm base-devel
	fi
	if ! pkg_installed "git"; then
		info "Installing git..."
		sudo pacman -S --needed --noconfirm git
	fi
	
	info "Installing yay..."
	local tmp=$(mktemp -d)
	
	# Use yay (source) instead of yay-bin for better compatibility
	if ! git clone https://aur.archlinux.org/yay.git "$tmp/yay" --depth 1; then
		err "Failed to clone yay repository"
		rm -rf "$tmp"
		return 1
	fi
	
	# Build and install yay (show output for debugging)
	if ! (cd "$tmp/yay" && makepkg -si --noconfirm); then
		err "Failed to build/install yay"
		rm -rf "$tmp"
		return 1
	fi
	
	rm -rf "$tmp"
	
	# Verify installation
	if command -v yay &>/dev/null; then
		ok "yay installed successfully"
		yay --version
	else
		err "yay installation verification failed"
		return 1
	fi
}

do_install() {
	local aur=$(get_aur_helper)
	local official=() from_aur=()

	for pkg in "$@"; do
		[[ -z "$pkg" ]] && continue
		if pkg_installed "$pkg"; then
			ok "$pkg"
		elif pacman -Si "$pkg" &>/dev/null; then
			official+=("$pkg")
		elif [[ -n "$aur" ]] && $aur -Si "$pkg" &>/dev/null 2>&1; then
			from_aur+=("$pkg")
		else
			warn "$pkg not found"
		fi
	done

	if [[ ${#official[@]} -gt 0 ]]; then
		echo
		info "Installing ${#official[@]} packages from official repos..."
		echo
		sudo pacman -S --needed --noconfirm "${official[@]}"
	fi

	if [[ ${#from_aur[@]} -gt 0 ]]; then
		echo
		info "Installing ${#from_aur[@]} packages from AUR..."
		echo
		$aur -S --needed --noconfirm "${from_aur[@]}"
	fi

	return 0
}

ask_applications() {
	command -v gum &>/dev/null || return 0
	echo
	gum confirm "Install optional applications?" || return 0

	local selected
	selected=$(printf '%s\n' "${applications[@]}" | gum choose --no-limit --height 20) || return 0
	[[ -z "$selected" ]] && return 0

	step "Installing applications"
	do_install $selected
	return 0
}

# ╭───────────────────────────────────────────────────────────────────────╮
# │ Run                                                                   │
# ╰───────────────────────────────────────────────────────────────────────╯

step "Installing packages"
setup_aur
do_install "${packages[@]}"
ask_applications
