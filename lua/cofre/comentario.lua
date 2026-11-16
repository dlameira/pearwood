-- Comentários presos a um trecho, guardados no próprio Markdown no formato do Obsidian:
--   ==trecho comentado==%%o comentário%%
-- (grifo + comentário oculto: no Obsidian o trecho aparece grifado e o comentário some na leitura).
-- Aqui o trecho fica sublinhado, as marcas somem fora da linha do cursor e o comentário aparece
-- numa linha embaixo. Menu do botão direito: menu.lua.
local M = {}
local ns = vim.api.nvim_create_namespace("cofre_comentarios")

local function cores()
  vim.api.nvim_set_hl(0, "CofreComentado", { underline = true, sp = "#ffc107" })
  vim.api.nvim_set_hl(0, "CofreComentarioMarca", { fg = "#ffc107" })
  vim.api.nvim_set_hl(0, "CofreComentario", { fg = "#7a7a7a", italic = true })
end

-- Todos os comentários da nota: posições (linha a partir de 0, coluna em bytes) de "==" (a),
-- do "==%%" de fechamento (b), do fim do "%%" final (c, exclusivo) e o texto.
local function analisar(buf)
  local linhas = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local texto = table.concat(linhas, "\n")
  local inicio, p = {}, 0
  for i, l in ipairs(linhas) do
    inicio[i] = p
    p = p + #l + 1
  end
  local function pos(desloc) -- deslocamento (a partir de 0) -> linha, coluna
    local lo, hi = 1, #inicio
    while lo < hi do
      local meio = math.floor((lo + hi + 1) / 2)
      if inicio[meio] <= desloc then lo = meio else hi = meio - 1 end
    end
    return lo - 1, desloc - inicio[lo]
  end
  local achados, de = {}, 1
  while true do
    local a = texto:find("==", de, true)
    if not a then break end
    local b = texto:find("==", a + 2, true)
    if not b then break end
    local dentro = texto:sub(a + 2, b - 1)
    if dentro == "" or dentro:find("\n%s*\n") then
      de = a + 2 -- não é um grifo: não atravessa parágrafo
    elseif texto:sub(b + 2, b + 3) == "%%" then
      local c = texto:find("%%", b + 4, true)
      local comentario = c and texto:sub(b + 4, c - 1)
      if c and not comentario:find("\n") then
        local ar, ac = pos(a - 1)
        local br, bc = pos(b - 1)
        local cr, cc = pos(c + 1)
        achados[#achados + 1] = { ar = ar, ac = ac, br = br, bc = bc, cr = cr, cc = cc, texto = comentario }
        de = c + 2
      else
        de = b + 2
      end
    else
      de = b + 2 -- grifo sem comentário
    end
  end
  return achados
end

local function quebrar(texto, largura) -- comentário comprido ocupa mais de uma linha embaixo
  local linhas, atual = {}, ""
  for palavra in texto:gmatch("%S+") do
    if atual ~= "" and vim.fn.strdisplaywidth(atual .. " " .. palavra) > largura then
      linhas[#linhas + 1] = atual
      atual = palavra
    else
      atual = atual == "" and palavra or (atual .. " " .. palavra)
    end
  end
  if atual ~= "" then linhas[#linhas + 1] = atual end
  return linhas
end

function M.marcar(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  local largura = math.max(30, vim.api.nvim_win_get_width(0) - 8)
  for _, c in ipairs(analisar(buf)) do
    vim.api.nvim_buf_set_extmark(buf, ns, c.ar, c.ac, { end_row = c.ar, end_col = c.ac + 2, conceal = "" })
    vim.api.nvim_buf_set_extmark(buf, ns, c.ar, c.ac + 2, { end_row = c.br, end_col = c.bc, hl_group = "CofreComentado" })
    vim.api.nvim_buf_set_extmark(buf, ns, c.br, c.bc, { end_row = c.cr, end_col = c.cc, conceal = "" })
    local embaixo = {}
    for i, l in ipairs(quebrar(c.texto, largura)) do
      embaixo[#embaixo + 1] = { { i == 1 and "  ✎ " or "    ", "CofreComentarioMarca" }, { l, "CofreComentario" } }
    end
    vim.api.nvim_buf_set_extmark(buf, ns, c.cr, 0, { virt_lines = embaixo })
  end
end

local function sob_o_cursor(calado)
  local cur = vim.api.nvim_win_get_cursor(0)
  local l, col = cur[1] - 1, cur[2]
  for _, c in ipairs(analisar(0)) do
    local depois_do_inicio = l > c.ar or (l == c.ar and col >= c.ac)
    local antes_do_fim = l < c.cr or (l == c.cr and col <= c.cc)
    if depois_do_inicio and antes_do_fim then
      return c
    end
  end
  if not calado then
    vim.notify("o cursor não está num trecho comentado")
  end
end
M.sob_o_cursor = sob_o_cursor

local function limpar(txt)
  return (txt:gsub("[\r\n]+", " "):gsub("%%%%+", "%%"):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- Comenta o trecho selecionado.
function M.comentar(s)
  local trecho_mod = require("cofre.trecho")
  if not s then -- sem trecho guardado pelo menu: usa a seleção de agora
    s = trecho_mod.selecao()
    if not s then
      vim.notify("selecione um trecho primeiro")
      return
    end
    trecho_mod.sair_da_selecao()
  end
  s = vim.deepcopy(s)
  local buf = vim.api.nvim_get_current_buf()
  local trecho = vim.api.nvim_buf_get_text(buf, s.l1, s.c1, s.l2, s.c2, {})
  -- as marcas encostam no texto: espaços nas pontas da seleção ficam de fora
  while #trecho > 1 and trecho[1]:match("^%s*$") do
    table.remove(trecho, 1)
    s.l1, s.c1 = s.l1 + 1, 0
  end
  while #trecho > 1 and trecho[#trecho]:match("^%s*$") do
    table.remove(trecho)
    s.l2 = s.l2 - 1
    s.c2 = #vim.api.nvim_buf_get_lines(buf, s.l2, s.l2 + 1, false)[1]
  end
  s.c1 = s.c1 + #trecho[1]:match("^%s*")
  s.c2 = s.c2 - #trecho[#trecho]:match("%s*$")
  local junto = table.concat(trecho, "\n")
  if junto:match("^%s*$") then
    return
  end
  if junto:find("\n%s*\n") then
    vim.notify("o comentário precisa ficar dentro de um parágrafo só")
    return
  end
  vim.ui.input({ prompt = "Comentário" }, function(txt)
    if not txt or txt:match("^%s*$") then
      return
    end
    vim.api.nvim_buf_set_text(buf, s.l2, s.c2, s.l2, s.c2, { "==%%" .. limpar(txt) .. "%%" })
    vim.api.nvim_buf_set_text(buf, s.l1, s.c1, s.l1, s.c1, { "==" })
    M.marcar(buf)
  end)
end

-- Troca o texto do comentário em que o cursor está.
function M.editar()
  local c = sob_o_cursor()
  if not c then
    return
  end
  local buf = vim.api.nvim_get_current_buf()
  vim.ui.input({ prompt = "Comentário", default = c.texto }, function(txt)
    if not txt or txt:match("^%s*$") then
      return
    end
    vim.api.nvim_buf_set_text(buf, c.br, c.bc, c.cr, c.cc, { "==%%" .. limpar(txt) .. "%%" })
    M.marcar(buf)
  end)
end

-- Tira o comentário (e o grifo) do trecho em que o cursor está; o texto fica.
function M.remover()
  local c = sob_o_cursor()
  if not c then
    return
  end
  vim.api.nvim_buf_set_text(0, c.br, c.bc, c.cr, c.cc, {})
  vim.api.nvim_buf_set_text(0, c.ar, c.ac, c.ar, c.ac + 2, {})
  M.marcar(0)
end

cores()
vim.api.nvim_create_autocmd("ColorScheme", { callback = cores })
local espera = {}
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave", "VimResized" }, {
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "markdown" then
      return
    end
    if espera[ev.buf] then
      return
    end
    espera[ev.buf] = true
    vim.defer_fn(function()
      espera[ev.buf] = nil
      if vim.api.nvim_buf_is_valid(ev.buf) and vim.api.nvim_get_current_buf() == ev.buf then
        M.marcar(ev.buf)
      end
    end, 80)
  end,
})

return M
