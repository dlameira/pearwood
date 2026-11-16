# pearwood

**Um editor para um cofre de notas em Markdown (como o do Obsidian), feito sobre o Neovim, mas com cara e atalhos de
editor de texto comum.** As notas abrem já em modo de escrita, sem modos do Vim para decorar, e o cofre se organiza
pelo método PARA.

Feito para o [Omarchy](https://omarchy.org) (Linux com Hyprland): segue o tema do sistema e roda num terminal kitty
próprio, com a fonte ajustada para leitura.

## O que ele faz

- **Editor comum:** Ctrl+C/X/V, Ctrl+Z/Y, Ctrl+A, setas andando por linhas visuais e salvamento automático 1 s depois de
  parar de digitar.
- **Navegação como num navegador:**
  - **Esc** volta um nível; **Esc Esc** vai para a tela inicial;
  - **Alt+← / Alt+→** voltar e avançar entre notas;
  - **Alt+H** tela inicial.
- **Anotar primeiro, organizar depois (PARA):**
  - **Ctrl+N** cria uma nota solta, sem pedir nome, que fica na raiz do cofre (a caixa de entrada);
  - começar a nota com **/**, ou usar **Alt+M**, escolhe a pasta e o nome;
  - a tela inicial mostra o que falta catalogar em `01 Projetos`, `02 Áreas`, `03 Resources` e `04 Arquivo`.
- **Achar coisas:**
  - **Ctrl+O** abre uma nota pelo nome;
  - **Ctrl+F** busca na nota; **Ctrl+Shift+F** busca no cofre inteiro;
  - **Ctrl+P** abre a paleta de comandos;
  - **Ctrl+Enter** segue um `[[link]]`.
- **Botão direito num trecho selecionado:**
  - **Mandar pro fim** tira o trecho de onde está e guarda no fim da nota, depois de uma linha `----` (as sobras vão
    se empilhando ali);
  - **Comentar** prende um comentário ao trecho. Fica no próprio arquivo, no formato do Obsidian
    (`==trecho==%%comentário%%`): o trecho aparece sublinhado e o comentário, numa linha embaixo. Com o botão direito
    sobre um trecho comentado dá para **editar** ou **remover** o comentário;
  - recortar, copiar e colar também estão ali.
- **Leitura confortável:** texto numa coluna centralizada, Markdown renderizado e sem barra de status. Um pontinho
  na borda direita mostra em que altura da nota você está.

## Requisitos

- Omarchy (ou Arch com Neovim 0.11+, kitty e uma Nerd Font). Fora do Omarchy funciona, mas com o tema padrão do LazyVim.
- Um cofre de notas: por padrão `~/Cofre`. Outra pasta: variável `COFRE`.

## Seu cofre

O pearwood não traz notas: ele abre a pasta que você já tem (por padrão `~/Cofre`; outra pasta com `COFRE=`). Serve
qualquer pasta de arquivos `.md`, inclusive um cofre do Obsidian, que continua funcionando no Obsidian ao mesmo tempo.

- Arquivos `.md` soltos na raiz da pasta são a caixa de entrada (o que falta catalogar).
- Os atalhos do PARA esperam as pastas `01 Projetos`, `02 Áreas`, `03 Resources` e `04 Arquivo`. Sem elas, o resto
  funciona e esses atalhos só não têm aonde ir. Os nomes ficam em `lua/cofre/para.lua` e nos menus de
  `lua/plugins/cofre.lua` e `lua/cofre/nav.lua`.
- O diário vai para `02 Áreas/Diário` quando existe `02 Áreas`; senão, para a raiz.
- O editor não cria pastas no seu cofre por conta própria.

## Instalar

```bash
git clone https://github.com/dlameira/pearwood.git
cd pearwood
./instalar.sh                    # ou: COFRE=~/MinhasNotas ./instalar.sh
```

O instalador liga `~/.config/pearwood` a esta pasta (o perfil `NVIM_APPNAME=pearwood`, separado do seu Neovim de
sempre) e cria o atalho **pearwood** no menu de apps. Na primeira vez que abrir, o lazy.nvim baixa os plugins.

Atualizar: `git pull` na pasta e reabrir o pearwood.

## O nome

Nos livros do Discworld, de Terry Pratchett, a Bagagem é um baú feito de pereira sapiente (*sapient pearwood*): segue
o dono a qualquer lugar e protege o que guarda.

## Licença

Apache 2.0 (`LICENSE`), herdada do [LazyVim starter](https://github.com/LazyVim/starter). Alguns arquivos vêm do
[Omarchy](https://github.com/omacom/omarchy), sob MIT: lista em `NOTICE`.
