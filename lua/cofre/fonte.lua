-- Fonte e margem do Cofre: tela inicial em 9 e sem margem; notas em 11 e com
-- a margem centralizada (no-neck-pain). A fonte é pedida ao kitty pela socket.
local M = { inicio = 9, nota = 11 }
local atual = M.inicio

local function pedir(tamanho)
  local sock = vim.env.KITTY_LISTEN_ON
  if not sock or tamanho == atual then
    return
  end
  atual = tamanho
  vim.system({ "kitty", "@", "--to", sock, "set-font-size", tostring(tamanho) })
end

-- Margem: coluna centralizada com espaço vazio dos dois lados (no-neck-pain).
local function margem_ligada()
  return _G.NoNeckPain and _G.NoNeckPain.state and _G.NoNeckPain.state.enabled == true
end

local function com_margem(ligar)
  local ok, nnp = pcall(require, "no-neck-pain")
  if not ok then
    return
  end
  if ligar then
    if not margem_ligada() then
      pcall(nnp.enable)
    end
    return
  end
  if margem_ligada() then
    -- o disable público é atrasado (debounce); aqui precisa fechar as laterais já
    pcall(require("no-neck-pain.main").disable, "cofre")
  end
  -- garante uma janela só, para a tela inicial ocupar tudo
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if w ~= vim.api.nvim_get_current_win() and vim.api.nvim_win_get_config(w).relative == "" then
      pcall(vim.api.nvim_win_close, w, true)
    end
  end
end

local function ajustar()
  if vim.api.nvim_win_get_config(0).relative ~= "" then
    return -- listas/janelas flutuantes não mudam a fonte
  end
  local ft = vim.bo.filetype
  if ft == "snacks_dashboard" then
    com_margem(false)
    pedir(M.inicio)
  elseif ft == "markdown" and vim.bo.buftype == "" then
    -- margens antes da fonte: senão aparece um instante com o texto grande
    -- ocupando a janela toda, antes de a coluna estreitar
    com_margem(true)
    vim.cmd("redraw")
    pedir(M.nota)
  end
end

-- Antes de abrir a tela inicial: tira a margem (senão ela abre flutuando) e volta a fonte.
function M.preparar_inicio()
  com_margem(false)
  pedir(M.inicio)
end

vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "WinEnter" }, {
  callback = function() vim.schedule(ajustar) end,
})

return M
