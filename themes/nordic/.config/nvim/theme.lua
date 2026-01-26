-- Hyprluggage by Jmartgraphix
-- Theme: Nordic
-- https://github.com/Jmartgraphix/hyprluggage

return {
	{
		"AlexvZyl/nordic.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("nordic").load()
		end,
	},
}
