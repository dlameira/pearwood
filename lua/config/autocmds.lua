-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Perfil "pearwood": o LazyVim liga corretor (em inglês) no markdown; aqui fica desligado
-- (ligue com <leader>us quando tiver o dicionário pt_br). Sem fechar ( [ " sozinho.
pcall(vim.api.nvim_del_augroup_by_name, "lazyvim_wrap_spell")
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text" },
  callback = function()
    vim.b.minipairs_disable = true
    vim.b.autoformat = false
    vim.opt_local.spell = false
    vim.opt_local.wrap = true
    vim.opt_local.list = false -- sem os ">" de tab e "-" de espaço sobrando
    vim.diagnostic.enable(false, { bufnr = 0 })
  end,
})

-- Cofre: nota abre já digitando; Esc/Alt+setas navegam (ver lua/cofre/nav.lua).
local nav = require("cofre.nav")
local rascunho = require("cofre.rascunho")
require("cofre.fonte")
require("cofre.autosalvar")
require("cofre.recarregar")
require("cofre.comentario")
require("cofre.menu")
require("cofre.rolagem")

-- Fechar o Cofre (:qa, Sair) com nota nova sem nome: vira nota solta.
vim.api.nvim_create_autocmd("QuitPre", { callback = function() rascunho.salvar_todos() end })

-- Ao entrar numa nota, guarda de onde ela veio (lista, nota anterior ou início).
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(ev)
    if not nav.eh_nota(ev.buf) then
      return
    end
    if vim.g.cofre_voltando then
      vim.g.cofre_voltando = false
    else
      nav.limpar_frente()
      local lista = vim.g.cofre_lista
      local anterior = vim.fn.bufnr("#")
      if lista and vim.uv.now() - lista.fechou < 400 and lista.buf ~= ev.buf then
        vim.b[ev.buf].cofre_volta = { tipo = "lista" }
      elseif anterior > 0 and anterior ~= ev.buf and vim.api.nvim_buf_is_valid(anterior) and nav.eh_nota(anterior) then
        vim.b[ev.buf].cofre_volta = { tipo = "nota", buf = anterior }
      else
        vim.b[ev.buf].cofre_volta = { tipo = "inicio" }
      end
    end
    vim.schedule(function()
      if vim.api.nvim_get_current_buf() == ev.buf and vim.fn.mode() == "n" then
        vim.cmd.startinsert()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "<Esc>", nav.esc_normal, { buffer = ev.buf, desc = "Voltar um nível (2x: início)" })
    vim.keymap.set("i", "<Esc>", nav.esc_escrita, { buffer = ev.buf, desc = "Voltar um nível (2x: início)" })
    vim.keymap.set("i", "/", rascunho.barra, { buffer = ev.buf, expr = true, desc = "/ no início: escolher pasta e nome" })
    vim.keymap.set({ "n", "i" }, "<C-s>", function() nav.salvar() end, { buffer = ev.buf, desc = "Salvar" })
  end,
})

-- Sem modos: se a nota cair no modo de comandos (ao fechar uma lista, por
-- exemplo), volta direto a ficar pronta para digitar.
vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*:n",
  callback = function()
    vim.schedule(function()
      if nav.eh_nota() and vim.fn.mode() == "n" and vim.api.nvim_win_get_config(0).relative == "" then
        vim.cmd.startinsert()
      end
    end)
  end,
})

-- Paleta comum aos outros programas do PC: linhas em cinza #7a7a7a, verde para foco,
-- ciano para informação, âmbar para atenção. Reaplica quando o tema do Omarchy muda.
local function paleta()
  local hl = function(nome, def) vim.api.nvim_set_hl(0, nome, def) end
  local linha, verde, ciano, ambar = "#7a7a7a", "#82fb9c", "#00c8c8", "#ffc107"
  hl("FloatBorder", { fg = linha, bg = "NONE" })
  hl("FloatTitle", { fg = verde, bg = "NONE", bold = true })
  hl("WinSeparator", { fg = linha, bg = "NONE" })
  hl("SnacksPickerBorder", { link = "FloatBorder" })
  hl("SnacksPickerTitle", { link = "FloatTitle" })
  hl("SnacksPickerInputBorder", { fg = verde, bg = "NONE" })
  hl("BlinkCmpMenuBorder", { link = "FloatBorder" })
  hl("Search", { fg = "#000000", bg = ciano })
  hl("CurSearch", { fg = "#000000", bg = verde })
  hl("IncSearch", { link = "CurSearch" })
  hl("DiagnosticWarn", { fg = ambar })
end
vim.api.nvim_create_autocmd("ColorScheme", { callback = paleta })
paleta()
