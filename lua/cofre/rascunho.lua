-- Nota nova sem nome ("Anotar"):
--   escreveu e salvou/saiu  -> vira nota solta na raiz; 1ª linha = nome do arquivo
--   "/" como 1º caractere    -> escolhe pasta do PARA e nome
--   Alt + M (a qualquer hora) -> idem
local M = {}

local function para() return require("cofre.para") end

function M.eh_rascunho(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf].cofre_rascunho == true
end

local function vazio(buf)
  local linhas = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  return #linhas == 1 and linhas[1] == "" or table.concat(linhas, ""):match("^%s*$") ~= nil
end

local function limpar_nome(s)
  s = (s or ""):gsub("^%s*#+%s*", ""):gsub("[/\\:]", "-"):gsub("%s+$", ""):gsub("^%s+", "")
  return s
end

local function primeira_linha(buf)
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local n = limpar_nome(l)
    if n ~= "" then
      return n:sub(1, 80)
    end
  end
end

local function caminho_livre(dir, nome)
  local arquivo = dir .. "/" .. nome .. ".md"
  local i = 2
  while vim.uv.fs_stat(arquivo) do
    arquivo = ("%s/%s %d.md"):format(dir, nome, i)
    i = i + 1
  end
  return arquivo
end

-- Dá nome e lugar ao rascunho e salva (se tiver texto).
local function fixar(buf, dir, nome)
  local arquivo = caminho_livre(dir, nome)
  vim.api.nvim_buf_set_name(buf, arquivo)
  vim.b[buf].cofre_rascunho = false
  vim.api.nvim_buf_call(buf, function()
    vim.cmd("silent! write")
    vim.bo.filetype = "markdown"
  end)
  return arquivo
end

-- Salva o rascunho como nota solta, com a 1ª linha de nome. Rascunho vazio não salva.
function M.salvar_solta(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not M.eh_rascunho(buf) or vazio(buf) then
    return false
  end
  fixar(buf, para().raiz, primeira_linha(buf) or os.date("sem título %Y-%m-%d %H%M"))
  return true
end

function M.novo()
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  vim.b[buf].cofre_rascunho = true
  vim.bo[buf].filetype = "markdown"
  vim.bo[buf].bufhidden = "hide"
  vim.cmd.startinsert()
end

-- Escolher pasta do PARA e nome. Serve para rascunho e para nota já existente.
function M.guardar_em()
  local buf = vim.api.nvim_get_current_buf()
  local rascunho = M.eh_rascunho(buf)
  local atual = vim.api.nvim_buf_get_name(buf)
  local opcoes = { "✎ Solta (raiz, catalogar depois)" }
  vim.list_extend(opcoes, para().pastas())
  vim.cmd("stopinsert")
  vim.ui.select(opcoes, { prompt = "Onde vai a nota?" }, function(escolha)
    if not escolha then
      vim.cmd.startinsert()
      return
    end
    local dir = escolha == opcoes[1] and para().raiz or (para().raiz .. "/" .. escolha)
    local sugestao = rascunho and (primeira_linha(buf) or "") or vim.fn.fnamemodify(atual, ":t:r")
    vim.ui.input({ prompt = "Nome da nota: ", default = sugestao }, function(nome)
      nome = limpar_nome(nome)
      if nome == "" then
        vim.cmd.startinsert()
        return
      end
      if rascunho then
        fixar(buf, dir, nome)
      else
        -- nota existente: move (e renomeia, se mudou o nome)
        vim.cmd("silent! write")
        local destino = caminho_livre(dir, nome)
        if destino ~= atual then
          local ok, err = vim.uv.fs_rename(atual, destino)
          if not ok then
            vim.notify("Não consegui mover: " .. tostring(err), vim.log.levels.ERROR)
            return
          end
          vim.api.nvim_buf_set_name(buf, destino)
          vim.cmd("silent! edit!")
        end
      end
      vim.notify("Guardada em " .. (dir == para().raiz and "solta (raiz)" or escolha) .. " / " .. nome)
      vim.cmd.startinsert()
    end)
  end)
end

-- "/" só abre a escolha se for o primeiro caractere de uma nota nova.
function M.barra()
  if M.eh_rascunho() and vazio(0) then
    vim.schedule(M.guardar_em)
    return ""
  end
  return "/"
end

-- Ao sair do rascunho (trocar de nota, voltar, fechar): salva como solta ou descarta se vazio.
vim.api.nvim_create_autocmd("BufHidden", {
  callback = function(ev)
    if not M.eh_rascunho(ev.buf) then
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      if not M.salvar_solta(ev.buf) and vazio(ev.buf) then
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end
    end)
  end,
})

-- Antes de fechar o Cofre: rascunhos com texto viram notas soltas.
function M.salvar_todos()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if M.eh_rascunho(b) then
      if not M.salvar_solta(b) then
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end
end

return M
