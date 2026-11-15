-- Salva sozinho, como o Obsidian: 1 s depois de parar de digitar.
-- Nota nova sem nome ("Anotar") é salva como solta depois de 3 s parado,
-- com a 1ª linha de nome; dali em diante vira uma nota normal.
local timers = {}

local function salvar(buf)
  if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].modified then
    return
  end
  local r = require("cofre.rascunho")
  if r.eh_rascunho(buf) then
    r.salvar_solta(buf)
  elseif vim.bo[buf].filetype == "markdown" and vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
    vim.api.nvim_buf_call(buf, function() vim.cmd("silent! lockmarks noautocmd write") end)
  end
end

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "InsertLeave" }, {
  callback = function(ev)
    if vim.bo[ev.buf].filetype ~= "markdown" then
      return
    end
    local espera = require("cofre.rascunho").eh_rascunho(ev.buf) and 3000 or 1000
    if timers[ev.buf] then
      timers[ev.buf]:stop()
    else
      timers[ev.buf] = vim.uv.new_timer()
    end
    timers[ev.buf]:start(espera, 0, vim.schedule_wrap(function() salvar(ev.buf) end))
  end,
})

-- Saindo do Cofre ou perdendo o foco: salva o que estiver pendente na hora.
vim.api.nvim_create_autocmd({ "FocusLost", "VimLeavePre" }, {
  callback = function()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      salvar(b)
    end
  end,
})
