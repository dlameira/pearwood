# pearwood

Editor para um cofre de notas em Markdown (estilo Obsidian): um perfil próprio do Neovim (`NVIM_APPNAME=pearwood`) sobre o
LazyVim, com atalhos de editor comum (sem modos), navegação de navegador e fluxo PARA. Feito para o Omarchy.
Para instalar e usar: `README.md`.

## Regras
- **As notas nunca entram aqui.** O repo é só o editor; o cofre é outra pasta (`COFRE`, padrão `~/Cofre`).
- Nada pessoal no código nem nos textos: caminhos fixos de usuário, nomes de pastas reais do cofre, conteúdo de notas.
  Caminhos sempre via `~`/`$HOME`/`COFRE`; os nomes do PARA (`01 Projetos`…) são os genéricos.
- `README.md` é para quem instala: manter os atalhos e o "Instalar" de acordo com o código, no mesmo commit.
- Arquivo vindo do Omarchy ou do LazyVim: manter a lista em `NOTICE`.

O módulo `lua/cofre/` e o nome "cofre" no código se referem à pasta de notas, não ao app (que é o pearwood).

## Estrutura
- `init.lua`, `lua/config/` (options, keymaps de editor comum, autocmds, área de transferência), `lua/plugins/`: base do
  LazyVim starter + arquivos do Omarchy (tema, troca de tema ao vivo, transparência).
- `lua/plugins/theme.lua`: carrega o tema atual do Omarchy (`~/.local/state/omarchy/current/theme/neovim.lua`); sem ele,
  fica o tema padrão.
- `lua/cofre/`: `para.lua` (caixa de entrada na raiz, catalogar, mover), `nav.lua` (Esc em níveis, Esc Esc, Alt+setas,
  Alt+H, paleta Ctrl+P), `rascunho.lua` (nota nova sem nome; "/" no início ou Alt+M escolhe pasta e nome),
  `fonte.lua` (fonte 9 na tela inicial e 11 nas notas, pedida ao kitty pela socket; margem com no-neck-pain),
  `autosalvar.lua` (1 s depois de parar de digitar), `trecho.lua` (seleção atual; "mandar pro fim"),
  `comentario.lua` (comentários `==trecho==%%texto%%`, mostrados com extmarks), `menu.lua` (menu do botão direito),
  `recarregar.lua` (salva, reinicia com `:restart` e volta à mesma nota e posição), `rolagem.lua` (pontinho na
  borda direita indicando a altura da rolagem).
- `lua/plugins/cofre.lua` (obsidian.nvim, render-markdown, blink só em `[[`/`#`, tela inicial), `cofre-margem.lua`,
  `cofre-rodape.lua` (sem barra inferior).
- `modelos/obra.md`: modelo de nota de referência.
- `kitty.conf` (terminal próprio, com socket para a fonte), `pearwood.desktop.in` (modelo do atalho), `instalar.sh`.

## Desenvolvimento
- Plugins (lazy.nvim) ficam fora do repo, em `~/.local/share/pearwood`.
- Mudanças de Lua só valem ao reabrir o editor. Para aplicar na hora num pearwood aberto: `./recarregar.sh` (ele
  pisca e volta na mesma nota). O `:restart` trava com o noice ligado, por isso `recarregar.lua` o desliga antes.
- Testar sem mexer na janela de quem está escrevendo: abrir outro pearwood com `COFRE` de teste e conversar com ele
  pela socket (`$XDG_RUNTIME_DIR/pearwood.<pid>.0`, `nvim --server … --remote-expr/--remote-send`). Esc na nota volta
  para a tela inicial: nos testes, posicionar com `<Cmd>call cursor()<CR>` e selecionar com Shift+setas.
- Nunca criar pastas no cofre do usuário sem ele pedir (ex.: o diário só usa `02 Áreas/Diário` se `02 Áreas` existir).
- Testar com outro cofre: `COFRE=/tmp/cofre-teste NVIM_APPNAME=pearwood nvim`.

## Pendências
- [ ] Nomes das pastas do PARA repetidos em `para.lua`, `plugins/cofre.lua` e `nav.lua`: deixar só em `para.lua`.
- [ ] Tela inicial no visual do painel do LazyVim (logo grande), mantendo os itens do cofre.
- [ ] Captura rápida "para pesquisar" (ideia em aberto).
- [ ] Ao trocar de fonte (9 → 11) ainda há uma piscada; alternativa é tamanho único.
- [ ] Captura de tela para o README, com notas inventadas.

## Onde paramos
2026-11-15 · Botão direito com "mandar pro fim" e comentários em trechos; recarregamento na hora (`recarregar.sh`);
paleta comum e cantos arredondados. O menu do botão direito foi testado pelos comandos, não com clique de verdade.
Antes, no mesmo dia: preparado para virar público (README, NOTICE, `instalar.sh`), renomeado para `pearwood`.
