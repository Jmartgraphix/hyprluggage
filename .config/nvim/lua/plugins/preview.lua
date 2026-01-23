-- Preview tools
return {
  -- HTML preview
  {
    "barrett-ruth/live-server.nvim",
    build = "npm install -g live-server",
    cmd = { "LiveServerStart", "LiveServerStop" },
    config = true,
  },


  -- Markdown preview (modern replacement for peek.nvim)
{
  "OXY2DEV/markview.nvim",
  ft = "markdown",
  opts = {
    hybrid = true, -- render + raw text
  },
  keys = {
    {
      "<leader>pm",
      "<cmd>MarkviewToggle<cr>",
      desc = "Markdown Preview Toggle",
    },
  },
},


  -- Markdown render
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    opts = {},
  },
}
