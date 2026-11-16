-- Menu do botão direito do pearwood: uma janelinha própria, em português, só com o que serve
-- para escrever. Com um trecho selecionado: recortar, copiar, colar por cima, mandar pro fim,
-- comentar. Sem seleção: colar, selecionar tudo e, sobre um trecho comentado, editar ou remover
-- o comentário.
--
-- Não usa o menu "PopUp" do Neovim: quando a seleção nasce no meio da digitação ele mostra os
-- itens de seleção mas executa a versão "de digitar" do item (E335). Aqui a seleção é guardada
-- antes de o menu abrir e cada ação recebe esse trecho.
local M = {}
local trecho = require("cofre.trecho")
local ns = vim.api.nvim_create_namespace("cofre_menu")
local aberto -- { win, buf, nota }

local function fechar()
  local a = aberto
  aberto = nil
  if not a then
    return
  end
  vim.o.mousemoveevent = a.movimento
  if vim.api.nvim_buf_is_valid(a.nota) then
    vim.api.nvim_buf_clear_namespace(a.nota, ns, 0, -1)
  end
  if vim.api.nvim_win_is_valid(a.win) then
    pcall(vim.api.nvim_win_close, a.win, true)
  end
end

local function abrir(itens, linha_tela, coluna_tela)
  local nota = vim.api.nvim_get_current_buf()
  local largura = 0
  for _, it in ipairs(itens) do
    if it ~= "-" then largura = math.max(largura, vim.fn.strdisplaywidth(it[1]) + 2) end
  end
  local linhas = {}
  for _, it in ipairs(itens) do
    linhas[#linhas + 1] = it == "-" and string.rep("─", largura) or (" " .. it[1])
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, linhas)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "cofre_menu"
  -- cabe na tela: sobe ou vai para a esquerda se o clique foi perto da borda
  local row = math.max(0, math.min(linha_tela, vim.o.lines - #linhas - 3))
  local col = math.max(0, math.min(coluna_tela, vim.o.columns - largura - 3))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", row = row, col = col, width = largura, height = #linhas,
    style = "minimal", border = "rounded", zindex = 200,
  })
  vim.wo[win].cursorline = true
  vim.wo[win].winhighlight = "Normal:CofreMenu,CursorLine:CofreMenuItem,FloatBorder:FloatBorder"
  vim.cmd.stopinsert()
  aberto = { win = win, buf = buf, nota = nota, movimento = vim.o.mousemoveevent }
  vim.o.mousemoveevent = true -- para o realce acompanhar o mouse enquanto o menu está aberto

  local function ir(passo) -- anda pulando as divisórias
    local n = vim.api.nvim_win_get_cursor(win)[1]
    for _ = 1, #itens do
      n = (n - 1 + passo) % #itens + 1
      if itens[n] ~= "-" then break end
    end
    vim.api.nvim_win_set_cursor(win, { n, 0 })
  end
  local function escolher()
    local it = itens[vim.api.nvim_win_get_cursor(win)[1]]
    fechar()
    if it and it ~= "-" then
      vim.schedule(it[2])
    end
  end
  local function tecla(lhs, fn)
    vim.keymap.set({ "n", "i" }, lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  local function sob_o_mouse() -- leva o realce para o item em que o mouse está
    local m = vim.fn.getmousepos()
    if m.winid == win and m.line >= 1 and m.line <= #itens and itens[m.line] ~= "-" then
      vim.api.nvim_win_set_cursor(win, { m.line, 0 })
      return true
    end
  end
  tecla("<CR>", escolher)
  tecla("<LeftMouse>", sob_o_mouse)
  tecla("<MouseMove>", sob_o_mouse)
  tecla("<LeftRelease>", function()
    if sob_o_mouse() then
      escolher()
    else
      fechar() -- soltou em cima de uma divisória ou fora do menu
    end
  end)
  tecla("<Esc>", fechar)
  tecla("q", fechar)
  tecla("<Down>", function() ir(1) end)
  tecla("j", function() ir(1) end)
  tecla("<Up>", function() ir(-1) end)
  tecla("k", function() ir(-1) end)
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = function() vim.schedule(fechar) end })
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
  if itens[1] == "-" then ir(1) end
