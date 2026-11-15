-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- Perfil "pearwood": escrita, não código
vim.opt.number = false
vim.opt.signcolumn = "no"
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true
vim.opt.spell = false
vim.opt.spelllang = { "pt_br" }
vim.opt.conceallevel = 2
vim.opt.scrolloff = 8
vim.opt.laststatus = 3
-- sem linha vertical entre o texto e as margens
vim.opt.fillchars:append({ vert = " ", vertleft = " ", vertright = " ", verthoriz = " ", horiz = " ", horizup = " ", horizdown = " " })
vim.opt.laststatus = 0 -- sem barra inferior
vim.opt.ruler = false
vim.opt.showcmd = false
