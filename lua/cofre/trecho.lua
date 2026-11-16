-- Trechos selecionados: descobrir o que está selecionado e "mandar pro fim" (tira o trecho de
-- onde está e guarda no fim da nota, depois de uma linha ----). Menu do botão direito: menu.lua.
local M = {}

local function linha(n) -- n a partir de 0; nil se não existe
  return vim.api.nvim_buf_get_lines(0, n, n + 1, false)[1]
end

local function em_branco(s) return s == nil or s:match("^%s*$") ~= nil end

-- A seleção atual, com posições no formato da API (linha a partir de 0, coluna em bytes, fim exclusivo).
function M.selecao()
  local modo = vim.fn.mode()
  if not modo:match("^[vVsS]") then
    return nil
  end
  local a, b = vim.fn.getpos("v"), vim.fn.getpos(".")
  local l1, c1, l2, c2 = a[2], a[3], b[2], b[3]
  if l1 > l2 or (l1 == l2 and c1 > c2) then
    l1, c1, l2, c2 = l2, c2, l1, c1
  end
  local ultima = vim.fn.getline(l2)
  if modo == "V" or modo == "S" then
    c1, c2 = 1, #ultima
  else
    if vim.o.selection == "exclusive" then
      c2 = c2 - 1
    end
    c2 = math.min(c2, #ultima)
    if c2 > 0 then
      c2 = c2 + vim.str_utf_end(ultima, c2) -- até o último byte da letra (acentos têm 2)
    end
  end
  c1 = math.min(c1, #vim.fn.getline(l1) + 1)
  return { l1 = l1 - 1, c1 = c1 - 1, l2 = l2 - 1, c2 = math.max(c2, 0) }
end

function M.sair_da_selecao()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
end

-- Tira o trecho selecionado do lugar e põe no fim da nota, depois de uma linha "----"
-- (criada na primeira vez; as seguintes vão se empilhando embaixo dela).
function M.mandar_pro_fim(s)
  if not s then -- sem trecho guardado pelo menu: usa a seleção de agora
    s = M.selecao()
    if not s then
      vim.notify("selecione um trecho primeiro")
      return
    end
    M.sair_da_selecao()
  end
  local trecho = vim.api.nvim_buf_get_text(0, s.l1, s.c1, s.l2, s.c2, {})
  while #trecho > 0 and em_branco(trecho[1]) do table.remove(trecho, 1) end
  while #trecho > 0 and em_branco(trecho[#trecho]) do table.remove(trecho) end
  if #trecho == 0 then
    return
  end

  vim.api.nvim_buf_set_text(0, s.l1, s.c1, s.l2, s.c2, {})
  -- a linha que sobrou vazia some se já houver outra linha vazia ao lado (ou se for a ponta da nota)
  if em_branco(linha(s.l1)) and (em_branco(linha(s.l1 - 1)) or em_branco(linha(s.l1 + 1))) then
    vim.api.nvim_buf_set_lines(0, s.l1, s.l1 + 1, false, {})
  end

  local total = vim.api.nvim_buf_line_count(0)
  local tem_divisa = false
  for n = total - 1, 0, -1 do
    if linha(n):match("^%-%-%-%-+%s*$") then
      tem_divisa = true
      break
    end
  end
  local novo = {}
  if not em_branco(linha(total - 1)) then novo[#novo + 1] = "" end
  if not tem_divisa then
    novo[#novo + 1] = "----"
    novo[#novo + 1] = ""
  end
  vim.list_extend(novo, trecho)
  vim.api.nvim_buf_set_lines(0, -1, -1, false, novo)

  local l = math.min(s.l1, vim.api.nvim_buf_line_count(0) - 1)
  pcall(vim.api.nvim_win_set_cursor, 0, { l + 1, math.min(s.c1, #(linha(l) or "")) })
  vim.notify("trecho mandado pro fim da nota")
end

return M
