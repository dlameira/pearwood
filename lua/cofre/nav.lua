-- Navegação do Cofre, no estilo do navegador:
--   Esc          volta um nível (escrevendo -> comandos -> lista/nota anterior/início)
--   Esc Esc      (rápido) vai para a tela inicial, de qualquer lugar
--   Alt + ←/→    voltar / avançar
--   Alt + H      tela inicial
local M = {}

local JANELA_DUPLO = 400 -- ms entre dois Esc para contar como duplo
local ultimo_esc = 0
local frente = {} -- notas de onde voltei, para o Alt + →
M.avancando = false

function M.eh_nota(buf)
  buf = buf or 0
  return vim.bo[buf].filetype == "markdown" and vim.bo[buf].buftype == ""
end

-- Registra um Esc e diz se ele foi o segundo de um par rápido.
function M.esc_duplo()
  local agora = vim.uv.now()
  local duplo = agora - ultimo_esc < JANELA_DUPLO
  ultimo_esc = duplo and 0 or agora
  return duplo
end

local function salvar()
  local r = require("cofre.rascunho")
  if r.eh_rascunho() then
    r.salvar_solta()
  elseif M.eh_nota() and vim.bo.modified and vim.api.nvim_buf_get_name(0) ~= "" then
    vim.cmd("silent! write")
  end
end
M.salvar = salvar

function M.sair()
  require("cofre.rascunho").salvar_todos()
  vim.cmd("silent! wall")
  vim.cmd("qa")
end

local function abrir_inicio()
  require("cofre.fonte").preparar_inicio()
  -- num buffer vazio a tela inicial ocupa a janela; sobre uma nota ela abriria flutuando
  vim.cmd("enew")
  Snacks.dashboard({ win = 0, buf = vim.api.nvim_get_current_buf() })
end

function M.inicio()
  salvar()
  vim.cmd("stopinsert")
  abrir_inicio()
end

function M.voltar()
  if not M.eh_nota() then
    return
  end
  vim.cmd("nohlsearch")
  salvar()
  table.insert(frente, vim.api.nvim_buf_get_name(0))
  local volta = vim.b.cofre_volta or { tipo = "inicio" }
  if volta.tipo == "lista" then
    Snacks.picker.resume() -- a lista reaparece por cima do texto
  elseif volta.tipo == "nota" and vim.api.nvim_buf_is_valid(volta.buf) then
    vim.g.cofre_voltando = true
    vim.api.nvim_set_current_buf(volta.buf)
  else
    abrir_inicio()
  end
end

function M.avancar()
  local alvo = table.remove(frente)
  if not alvo then
    return
  end
  salvar()
  M.avancando = true
  vim.cmd.edit(vim.fn.fnameescape(alvo))
end

-- Abrir uma nota por outro caminho apaga o "avançar", como no navegador.
function M.limpar_frente()
  if M.avancando then
    M.avancando = false
  else
    frente = {}
  end
end

-- Esc na nota, modo de comandos.
function M.esc_normal()
  if M.esc_duplo() then
    M.inicio()
  else
    M.voltar()
  end
end

-- Sem modos: na nota o Esc nunca "sai da escrita", ele já navega.
M.esc_escrita = M.esc_normal

-- Paleta de comandos (Ctrl + P), como no Obsidian.
local function cmd(c) return function() vim.cmd(c) end end
local function para(fn, ...)
  local a = { ... }
  return function() require("cofre.para")[fn](unpack(a)) end
end
M.comandos = {
  { "Anotar (nota solta)", "Ctrl + N", para("anotar") },
  { "Abrir nota pelo nome", "Ctrl + O", cmd("Obsidian quick_switch") },
  { "Buscar no texto do cofre", "Ctrl + Shift + F", cmd("Obsidian search") },
  { "Buscar nesta nota", "Ctrl + F", function() Snacks.picker.lines() end },
  { "Catalogar soltas", "", para("catalogar") },
  { "Ver soltas", "", para("ver_soltas") },
  { "Guardar em… (pasta do PARA e nome)", "Alt + M  ou  / no início", function() require("cofre.rascunho").guardar_em() end },
  { "Nova nota numa pasta do PARA", "", para("nova_em_pasta") },
  { "Novo verbete de obra", "", para("nova_obra") },
  { "Diário de hoje", "", cmd("Obsidian today") },
  { "Diário de ontem", "", cmd("Obsidian yesterday") },
  { "Todos os diários", "", cmd("Obsidian dailies") },
  { "Projetos", "", para("abrir", "01 Projetos") },
  { "Áreas", "", para("abrir", "02 Áreas") },
  { "Resources", "", para("abrir", "03 Resources") },
  { "Arquivo", "", para("abrir", "04 Arquivo") },
  { "Quem cita esta nota (backlinks)", "", cmd("Obsidian backlinks") },
  { "Links desta nota", "", cmd("Obsidian links") },
  { "Renomear nota (atualiza links)", "", cmd("Obsidian rename") },
  { "Sumário da nota", "", cmd("Obsidian toc") },
  { "Colar imagem", "", cmd("Obsidian paste_img") },
  { "Marcar/desmarcar caixa", "", cmd("Obsidian toggle_checkbox") },
  { "Modo foco", "", function() Snacks.zen() end },
  { "Tela inicial", "Alt + H / Esc Esc", function() M.inicio() end },
  { "Fechar o Cofre", "", function() M.sair() end },
}

function M.paleta()
  vim.cmd("stopinsert")
  local itens = {}
  for i, c in ipairs(M.comandos) do
    itens[i] = { text = c[1] .. " " .. c[2], nome = c[1], atalho = c[2], acao = c[3] }
  end
  Snacks.picker.pick({
    title = "Comandos",
    items = itens,
    layout = { preset = "select" },
    format = function(item)
      return { { item.nome }, { "  " .. item.atalho, "Comment" } }
    end,
    confirm = function(picker, item)
      picker:close()
      vim.g.cofre_lista = nil -- a paleta não é "lista de onde a nota veio"
      if item then vim.schedule(item.acao) end
    end,
  })
end

-- Ações para as listas (snacks picker).
M.acoes = {
  cofre_inicio = function(picker)
    picker:close()
    vim.schedule(M.inicio)
  end,
  cofre_esc = function(picker)
    local duplo = M.esc_duplo()
    picker:close()
    if duplo then
      vim.schedule(M.inicio)
    end
  end,
}

return M
