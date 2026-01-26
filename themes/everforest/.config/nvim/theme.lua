-- Everforest Theme
-- https://github.com/sainnhe/everforest

return {
	{
		"sainnhe/everforest",
		lazy = false,
		priority = 1000,
		opts = {
			background = "dark",
			transparent_background = true,
		},
		config = function()
			vim.cmd.colorscheme("everforest")
		end,
	},
}