end

local function texto(s) return vim.api.nvim_buf_get_text(0, s.l1, s.c1, s.l2, s.c2, {}) end

local function colar_em(l1, c1, l2, c2)
  local linhas = vim.split(vim.fn.getreg("+"), "\n", { plain = true })
  vim.api.nvim_buf_set_text(0, l1, c1, l2, c2, linhas)
  local fim_c = (#linhas == 1 and c1 or 0) + #linhas[#linhas]
  pcall(vim.api.nvim_win_set_cursor, 0, { l1 + #linhas, fim_c })
end

local function itens_do_trecho(s)
  return {
    { "Recortar", function()
      vim.fn.setreg("+", table.concat(texto(s), "\n"))
      vim.api.nvim_buf_set_text(0, s.l1, s.c1, s.l2, s.c2, {})
      pcall(vim.api.nvim_win_set_cursor, 0, { s.l1 + 1, s.c1 })
    end },
    { "Copiar", function() vim.fn.setreg("+", table.concat(texto(s), "\n")) end },
    { "Colar", function() colar_em(s.l1, s.c1, s.l2, s.c2) end },
    "-",
    { "Mandar pro fim", function() trecho.mandar_pro_fim(s) end },
    { "Comentar", function() require("cofre.comentario").comentar(s) end },
  }
end

local function itens_sem_trecho()
  local cur = vim.api.nvim_win_get_cursor(0)
  local itens = {
    { "Colar", function() colar_em(cur[1] - 1, cur[2], cur[1] - 1, cur[2]) end },
    { "Selecionar tudo", function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>gg0vG$<C-g>", true, false, true), "n", false)
    end },
  }
  local comentario = require("cofre.comentario")
  if comentario.sob_o_cursor(true) then
    itens[#itens + 1] = "-"
    itens[#itens + 1] = { "Editar comentário", comentario.editar }
    itens[#itens + 1] = { "Remover comentário", comentario.remover }
  end
  return itens
end

-- Clique com o botão direito numa nota.
function M.botao_direito()
  fechar()
  if vim.bo.filetype ~= "markdown" or vim.bo.buftype ~= "" then
    return
  end
  local mouse = vim.fn.getmousepos()
  local s = trecho.selecao()
  if s then
    trecho.sair_da_selecao()
    -- a seleção some ao abrir o menu: o trecho fica realçado enquanto ele estiver aberto
    vim.api.nvim_buf_set_extmark(0, ns, s.l1, s.c1, { end_row = s.l2, end_col = s.c2, hl_group = "Visual" })
    abrir(itens_do_trecho(s), mouse.screenrow, mouse.screencol - 1)
  else
    if mouse.winid == vim.api.nvim_get_current_win() and mouse.line > 0 then
      pcall(vim.api.nvim_win_set_cursor, 0, { mouse.line, math.max(mouse.column - 1, 0) })
    end
    abrir(itens_sem_trecho(), mouse.screenrow, mouse.screencol - 1)
  end
end

local function cores()
  vim.api.nvim_set_hl(0, "CofreMenu", { fg = "#ffffff", bg = "#000000" })
  vim.api.nvim_set_hl(0, "CofreMenuItem", { fg = "#000000", bg = "#7a7a7a" })
end
cores()
vim.api.nvim_create_autocmd("ColorScheme", { callback = cores })

vim.cmd("silent! aunmenu PopUp")
vim.cmd("silent! autocmd! nvim.popupmenu")
vim.keymap.set({ "n", "i", "x", "s" }, "<RightMouse>", function() M.botao_direito() end, { desc = "Menu do botão direito" })
for _, t in ipairs({ "<RightRelease>", "<RightDrag>", "<2-RightMouse>", "<3-RightMouse>", "<4-RightMouse>" }) do
  vim.keymap.set({ "n", "i", "x", "s" }, t, "<Nop>")
end

M.fechar = fechar
return M
