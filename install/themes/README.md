## Installation

```bash
git clone https://github.com/Jmartgraphix/hyprluggage.git ~/hyprluggage
cd ~/hyprluggage/install/themes
./install.sh
```

Uninstall:
```bash
./uninstall.sh
```

## Themes

- **Dynamic** - Colors generated from wallpaper using Matugen
- **Catppuccin** - Soothing pastel theme (Mocha variant)
- **Coffee** - Warm, earthy brown tones inspired by coffee
- **Everforest** - Green-based, warm-toned color scheme
- **Gruvbox** - Retro groove color scheme with warm, muted tones
- **Jade** - Cool, serene green palette with elegant tones
- **Kanagawa** - Inspired by Japanese woodblock prints, warm and artistic
- **Monochrome** - Minimalist black and white aesthetic
- **Nordic** - Cool, clean blue tones inspired by Nordic design
- **Octarine** - The eighth color of magic (fluorescent greenish-yellow purple) from Discworld
- **Rosé Pine** - Soft, muted rose and pine color scheme
- **Tokyo Night** - Dark theme with vibrant neon accents

Wallpapers: [Jmartgraphix/Wallpapers](https://github.com/Jmartgraphix/Wallpapers)

## Usage

```bash
hyprluggage switch          # pick a theme
hyprluggage switch monochrome # switch directly
hyprluggage list            # see all themes
hyprluggage reload          # re-apply current
hyprluggage fix             # fix broken symlinks
```

## Keybindings

| Shortcut | Action |
|----------|--------|
| `Super + Ctrl + Shift + Space` | Theme switcher |
| `Super + Ctrl + Space` | Matugen (colors from wallpaper) |
| `Super + Alt + Space` | Wallpaper picker |
| `Super + Ctrl + Alt + Space` | Random wallpaper + colors |
| `Super + Alt + Left/Right` | Cycle wallpapers |
| `Super + Backspace` | Toggle terminal transparency |
| `Super + Ctrl + Backspace` | Toggle focus/vibe mode |

Over VNC or Sunshine, use **Ctrl+Alt** instead of Super (some Space-family theme chords are remapped). See [`.config/hypr/VNC.md`](../../.config/hypr/VNC.md).

## How it works

Hyprluggage updates `~/.config/hyprluggage/current` and runs hooks to reload apps. No files are overwritten.

## Hooks (what it covers)

- Terminals: kitty, ghostty, alacritty
- UI: Hyprland, Waybar, GTK3/4, Rofi
- Utilities: btop, cava
- Apps: yazi, rmpc, vesktop, obsidian
- Extras: pywalfox

## Customization

### Themed Rofi

Rofi has a transparent glass/blur look by default - works well with any wallpaper. If you want it to match your theme colors instead:

1. Open `~/.config/rofi/config.rasi`
2. Uncomment `@import "colors.rasi"`
3. Replace hardcoded color values with variables from `colors.rasi`

Each theme has its own `colors.rasi` in `themes/<name>/.config/rofi/`

### Themed Neovim

Each theme includes a `theme.lua` in `themes/<name>/.config/nvim/`. To use it, copy or symlink to your nvim config:

```bash
ln -sf ~/.config/hyprluggage/current/.config/nvim/theme.lua ~/.config/nvim/lua/plugins/theme.lua
```

## Adding your own theme

Copy an existing theme:
```bash
cp -r themes/monochrome themes/my-theme
```
Edit configs in `themes/my-theme/.config/` and add wallpapers to `themes/my-theme/backgrounds/`.

## Dependencies

- Required: `stow`, `hyprctl`, `awww`
- Terminals: `kitty`, `ghostty`, `alacritty` (all installed; Kitty is default Super+Return)
- Optional: `waybar`, `rofi`, `gum`, `tte`, `matugen`

## Troubleshooting

```bash
hyprluggage reload    # colors not updating
hyprluggage fix       # symlinks broken
```

---

Thanks / Inspirations:
- [basecamp/omarchy](https://github.com/basecamp/omarchy)
- [vyrx-dev/dotfiles](https://github.com/vyrx-dev/dotfiles)
- [rebelot/kanagawa.nvim](https://github.com/rebelot/kanagawa.nvim)
- [sainnhe/gruvbox-material](https://github.com/sainnhe/gruvbox-material)
- [EliverLara/Nordic](https://github.com/EliverLara/Nordic)
- [rose-pine/rose-pine-theme](https://github.com/rose-pine/rose-pine-theme)
- [folke/tokyonight.nvim](https://github.com/folke/tokyonight.nvim)
- [InioX/matugen](https://github.com/InioX/matugen)

Have an idea or found a bug?
- Report a bug: [new bug](https://github.com/Jmartgraphix/hyprluggage/issues/new?template=bug_report.yml)
- Request a feature: [new feature](https://github.com/Jmartgraphix/hyprluggage/issues/new?template=feature_request.yml)
