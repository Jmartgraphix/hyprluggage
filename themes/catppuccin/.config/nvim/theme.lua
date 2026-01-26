-- Catppuccin Mocha Theme
-- https://github.com/catppuccin/nvim

return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		priority = 1000,
		opts = {
			flavour = "mocha",
			transparent_background = true,
		},
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},
}
