-- Cofre: texto numa coluna centralizada, com espaço vazio igual dos dois lados.
-- Liga/desliga pela lua/cofre/fonte.lua (só nas notas; a tela inicial fica sem).
return {
  "shortcuts/no-neck-pain.nvim",
  version = "*",
  lazy = false,
  opts = {
    width = 78,
    minSideBufferWidth = 1,
    autocmds = { enableOnVimEnter = false, skipEnteringNoNeckPainBuffer = true },
    buffers = {
      scratchPad = { enabled = false },
      wo = { fillchars = "eob: ,vert: ,vertleft: ,vertright: ,verthoriz: " },
    },
  },
}
