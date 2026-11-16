-- Marca de rolagem: um pontinho (quase um pixel) na borda direita da tela, na altura
-- em que a nota está rolada (em cima = começo, embaixo = fim). Sem trilho e sem cor de destaque,
-- para quase não aparecer. Some quando a nota cabe inteira na tela e fora das notas.
local M = {}
local janela, buf

local function esconder()
  if janela and vim.api.nvim_win_is_valid(janela) then
    pcall(vim.api.nvim_win_close, janela, true)
  end
  janela = nil
end

local function atualizar()
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return -- lista ou caixa por cima: a marca fica onde estava
  end
  if vim.bo.filetype ~= "markdown" or vim.bo.buftype ~= "" then
    return esconder()
  end
  local total = vim.api.nvim_buf_line_count(0)
  local primeira, ultima = vim.fn.line("w0"), vim.fn.line("w$")
  if primeira <= 1 and ultima >= total then
    return esconder() -- cabe tudo na tela
  end
  local altura = vim.api.nvim_win_get_height(win)
  local fora = math.max(1, total - (ultima - primeira + 1)) -- linhas que não cabem
  local fracao = math.min(1, math.max(0, (primeira - 1) / fora))
  local cfg = {
    relative = "editor",
    row = vim.fn.win_screenpos(win)[1] - 1 + math.floor(fracao * (altura - 1) + 0.5),
    col = vim.o.columns - 1,
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    border = "none", -- o padrão das janelas flutuantes aqui é borda arredondada (winborder)
    zindex = 1,
  }
  if janela and vim.api.nvim_win_is_valid(janela) then
    vim.api.nvim_win_set_config(janela, cfg)
    return
  end
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "·" })
  end
  cfg.noautocmd = true
  janela = vim.api.nvim_open_win(buf, false, cfg)
  vim.wo[janela].winhighlight = "Normal:CofreRolagem,NormalFloat:CofreRolagem"
  vim.wo[janela].winblend = 0
end

local function cores() vim.api.nvim_set_hl(0, "CofreRolagem", { fg = "#7a7a7a", bg = "NONE" }) end
cores()
vim.api.nvim_create_autocmd("ColorScheme", { callback = cores })
vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter", "VimResized", "TextChanged", "TextChangedI" }, {
  callback = function() vim.schedule(function() pcall(atualizar) end) end,
})

M.atualizar = atualizar
return M
