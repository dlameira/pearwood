-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Cofre: cursor e atalhos de editor de texto comum (Obsidian, Docs, Word).
local map = vim.keymap.set
local ni = { "n", "i" }

-- setas atravessam o começo/fim da linha
vim.opt.whichwrap = "b,s,<,>,[,]"
-- ↑ ↓ andam pela linha que aparece na tela (parágrafo quebrado), como no Obsidian
map(ni, "<Up>", "<Cmd>normal! gk<CR>", { desc = "Linha de cima (visual)" })
map(ni, "<Down>", "<Cmd>normal! gj<CR>", { desc = "Linha de baixo (visual)" })

-- Shift + setas seleciona; digitar por cima substitui; Backspace apaga a seleção
vim.opt.keymodel = "startsel,stopsel"
vim.opt.selectmode = "mouse,key"

-- desfazer / refazer / selecionar tudo
map(ni, "<C-z>", "<Cmd>undo<CR>", { desc = "Desfazer" })
map(ni, "<C-y>", "<Cmd>redo<CR>", { desc = "Refazer" })
map(ni, "<C-S-z>", "<Cmd>redo<CR>", { desc = "Refazer" })
map(ni, "<C-a>", "<Esc>gg0vG$<C-g>", { desc = "Selecionar tudo" })

-- copiar / recortar / colar com a área de transferência do sistema
map("s", "<C-c>", '<C-g>"+y', { desc = "Copiar" })
map("s", "<C-x>", '<C-g>"+d', { desc = "Recortar" })
map("x", "<C-c>", '"+y', { desc = "Copiar" })
map("x", "<C-x>", '"+d', { desc = "Recortar" })
map("i", "<C-v>", "<C-r><C-o>+", { desc = "Colar" })

-- apagar palavra inteira com Ctrl + Backspace / Ctrl + Delete
map("i", "<C-BS>", "<C-w>", { desc = "Apagar palavra" })
map("i", "<C-h>", "<C-w>", { desc = "Apagar palavra" })
map("i", "<C-Del>", "<C-o>dw", { desc = "Apagar palavra à frente" })

-- seguir [[link]] sem sair da escrita: Ctrl + Enter ou Ctrl + clique
map(ni, "<C-CR>", "<Cmd>Obsidian follow_link<CR>", { desc = "Abrir link" })
map(ni, "<C-LeftMouse>", "<LeftMouse><Cmd>Obsidian follow_link<CR>", { desc = "Abrir link" })

-- Navegação estilo navegador (ver lua/cofre/nav.lua)
local nav = require("cofre.nav")
map({ "n", "i", "x", "s" }, "<M-h>", nav.inicio, { desc = "Tela inicial do Cofre" })
map("n", "<leader>h", nav.inicio, { desc = "Tela inicial do Cofre" })
map({ "n", "i" }, "<M-Left>", nav.voltar, { desc = "Voltar" })
map({ "n", "i" }, "<M-Right>", nav.avancar, { desc = "Avançar" })

-- Atalhos do Obsidian
map({ "n", "i" }, "<C-p>", nav.paleta, { desc = "Paleta de comandos" })
map({ "n", "i" }, "<C-o>", "<Cmd>Obsidian quick_switch<CR>", { desc = "Abrir nota pelo nome" })
map({ "n", "i" }, "<C-n>", function() require("cofre.para").anotar() end, { desc = "Anotar (nota solta)" })
map({ "n", "i" }, "<C-S-f>", "<Cmd>Obsidian search<CR>", { desc = "Buscar no texto do cofre" })
map({ "n", "i" }, "<C-f>", function() Snacks.picker.lines() end, { desc = "Buscar nesta nota" })
map({ "n", "i" }, "<M-m>", function() require("cofre.rascunho").guardar_em() end, { desc = "Guardar em… (pasta e nome)" })
