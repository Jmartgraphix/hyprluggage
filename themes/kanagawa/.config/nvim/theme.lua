-- Hyprluggage by Jmartgraphix
-- Theme: Kanagawa
-- https://github.com/Jmartgraphix/hyprluggage

return {
	{
		"rebelot/kanagawa.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("kanagawa").setup({
				theme = "wave",
			})
			vim.cmd.colorscheme("kanagawa")
		end,
	},
}
