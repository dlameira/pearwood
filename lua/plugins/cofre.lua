-- Perfil "pearwood": Neovim só para o cofre (~/Cofre), organizado pelo PARA.
-- Abrir pelo atalho "pearwood" ou `NVIM_APPNAME=pearwood nvim` dentro do cofre.
-- Teclas próprias ficam em <leader>o (leader = espaço). Fluxo em lua/cofre/para.lua.

local cofre = require("cofre.para").raiz
local function para(fn, ...)
  local args = { ... }
  return function() require("cofre.para")[fn](unpack(args)) end
end

-- Nome do arquivo = título como foi digitado (com espaço e acento), igual ao Obsidian.
local function titulo_como_nome(title)
  if not title or vim.trim(title) == "" then
    return os.date("sem título %Y-%m-%d %H%M")
  end
  return (vim.trim(title):gsub("[/\\:]", "-"))
end

return {
  -- ---------------------------------------------------------------- cofre
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    lazy = false,
    opts = {
      legacy_commands = false,
      workspaces = { { name = "cofre", path = cofre } },
      new_notes_location = "current_dir", -- [[link novo]] nasce na pasta da nota atual
      note_id_func = titulo_como_nome,
      note = { template = vim.NIL },
      frontmatter = { enabled = false }, -- nota de ideia/texto não leva frontmatter
      link = { style = "wiki", format = "shortest" },
      daily_notes = {
        -- Diário dentro de "02 Áreas" só se o cofre já usa o PARA; senão fica na raiz (não cria pastas no cofre de ninguém).
        folder = vim.uv.fs_stat(cofre .. "/02 Áreas") and "02 Áreas/Diário" or nil,
        date_format = "YYYY-MM-DD",
        default_tags = {},
        workdays_only = false,
      },
      attachments = { folder = "./Anexos" },
      picker = { name = "snacks.picker" },
      completion = { min_chars = 2, create_new = true },
      ui = { enable = false }, -- quem desenha o markdown é o render-markdown
      footer = { enabled = false },
    },
    keys = {
      { "<leader>oh", function() require("cofre.nav").inicio() end, desc = "Tela inicial do Cofre" },
      { "<leader>oa", para("anotar"), desc = "Anotar (solta na raiz)" },
      { "<leader>oc", para("catalogar"), desc = "Catalogar soltas" },
      { "<leader>ov", para("ver_soltas"), desc = "Ver soltas" },
      { "<leader>om", function() require("cofre.rascunho").guardar_em() end, desc = "Guardar em… (pasta e nome)" },
      { "<leader>on", para("nova_em_pasta"), desc = "Nova nota numa pasta do PARA" },
      { "<leader>oo", para("nova_obra"), desc = "Novo verbete de obra" },
      { "<leader>o1", para("abrir", "01 Projetos"), desc = "Projetos" },
      { "<leader>o2", para("abrir", "02 Áreas"), desc = "Áreas" },
      { "<leader>o3", para("abrir", "03 Resources"), desc = "Resources" },
      { "<leader>o4", para("abrir", "04 Arquivo"), desc = "Arquivo" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Diário de hoje" },
      { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Diário de ontem" },
      { "<leader>oD", "<cmd>Obsidian dailies<cr>", desc = "Todos os diários" },
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Buscar nota" },
      { "<leader>og", "<cmd>Obsidian search<cr>", desc = "Buscar no texto" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Quem cita esta nota" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links desta nota" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Renomear (atualiza links)" },
      { "<leader>os", "<cmd>Obsidian toc<cr>", desc = "Sumário da nota" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Colar imagem" },
      { "<leader>ox", "<cmd>Obsidian toggle_checkbox<cr>", desc = "Marcar/desmarcar caixa" },
      { "<leader>oz", function() Snacks.zen() end, desc = "Modo foco" },
    },
  },

  -- ---------------------------------------------- markdown bonito no buffer
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    opts = {
      render_modes = { "n", "c" }, -- ao digitar mostra o texto cru
      heading = { sign = false, width = "block", left_pad = 1, right_pad = 2, border = true },
      code = { sign = false, width = "block", right_pad = 2, border = "thin" },
      bullet = { icons = { "•", "◦", "▪", "▫" } },
      checkbox = {
        unchecked = { icon = "☐ " },
        checked = { icon = "☑ " },
      },
      quote = { icon = "▌" },
      pipe_table = {
        style = "full",
        cell = "padded",
        border = { "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘", "│", "─" },
      },
      link = { wiki = { icon = "◈ " } },
    },
  },

  -- ----------------------------------- autocompletar só quando abrir [[ ou #
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.completion = opts.completion or {}
      opts.completion.ghost_text = { enabled = false }
      -- Ctrl + P/N/Y ficam para a paleta, nota nova e refazer
      opts.keymap = opts.keymap or {}
      opts.keymap["<C-p>"] = {}
      opts.keymap["<C-n>"] = {}
      opts.keymap["<C-y>"] = {}
      opts.completion.menu = opts.completion.menu or {}
      opts.completion.menu.border = "single"
      opts.completion.menu.auto_show = function()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local antes = vim.api.nvim_get_current_line():sub(1, col)
        return antes:match("%[%[[^%]]*$") ~= nil or antes:match("#[%w_/-]*$") ~= nil
      end
    end,
  },

  -- ----------------------------------------------------- painéis e entrada
  {
    "folke/snacks.nvim",
    opts = {
      zen = {
        toggles = { dim = false, git_signs = false, diagnostics = false },
        win = { width = 90, backdrop = { transparent = false } },
      },
      picker = {
        -- guarda de qual buffer a lista saiu, para o Esc da nota saber voltar para ela
        on_show = function() vim.g.cofre_lista = { buf = vim.api.nvim_get_current_buf(), fechou = math.huge } end,
        -- nas listas: Esc fecha (2x rápido: início), Alt + H início, Alt + ← fecha
        actions = require("cofre.nav").acoes,
        win = {
          input = { keys = {
            ["<Esc>"] = { "cofre_esc", mode = { "i", "n" } },
            ["<a-h>"] = { "cofre_inicio", mode = { "i", "n" } },
            ["<a-Left>"] = { "cofre_esc", mode = { "i", "n" } },
          } },
          list = { keys = {
            ["<Esc>"] = "cofre_esc",
            ["<a-h>"] = "cofre_inicio",
            ["<a-Left>"] = "cofre_esc",
          } },
        },
        on_close = function()
          if vim.g.cofre_lista then
            vim.g.cofre_lista = { buf = vim.g.cofre_lista.buf, fechou = vim.uv.now() }
          end
        end,
      },
      dashboard = {
        preset = {
          header = table.concat({
            "┌─────────────────────────────────┐",
            "│             C O F R E           │",
            "│  projetos · áreas · resources   │",
            "└─────────────────────────────────┘",
          }, "\n"),
          keys = {
            { icon = "✎ ", key = "a", desc = "Anotar", action = para("anotar") },
            { icon = "⇲ ", key = "c", desc = "Catalogar soltas", action = para("catalogar") },
            { icon = "◌ ", key = "s", desc = "Ver soltas", action = para("ver_soltas") },
            { icon = "◷ ", key = "d", desc = "Diário de hoje", action = ":Obsidian today" },
            { icon = "▸ ", key = "1", desc = "Projetos", action = para("abrir", "01 Projetos") },
            { icon = "▸ ", key = "2", desc = "Áreas", action = para("abrir", "02 Áreas") },
            { icon = "▸ ", key = "3", desc = "Resources", action = para("abrir", "03 Resources") },
            { icon = "▸ ", key = "4", desc = "Arquivo", action = para("abrir", "04 Arquivo") },
            { icon = "⌕ ", key = "f", desc = "Buscar nota", action = ":Obsidian quick_switch" },
            { icon = "≡ ", key = "g", desc = "Buscar no texto", action = ":Obsidian search" },
            { icon = "⏻ ", key = "q", desc = "Sair", action = function() require("cofre.nav").sair() end },
          },
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
        },
      },
    },
  },
}
