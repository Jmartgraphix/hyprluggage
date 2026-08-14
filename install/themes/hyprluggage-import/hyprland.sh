#!/bin/bash

gen_hyprland() {
    cat > "$dest/.config/hypr/theme/colors.lua" <<EOF
-- ╭─ ♪ Hyprluggage ─╮
-- │  Generated   │
-- ╰──────────────╯
-- Theme: Omarchy $name
return {
  secondary = "rgba($(hex "$accent")aa)",
  outline_variant = "rgba($(hex "$bblack")ff)",
  active_border = "rgba($(hex "$accent")aa)",
  group_border_active = "rgba($(hex "$accent")aa)",
  shadow = {
    color = "rgba($(hex "$bg")80)",
    color_inactive = "rgba($(hex "$bg")4d)",
    offset = { 2, 2 },
    range = 20,
    render_power = 3,
  },
}
EOF
}
