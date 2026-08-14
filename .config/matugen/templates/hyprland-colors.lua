-- Dynamic theme colors (Matugen) for Hyprland Lua
return {
  secondary = "rgba({{colors.secondary.default.hex_stripped}}ff)",
  outline_variant = "rgba({{colors.outline_variant.default.hex_stripped}}ff)",
  active_border = "rgba({{colors.primary.default.hex_stripped}}aa)",
  group_border_active = "rgba({{colors.primary.default.hex_stripped}}aa)",
  shadow = {
    color = "rgba({{colors.shadow.default.hex_stripped}}80)",
    color_inactive = "rgba({{colors.shadow.default.hex_stripped}}4d)",
    offset = { 2, 2 },
    range = 20,
    render_power = 3,
  },
}
