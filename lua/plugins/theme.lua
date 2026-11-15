-- Tema: segue o tema atual do Omarchy (e a troca ao vivo, via omarchy-theme-hotreload.lua).
-- Fora do Omarchy, fica o tema padrão do LazyVim.
local arquivo = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.uv.fs_stat(arquivo) then
  return dofile(arquivo)
end
return {}
