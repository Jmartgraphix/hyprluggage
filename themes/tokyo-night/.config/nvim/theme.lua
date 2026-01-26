-- Hyprluggage by Jmartgraphix
-- Theme: Tokyo Night
-- https://github.com/Jmartgraphix/hyprluggage

return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}
