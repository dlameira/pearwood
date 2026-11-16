-- Recarregar o editor sem perder o lugar: salva tudo, reinicia o Neovim (:restart) e reabre a
-- nota em que se estava, com o cursor na mesma posição. É como uma mudança no próprio editor
-- passa a valer na hora (o Lua só é lido ao abrir). De fora: ./recarregar.sh
local M = {}

function M.agora()
  pcall(function() require("cofre.rascunho").salvar_todos() end) -- nota nova sem nome vira nota solta
  vim.cmd("silent! wall")
  -- o noice recebe os eventos de tela e não conhece o de reinício: com ele ligado o :restart trava
  pcall(function() require("noice").disable() end)
  local nome = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype ~= "" or nome == "" or vim.fn.filereadable(nome) == 0 then
    vim.cmd("restart!") -- na tela inicial ou numa lista: só reinicia
    return
  end
  local pos = vim.api.nvim_win_get_cursor(0)
  -- :restart! não restaura sessão; o comando depois dele roda no Neovim novo
  vim.cmd(("restart! lua require('cofre.recarregar').voltar(%q, %d, %d)"):format(nome, pos[1], pos[2]))
end

function M.voltar(nome, linha, coluna)
  if vim.fn.filereadable(nome) == 0 then
    return
  end
  -- o comando do :restart roda antes de o editor terminar de se montar (os módulos do cofre
  -- entram no evento VeryLazy); abrir a nota antes disso deixaria fonte, margem e cursor de fora
  local function quando_pronto(tentativas)
    if not package.loaded["cofre.menu"] and tentativas > 0 then
      vim.defer_fn(function() quando_pronto(tentativas - 1) end, 30)
      return
    end
    vim.cmd.edit(vim.fn.fnameescape(nome))
    -- só com a nota já no modo de digitar o cursor pode ficar depois da última letra da linha
    local function posicionar(tentativas)
      if vim.api.nvim_buf_get_name(0) ~= nome then
        return
      end
      if vim.fn.mode():sub(1, 1) ~= "i" and tentativas > 0 then
        vim.defer_fn(function() posicionar(tentativas - 1) end, 40)
        return
      end
      linha = math.min(linha, vim.api.nvim_buf_line_count(0))
      pcall(vim.api.nvim_win_set_cursor, 0, { linha, 0 })
      vim.cmd("normal! zz") -- centraliza antes: o "normal!" tira o cursor do fim da linha
      pcall(vim.api.nvim_win_set_cursor, 0, { linha, coluna })
    end
    vim.defer_fn(function() posicionar(40) end, 80)
  end
  vim.schedule(function() quando_pronto(100) end)
end

vim.api.nvim_create_user_command("PearwoodRecarregar", M.agora, { desc = "Reinicia o editor e volta à mesma nota" })

return M
