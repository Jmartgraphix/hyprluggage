# HyprLuggage

<div align="center">

<img src="assets/luggage_open.png" alt="Luggage" width="300"/>

**Magical, Multi-Legged Hyprland Setup**

**(Made of Sapient Pearwood)**
**(Fiercely Loyal to Your Dotfiles)**

<a href="#installation"><img src="https://img.shields.io/badge/Install-c4a7e7?style=for-the-badge&logoColor=1a1b26" alt="Install"/></a>&ensp;
<a href="#themes"><img src="https://img.shields.io/badge/Themes-f5a97f?style=for-the-badge&logoColor=1a1b26" alt="Themes"/></a>&ensp;
<a href="install/themes/README.md"><img src="https://img.shields.io/badge/Hyprluggage-f5c2e7?style=for-the-badge&logoColor=1a1b26" alt="Hyprluggage"/></a>&ensp;
<a href="#usage"><img src="https://img.shields.io/badge/Usage-7aa2f7?style=for-the-badge&logoColor=1a1b26" alt="Usage"/></a>&ensp;
<a href="#keybindings"><img src="https://img.shields.io/badge/Keybindings-9ece6a?style=for-the-badge&logoColor=1a1b26" alt="Keybindings"/></a>

[![Arch](https://img.shields.io/badge/Arch-1793D1?style=flat&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![CachyOS](https://img.shields.io/badge/CachyOS-00D9FF?style=flat&logo=arch-linux&logoColor=white)](https://www.cachyos.org/)
[![Hyprland](https://img.shields.io/badge/Hyprland-58E1FF?style=flat&logo=wayland&logoColor=white)](https://hyprland.org/)
[![MIT](https://img.shields.io/badge/MIT-9ece6a?style=flat)](LICENSE)

</div>

## Table of Contents

- [Features](#features)
- [Themes](#themes)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Usage](#usage)
- [Keybindings](#keybindings)
- [Components](#components)
- [Customization](#customization)
- [Structure](#structure)
- [Remote desktop (VNC)](#remote-desktop-vnc)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Credits](#credits)

---

## Features

- **One-command theming** — Switch entire desktop look with `hyprluggage switch`
- **Desktop & laptop profiles** — Installer chooses form factor; NVIDIA GPU overlay auto-detects on bare metal (skipped in VMs by default)
- **Dynamic colors** — Matugen extracts palette from any wallpaper
- **12 themes** — 11 handcrafted + 1 dynamic (Dark, cozy, and aesthetic)
- **Everything synced** — Terminal, bar, launcher, notifications, apps
- **Rofi menus** — App launcher, emoji picker, clipboard, wallpaper selector, power profiles
- **Dual mode** — Vibe (animations + blur) or Focus (minimal + fast)
- **Music integration** — MPD + RMPC + Cava visualizer
- **Remote desktop** — wayvnc with Ctrl+Alt Super-key twins for browser VNC (Gatwy/noVNC)

<details>
<summary><b>Dual Mode System</b></summary>

Sometimes you want your desktop to look good. Other times you just need to get work done.

**Vibe Mode**

The default look — animations, blur, transparency, gaps. Makes everything feel smooth and polished.

**Focus Mode**

Strips it all down. No animations, minimal borders, transparency off. Just you and your work.

Toggle between them with `Super + Ctrl + Backspace`

</details>

---

## Themes

| | |
|:---:|:---:|
| ![Dynamic](assets/dynamic.png)**Dynamic** | ![Catppuccin](assets/catppuccin.png)**Catppuccin** |
| ![Coffee](assets/coffee.png)**Coffee** | ![Everforest](assets/everforest.png)**Everforest** |
| ![Gruvbox](assets/gruvbox.png)**Gruvbox** | ![Jade](assets/jade.png)**Jade** |
| ![Kanagawa](assets/kanagawa.png)**Kanagawa** | ![Monochrome](assets/monochrome.png)**Monochrome** |
| ![Nordic](assets/nordic.png)**Nordic** | ![Octarine](assets/octarine.png)**Octarine** |
| ![Rosé Pine](assets/rose-pine.png)**Rosé Pine** | ![Tokyo Night](assets/tokyo-night.png)**Tokyo Night** |

**Dynamic** - Colors generated from wallpaper using Matugen  
**Catppuccin** - Soothing pastel theme (Mocha variant)  
**Coffee** - Warm, earthy brown tones inspired by coffee  
**Everforest** - Green-based, warm-toned color scheme  
**Gruvbox** - Retro groove color scheme with warm, muted tones  
**Jade** - Cool, serene green palette with elegant tones  
**Kanagawa** - Inspired by Japanese woodblock prints, warm and artistic  
**Monochrome** - Minimalist black and white aesthetic  
**Nordic** - Cool, clean blue tones inspired by Nordic design  
**Octarine** - The eighth color of magic (fluorescent greenish-yellow purple) from Discworld  
**Rosé Pine** - Soft, muted rose and pine color scheme  
**Tokyo Night** - Dark theme with vibrant neon accents

Each theme includes multiple wallpapers and can be previewed using `hyprluggage tui` or `hyprluggage browse`.

---

## What's Included

HyprLuggage comes with a complete desktop environment setup:

**Rofi Menus** - Powerful launcher with multiple menus:
- App launcher (`Super + Space`)
- Emoji picker (`Alt + .`)
- Clipboard manager (`Alt + ,`)
- Wallpaper selector (`Super + Alt + Space`)
- Power profiles (`Super + Ctrl + B`)
- Power menu (`Super + Escape`)

**Hyprlock** - Customizable lock screen with theme integration. Lock with `Super + Shift + L`.

**Neovim** - Pre-configured Neovim with theme integration. All themes include Neovim color schemes that sync automatically.

**Music Integration** - Complete music setup:
- **MPD** - Music Player Daemon for background playback
- **RMPC** - Terminal-based music player (`Alt + M`)
- **Cava** - Audio visualizer (`Super + Shift + C`)

**Notifications** - Mako notification daemon with theme-aware styling. Dismiss all with `Super + N`.

**Remote desktop** - wayvnc shares the session; over VNC use **Ctrl+Alt** instead of Super. See [Remote desktop (VNC)](#remote-desktop-vnc).

---

## Requirements

- **Distribution:** CachyOS or Arch Linux (CachyOS preferred)
- **RAM:** At least 4GB (8GB recommended)
- **Storage:** ~5GB free space for packages and configs
- **Internet:** Required for installation
- **Access:** Root/sudo privileges
- **Display:** Wayland-compatible graphics

---

## Prerequisites

This setup works best on **CachyOS** or **Arch Linux**. While CachyOS is preferred, you can use either distribution.

### Installation Steps

1. **Bootloader and Filesystem**
   
   You can use whatever bootloader (GRUB, systemd-boot, rEFInd, etc.) and filesystem (ext4, btrfs, zfs, etc.) you prefer. HyprLuggage works with any combination.

2. **Choose "No Desktop"** during installation
   
   When installing CachyOS, select "No Desktop" from the desktop environment list. This ensures a clean base system without any desktop environment pre-configured.

   <img src="assets/cachy-no_desktop.jpg" alt="Desktop Selection" width="800"/>

3. **Uncheck "CachyOS shell configuration"** in the packages step
   
   In the packages selection screen, make sure to **uncheck** "CachyOS shell configuration" to prevent the installer from configuring your shell. This allows HyprLuggage to set up your shell configuration instead.

   <img src="assets/cachy-no_shell.jpg" alt="Package Selection" width="800"/>

4. **Install Git and Stow** after base system is finished installing
   
   Reboot your system and at the prompt install git and stow for package management and stowing dotfiles (*if not installed already*)

   ```bash
   sudo pacman -S git stow
   ```

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/Jmartgraphix/hyprluggage/master/boot.sh | bash
```

Or manually:

```bash
git clone https://github.com/Jmartgraphix/hyprluggage ~/hyprluggage
cd ~/hyprluggage && ./install.sh
```

### Themes Only

Want just the themes without the full setup? See [install/themes/README.md](install/themes/README.md)

### What Gets Installed

The installer will:

0. **Choose a hardware profile:**
   - **Desktop** or **Laptop** (battery presence is auto-detected as the default)
   - **GPU overlay** via `lspci` on bare metal (NVIDIA env applied when an NVIDIA display GPU is found; **skipped by default in VMs**)
   - Saved under `~/.local/state/hyprluggage/profile` and `gpu` (re-run can keep or change)

1. **Install core packages:**
   - Hyprland compositor and related tools (hypridle, hyprlock, hyprpicker)
   - Desktop components (Waybar, Rofi, Mako, awww, swayosd)
   - Browser (Brave)
   - Remote desktop (wayvnc) and SSH (openssh)
   - Firewall (ufw) with allow rules for SSH, VNC, LocalSend, and KDE Connect
   - Terminal emulators (Kitty, Ghostty, Alacritty; Kitty is the default Super+Return terminal)
   - Shell and tools (Fish, Starship, tmux)
   - File managers (Thunar, Yazi)
   - Editor (Neovim)
   - Music stack (MPD, RMPC, Cava)
   - And many more utilities

2. **Install optional applications:**
   - Extra browsers (Firefox, Chromium, Zen)
   - Editors (VS Code, Zed, Obsidian)
   - Communication (Discord, Vesktop)
   - Coding agents (OpenCode, Herdr)
   - And other productivity apps

3. **Set up system services:**
   - MPD (music daemon)
   - Greetd (display manager; session via `hyprluggage-session`, which runs hw-ensure then Hyprland)
   - wayvnc + clipboard bridge (user units)
   - sshd (enabled)
   - ufw allow rules for SSH, VNC, LocalSend, and KDE Connect
     - **Laptop:** UFW is enabled
     - **Desktop:** UFW stays inactive unless it was already active
   - **Laptop only:** logind lid ignore drop-in, `video` group, `power-profiles-daemon`, hypridle + battery notifications, hybrid lid close (suspend undocked / clamshell when docked)
   - **NVIDIA + laptop:** enable nvidia suspend/resume/hibernate units when present
   - User services for autostart

4. **Deploy dotfiles:**
   - Symlink all configs to `~/.config/`
   - Write form-factor + GPU Hyprland stubs under `~/.local/state/hyprluggage/`
   - Set up desktop entries
   - Configure shell (Fish with Starship)

5. **Install theme system:**
   - Set up Hyprluggage theme manager
   - Install all 12 themes

### Hardware profiles

| Profile | Idle | Battery | Lid close | Firewall | Power |
|---------|------|---------|-----------|----------|-------|
| Desktop | hypridle killed on login | not started | no change | rules only (left inactive) | performance |
| Laptop | hypridle started | battery-notify | suspend or clamshell | UFW enabled | balanced on battery |

NVIDIA vs AMD/Intel is **independent** of desktop/laptop. On bare metal, an NVIDIA display GPU sources `~/.config/hypr/profiles/nvidia.conf`; AMD/Intel get an empty GPU stub. **Virtual machines** still use Desktop or Laptop — there is no separate VM profile — but NVIDIA is not auto-applied under a hypervisor (passthrough cards often break Hyprland/wayvnc). Opt in with `hyprluggage-hw-ensure set desktop nvidia`. wayvnc also skips `--gpu` when virt is detected. See [VNC.md](.config/hypr/VNC.md).

Re-check or recreate stubs anytime:

```bash
hyprluggage-hw-ensure detect
hyprluggage-hw-ensure ensure
hyprluggage-hw-ensure set laptop nvidia   # example
```

---

## Quick Start

After installation:

1. **Log out and log back in** (or reboot) to start Hyprland
2. **Choose your first theme:**
   ```bash
   hyprluggage switch
   ```
   Or press `Super + Ctrl + Shift + Space` for the interactive picker
3. **Explore keybindings:** Press `Super + K` to see all available shortcuts
4. **Customize:** Edit configs in `~/.config/` - they won't be overwritten
5. **Switch themes anytime:** Use `hyprluggage switch` or the TUI (`Super + I`). The TUI also has **Choose Shell** and **Choose Terminal** (Super+Return / tmux only; system menus stay on Kitty).

---

## Usage

### Theme Switching

```bash
hyprluggage switch          # interactive picker
hyprluggage switch rose-pine # direct switch
hyprluggage list            # show all themes
hyprluggage reload          # re-apply current
hyprluggage current         # show current theme
hyprluggage fix             # fix broken symlinks
hyprluggage browse          # browse & import Omarchy themes
hyprluggage import <url>    # import theme from GitHub
hyprluggage tui             # interactive theme browser
hyprluggage remove <theme>  # delete a theme
hyprluggage uninstall       # remove Hyprluggage
hyprluggage help            # show help
```

Or press `Super + Ctrl + Shift + Space` for the theme picker.

<a id="keybindings"></a>

### Keybindings

<details>
<summary><b>Applications</b></summary>

| Key | Action |
|-----|--------|
| `Super + Return` | Working terminal (Kitty default; change in Hyprluggage TUI) |
| `Super + B` | Browser |
| `Super + E` | File Manager (Thunar) |
| `Super + M` | Spotify |
| `Super + D` | Discord |
| `Super + O` | Obsidian |
| `Super + C` | Cursor |
| `Super + /` | Bitwarden |
| `Super + Shift + C` | Cava |
| `Alt + M` | RMPC |
| `Alt + N` | Neovim |
| `Alt + Q` | Yazi |
| `Alt + /` | Btop |

</details>

<details>
<summary><b>Rofi Menus</b></summary>

| Key | Action |
|-----|--------|
| `Super + Space` | App Launcher |
| `Alt + ,` | Clipboard |
| `Alt + .` | Emoji Picker |
| `Super + Ctrl + B` | Power Profiles |
| `Super + Ctrl + Space` | Matugen Theme |
| `Super + Alt + Space` | Wallpaper Picker |
| `Super + Ctrl + Shift + Space` | Theme Switcher |
| `Super + I` | Hyprluggage TUI |
| `Super + Alt + I` | Browse Themes |

</details>

<details>
<summary><b>Window Management</b></summary>

| Key | Action |
|-----|--------|
| `Super + Q` | Close Window |
| `Super + K` | Show All Keybindings |
| `Super + Shift + K` | Kill Application |
| `Super + Arrow` | Move Focus |
| `Super + Shift + Arrow` | Swap Window |
| `Super + Ctrl + Left/Right` | Previous/Next Workspace |
| `Super + -` / `Super + =` | Resize Window |
| `Super + 1-9, 0` | Switch Workspace (1–10) |
| `Super + Shift + 1-9, 0` | Move to Workspace (1–10) |
| `Super + F` | Fullscreen |
| `Super + Shift + V` | Toggle Floating |
| `Super + Shift + O` | Pop Window (Float & Pin) |

</details>

<details>
<summary><b>System</b></summary>

| Key | Action |
|-----|--------|
| `Super + L` | Screensaver |
| `Super + Shift + L` | Lock Screen |
| `Super + Escape` | Power Menu |
| `Super + N` | Dismiss Notifications |
| `Super + Backspace` | Toggle Transparency |
| `Super + Ctrl + Backspace` | Toggle Focus/Vibe Mode |

</details>

<details>
<summary><b>Screenshots & Recording</b></summary>

| Key | Action |
|-----|--------|
| `Super + P` | Screenshot |
| `Super + R` | Screen Record |
| `Super + Shift + R` | Record with Mic |
| `Super + Shift + P` | Color Picker |

</details>

<details>
<summary><b>Wallpapers</b></summary>

| Key | Action |
|-----|--------|
| `Super + Ctrl + Alt + Space` | Random Wallpaper + Colors |
| `Super + Alt + Left/Right` | Cycle Wallpapers |

</details>

<details>
<summary><b>Remote (VNC)</b></summary>

| Key | Action |
|-----|--------|
| `Ctrl + Alt` + same key | Twin of most Super binds |
| `Ctrl + Alt + K` | Show remote keybinds |
| `Ctrl + Alt + Space` | App launcher (VNC twin of Super+Space) |

Some Space-family theme chords are remapped under Ctrl+Alt — see [`.config/hypr/VNC.md`](.config/hypr/VNC.md).

</details>

See [.config/hypr/bindings.conf](.config/hypr/bindings.conf), [tiling.conf](.config/hypr/tiling.conf), and [media.conf](.config/hypr/media.conf) for the full list.

---

## Components

| Component | Tool | Description |
|-----------|------|-------------|
| Compositor | [Hyprland](https://hyprland.org/) | Wayland compositor with smooth animations and window management |
| Bar | [Waybar](https://github.com/Alexays/Waybar) | Highly customizable status bar with modules for system info, workspaces, and more |
| Launcher | [Rofi](https://github.com/lbonn/rofi) | Application launcher and menu system with multiple modes |
| Wallpaper | [awww](https://codeberg.org/LGFae/awww) | Wayland wallpaper daemon (theme wallpapers + Matugen) |
| OSD | [SwayOSD](https://github.com/ErikReider/SwayOSD) | On-screen display for volume, brightness, and caps lock |
| Terminal | [Kitty](https://sw.kovidgoyal.net/kitty/) / [Ghostty](https://ghostty.org/) / [Alacritty](https://alacritty.org/) | All three installed; Kitty is the default Super+Return terminal and system TUI host. Pick Ghostty or Alacritty as the working terminal from the Hyprluggage TUI. Alacritty also runs the screensaver. |
| File Manager | [Thunar](https://docs.xfce.org/xfce/thunar/start) (GUI) / [Yazi](https://github.com/sxyazi/yazi) (CLI) | Dual file managers for GUI and terminal workflows |
| Notifications | [Mako](https://github.com/emersion/mako) | Lightweight notification daemon with theme support |
| Lock screen | [Hyprlock](https://github.com/hyprwm/hyprlock) | Secure lock screen integrated with Hyprland |
| Theme engine | [Matugen](https://github.com/InioX/matugen) | Material You color palette generator from wallpapers |
| Music | [MPD](https://musicpd.org/) + [RMPC](https://github.com/mierak/rmpc) | Music Player Daemon with terminal client for music playback |
| Visualizer | [Cava](https://github.com/karlstav/cava) | Audio spectrum visualizer for terminal |
| Editor | [Neovim](https://neovim.io/) | Modern Vim fork with LSP support and theme integration |
| Shell | [Fish](https://fishshell.com/) + [Starship](https://starship.rs/) | User-friendly shell with fast, customizable prompt |
| Remote desktop | [wayvnc](https://github.com/any1/wayvnc) | VNC server for the Hyprland session (Ctrl+Alt Super twins) |

---

## Customization

All configuration files are located in `~/.config/`. You can edit them directly—they won't be overwritten by theme switches.

**Key customization locations:**
- **Keybindings:** `~/.config/hypr/bindings.conf` - Modify or add shortcuts
- **Hyprland settings:** `~/.config/hypr/` - Window rules, animations, monitors
- **Waybar:** `~/.config/waybar/` - Status bar modules and styling
- **Rofi:** `~/.config/rofi/` - Launcher appearance and scripts
- **Terminal:** `~/.config/kitty/`, `~/.config/ghostty/`, or `~/.config/alacritty/` - Terminal settings
- **Shell:** `~/.config/fish/` - Fish shell configuration

**Theme customization:**
- Each theme's configs are in `~/hyprluggage/themes/<theme-name>/.config/`
- Copy a theme to create your own: `cp -r themes/monochrome themes/my-theme`
- Edit colors, wallpapers, and configs in your custom theme

**Note:** Theme switches only update colors and wallpapers. Your custom config edits are preserved.

---

## Structure

```
~/hyprluggage/
├── .config/
│   ├── hypr/           # Hyprland (compositor, bindings, VNC mods)
│   ├── waybar/         # Status bar
│   ├── rofi/           # Launcher & menus
│   ├── mako/           # Notifications
│   ├── swayosd/        # OSD (volume/brightness)
│   ├── wayvnc/         # Remote desktop server
│   ├── kitty/          # Terminal (system TUIs + default Super+Return)
│   ├── ghostty/        # Terminal (optional working terminal)
│   ├── alacritty/      # Terminal (screensaver + optional working terminal)
│   ├── nvim/           # Neovim
│   ├── fish/           # Shell
│   ├── tmux/           # Terminal multiplexer
│   ├── yazi/           # File manager (CLI)
│   ├── mpd/            # Music daemon
│   ├── rmpc/           # Music player
│   ├── matugen/        # Theme generator templates
│   └── lazygit/        # Git UI
├── .local/bin/         # Helper scripts (VNC, clipboard bridge, etc.)
├── themes/             # Theme configs (colors, wallpapers)
├── .config/hypr/
│   ├── profiles/       # desktop.conf, laptop.conf, nvidia.conf
│   └── ...
├── .local/bin/         # hyprluggage-hw-ensure, hypr-vnc-mod, ...
├── scripts/            # Utility scripts
└── install/            # Installer
    ├── packages.sh     # Package lists
    ├── stow.sh         # Dotfile deployment
    ├── services.sh     # Systemd services (profile-aware)
    ├── logind-laptop.conf  # Lid ignore drop-in (laptop)
    └── themes/         # Hyprluggage theme system
```

Runtime stubs (outside the git tree): `~/.local/state/hyprluggage/profile.conf` and `gpu.conf`.

---

## Remote desktop (VNC)

Hyprluggage includes **wayvnc** and **Ctrl+Alt** Super-key twins for browser-based remote access (e.g. Gatwy/noVNC), because Super often does not reach the remote session.

- At the desk: Super works as usual.
- Over VNC: use **Ctrl+Alt** instead of Super; **Ctrl+Alt+K** shows remote keybinds.
- Some Space-family theme chords are remapped under Ctrl+Alt (documented in VNC.md).
- Fresh install enables `wayvnc` and `wayvnc-clipboard-bridge` user units via `install/services.sh`.
- Fresh install also enables `sshd` and adds ufw allow rules for SSH (`22/tcp`), VNC (`5900/tcp`), LocalSend (`53317` TCP/UDP), and KDE Connect (`1714–1764` TCP/UDP). On **laptop** profile, UFW is enabled; on **desktop**, UFW stays inactive unless it was already active.

See [`.config/hypr/VNC.md`](.config/hypr/VNC.md) for setup, remaps, and files.

---

## Troubleshooting

**Colors not updating?**
```bash
hyprluggage reload
```

**Symlinks broken?**
```bash
hyprluggage fix
```

**Theme not applying?**
- Check that `~/.config/hyprluggage/current` exists and is a symlink
- Verify the theme exists: `hyprluggage list`
- Try reloading: `hyprluggage reload`

**Installation issues?**
- Ensure you have internet connection
- Check you have sudo/root access
- Verify you're on Arch Linux or CachyOS
- See [install/themes/README.md](install/themes/README.md) for theme-specific issues

**Hyprland not starting / greetd login loops back to tuigreet?**
- Check: `journalctl -u greetd -b` and `~/.local/state/hyprluggage/session.log`
- If you see `greeter exited without creating a session` / `start-limit-hit`, tuigreet's session command is wrong — it must use `--cmd`.
- After pulling a greetd fix, re-apply as the install user:

```bash
cd ~/hyprluggage && git pull
sudo install -Dm755 ~/hyprluggage/.local/bin/hyprluggage-session /etc/greetd/hyprluggage-session
sudo mkdir -p /etc/tuigreet
sudo install -Dm644 ~/hyprluggage/install/tuigreet-config.toml /etc/tuigreet/config.toml
sed "s/{{USER}}/$USER/g" ~/hyprluggage/install/greetd-config.toml | sudo tee /etc/greetd/config.toml
sudo systemctl reset-failed greetd
sudo systemctl restart greetd
```

If it still loops, check:
- `/tmp/hyprluggage-session-$(id -u).log`
- `~/.local/state/hyprluggage/session.log`
- `journalctl -u greetd -b --no-pager | tail -50`

**Keybindings not working?**
- Check `~/.config/hypr/bindings.conf` (and `tiling.conf` / `media.conf`) for conflicts
- Reload Hyprland config: `hyprctl reload`
- Verify the keybinding syntax is correct
- Over VNC, use Ctrl+Alt instead of Super — see [VNC.md](.config/hypr/VNC.md)

**Need more help?**
- Check the [full keybindings list](.config/hypr/bindings.conf)
- Run `hyprluggage help` for command reference
- [Report a bug](https://github.com/Jmartgraphix/hyprluggage/issues/new?template=bug_report.yml)

---

## Uninstallation

To remove HyprLuggage:

```bash
cd ~/hyprluggage && ./uninstall.sh
```

The uninstaller will:
- Remove all symlinks from your home directory
- Restore any backed-up configs (from `~/dotfiles-backup*`)
- Optionally remove installed packages (you choose which ones)
- Clean up shell configuration
- Remove desktop entries

**Note:** Your custom edits in `~/.config/` will be preserved if they weren't symlinks. Backups are created during installation in `~/dotfiles-backup*`.

---

## Credits

**Inspiration:** HyprLuggage is inspired by Terry Pratchett's Discworld series, specifically The Luggage—a magical, multi-legged chest made of Sapient Pearwood that is fiercely loyal to its owner.

Learned a lot from these projects:
- [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles)
- [basecamp/omarchy](https://github.com/basecamp/omarchy)

Wallpapers: [Jmartgraphix/Wallpapers](https://github.com/Jmartgraphix/Wallpapers)

---

<div align="center">

**[Report Bug](https://github.com/Jmartgraphix/hyprluggage/issues/new?template=bug_report.yml)** · **[Request Feature](https://github.com/Jmartgraphix/hyprluggage/issues/new?template=feature_request.yml)** ·

</div>
