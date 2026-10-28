#!/bin/bash

# Palette colorscheme for bjarneo/aether.nvim, same shape as the Jade and Coffee themes.
gen_nvim() {
    local b01=$black b02=$surface
    [[ "$b01" == "$bg" ]] && b01=$surface
    [[ "$b02" == "$b01" ]] && b02=$(lighten "$bg" 36)
    cat > "$dest/.config/nvim/theme.lua" <<EOF
-- Hyprluggage by Jmartgraphix
-- Theme: $name
-- https://github.com/Jmartgraphix/hyprluggage

return {
	{
		"bjarneo/aether.nvim",
		name = "aether",
		lazy = false,
		priority = 1000,
		opts = {
			disable_italics = false,
			colors = {
				base00 = "$bg",
				base01 = "$b01",
				base02 = "$b02",
				base03 = "$bblack",
				base04 = "$white",
				base05 = "$fg",
				base06 = "$bwhite",
				base07 = "$white",
				base08 = "$red",
				base09 = "$bred",
				base0A = "$yellow",
				base0B = "$green",
				base0C = "$cyan",
				base0D = "$blue",
				base0E = "$magenta",
				base0F = "$byellow",
			},
		},
		config = function(_, opts)
			require("aether").setup(opts)
			vim.cmd.colorscheme("aether")
		end,
	},
}
EOF
}
