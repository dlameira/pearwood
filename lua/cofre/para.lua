-- Fluxo PARA do cofre: anotar solto na raiz (caixa de entrada) e catalogar depois
-- em 01 Projetos / 02 Áreas / 03 Resources / 04 Arquivo.
local M = {}

M.raiz = vim.env.COFRE or vim.fn.expand("~/Cofre") -- COFRE só para testes
M.para = { "01 Projetos", "02 Áreas", "03 Resources", "04 Arquivo" }
local fora_da_caixa = { ["CLAUDE.md"] = true }

local function caminho(rel)
  return M.raiz .. "/" .. rel
end

-- Notas soltas na raiz = o que falta catalogar.
function M.soltas()
  local itens = {}
  for nome, tipo in vim.fs.dir(M.raiz) do
    if tipo == "file" and nome:match("%.md$") and not fora_da_caixa[nome] then
      table.insert(itens, nome)
    end
  end
  table.sort(itens)
  return itens
end

-- Todas as pastas do PARA (sem Anexos), para escolher destino.
function M.pastas()
  local itens = {}
  for _, topo in ipairs(M.para) do
    if vim.uv.fs_stat(caminho(topo)) then
      table.insert(itens, topo)
      for nome, tipo in vim.fs.dir(caminho(topo), { depth = 4 }) do
        if tipo == "directory" and not nome:match("Anexos") and not nome:match("^%.") then
          table.insert(itens, topo .. "/" .. nome)
        end
      end
    end
  end
  table.sort(itens)
  return itens
end

local function novo_arquivo(rel_dir, linhas)
  vim.ui.input({ prompt = "Título: " }, function(titulo)
    if not titulo or vim.trim(titulo) == "" then
      return
    end
    titulo = vim.trim(titulo):gsub("[/\\:]", "-")
    local dir = rel_dir == "" and M.raiz or caminho(rel_dir)
    local arquivo = dir .. "/" .. titulo .. ".md"
    vim.cmd.edit(vim.fn.fnameescape(arquivo))
    if linhas and vim.uv.fs_stat(arquivo) == nil then
      local corpo = vim.tbl_map(function(l)
        return (l:gsub("{{title}}", titulo))
      end, linhas)
      vim.api.nvim_buf_set_lines(0, 0, -1, false, corpo)
    end
  end)
end

-- Anotar rápido: nota em branco na hora (ver lua/cofre/rascunho.lua).
function M.anotar()
  require("cofre.rascunho").novo()
end

-- Nota nova já direto numa pasta do PARA.
function M.nova_em_pasta()
  vim.ui.select(M.pastas(), { prompt = "Onde no PARA?" }, function(dir)
    if dir then
      novo_arquivo(dir)
    end
  end)
end

-- Verbete de obra mora em 03 Resources/Obras (regra do cofre).
function M.nova_obra()
  local modelo = vim.fn.stdpath("config") .. "/modelos/obra.md"
  novo_arquivo("03 Resources/Obras", vim.fn.readfile(modelo))
end

-- Move um arquivo para uma pasta do PARA. Os links [[nome]] continuam valendo,
-- porque o cofre liga pelo nome da nota, não pelo caminho.
local function mover(origem, destino_rel, depois)
  local destino = caminho(destino_rel) .. "/" .. vim.fs.basename(origem)
  if vim.uv.fs_stat(destino) then
    vim.notify("Já existe uma nota com esse nome em " .. destino_rel, vim.log.levels.WARN)
    return
  end
  local buf = vim.fn.bufnr(origem)
  if buf ~= -1 and vim.bo[buf].modified then
    vim.api.nvim_buf_call(buf, function() vim.cmd.write() end)
  end
  local ok, err = vim.uv.fs_rename(origem, destino)
  if not ok then
    vim.notify("Não consegui mover: " .. tostring(err), vim.log.levels.ERROR)
    return
  end
  if buf ~= -1 then
    vim.api.nvim_buf_set_name(buf, destino)
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent! edit!") end)
  end
  vim.notify(vim.fs.basename(origem) .. " → " .. destino_rel)
  if depois then
    vim.schedule(depois)
  end
end

-- Catalogar: escolhe uma nota solta e para onde ela vai. Repete até esvaziar.
function M.catalogar()
  local soltas = M.soltas()
  if #soltas == 0 then
    vim.notify("Caixa de entrada vazia: tudo catalogado.")
    return
  end
  vim.ui.select(soltas, { prompt = ("Catalogar (%d soltas)"):format(#soltas) }, function(nota)
    if not nota then
      return
    end
    vim.ui.select(M.pastas(), { prompt = nota .. " vai para…" }, function(dir)
      if dir then
        mover(caminho(nota), dir, M.catalogar)
      end
    end)
  end)
end

-- Catalogar a nota aberta agora.
function M.mover_atual()
  local atual = vim.api.nvim_buf_get_name(0)
  if not vim.startswith(atual, M.raiz) or not atual:match("%.md$") then
    vim.notify("Abra uma nota do cofre primeiro.", vim.log.levels.WARN)
    return
  end
  vim.ui.select(M.pastas(), { prompt = vim.fs.basename(atual) .. " vai para…" }, function(dir)
    if dir then
      mover(atual, dir)
    end
  end)
end

-- Ver as soltas (com prévia), sem catalogar.
function M.ver_soltas()
  local itens = {}
  for _, nome in ipairs(M.soltas()) do
    table.insert(itens, { text = nome:gsub("%.md$", ""), file = caminho(nome) })
  end
  if #itens == 0 then
    vim.notify("Nada solto: tudo catalogado.")
    return
  end
  Snacks.picker.pick({ title = ("Soltas (%d)"):format(#itens), items = itens, format = "file", preview = "file" })
end

-- Navegar dentro de uma das quatro caixas.
function M.abrir(topo)
  Snacks.picker.files({ cwd = caminho(topo), title = topo, ft = "md" })
end

return M
