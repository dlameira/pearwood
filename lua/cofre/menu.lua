-- Menu do botão direito, em português e só com o que serve para escrever.
-- Com um trecho selecionado: recortar, copiar, colar por cima, mandar pro fim, comentar.
-- Sem seleção: colar, selecionar tudo, editar ou remover o comentário sob o cursor.
vim.cmd([[
  silent! aunmenu PopUp
  silent! autocmd! nvim.popupmenu
  vnoremenu PopUp.Recortar "+d
  vnoremenu PopUp.Copiar "+y
  vnoremenu PopUp.Colar "_d"+P
  vnoremenu PopUp.-trecho- <Nop>
  vnoremenu PopUp.Mandar\ pro\ fim <Cmd>lua require("cofre.trecho").mandar_pro_fim()<CR>
  vnoremenu PopUp.Comentar <Cmd>lua require("cofre.comentario").comentar()<CR>
  inoremenu PopUp.Colar <C-r><C-o>+
  inoremenu PopUp.Selecionar\ tudo <Esc>gg0vG$<C-g>
  inoremenu PopUp.-comentario- <Nop>
  inoremenu PopUp.Editar\ comentário <Cmd>lua require("cofre.comentario").editar()<CR>
  inoremenu PopUp.Remover\ comentário <Cmd>lua require("cofre.comentario").remover()<CR>
  nnoremenu PopUp.Colar "+p
  nnoremenu PopUp.Selecionar\ tudo gg0vG$<C-g>
  nnoremenu PopUp.-comentario- <Nop>
  nnoremenu PopUp.Editar\ comentário <Cmd>lua require("cofre.comentario").editar()<CR>
  nnoremenu PopUp.Remover\ comentário <Cmd>lua require("cofre.comentario").remover()<CR>
]])
