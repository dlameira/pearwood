#!/usr/bin/env bash
# Instala o pearwood: liga ~/.config/pearwood a este clone e cria o atalho "pearwood" no menu de apps.
# Uso: ./instalar.sh            (cofre em ~/Cofre)
#      COFRE=~/Notas ./instalar.sh
# Seguro rodar de novo (por exemplo, depois de mudar o clone de lugar).
set -euo pipefail
AQUI="$(cd "$(dirname "$0")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
DADOS="${XDG_DATA_HOME:-$HOME/.local/share}"
ESTADO="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG="$CFG/pearwood"
COFRE="${COFRE:-$HOME/Cofre}"

# Versões antigas usavam o perfil "notas" e o atalho "Cofre": migra só se o perfil antigo apontava para este clone.
if [[ -L "$CFG/notas" && "$(readlink -f "$CFG/notas")" == "$AQUI" ]]; then
  rm "$CFG/notas"
  [[ -d "$DADOS/notas" && ! -e "$DADOS/pearwood" ]] && mv "$DADOS/notas" "$DADOS/pearwood"
  [[ -d "$ESTADO/notas" && ! -e "$ESTADO/pearwood" ]] && mv "$ESTADO/notas" "$ESTADO/pearwood"
  rm -f "$DADOS/applications/cofre.desktop"
  echo "Migrado do perfil antigo \"notas\"."
fi

if [[ -e "$CONFIG" && "$(readlink -f "$CONFIG")" != "$AQUI" ]]; then
  echo "Já existe $CONFIG e não é este clone. Mova ou apague essa pasta e rode de novo." >&2
  exit 1
fi
[[ -d "$COFRE" ]] || echo "Aviso: a pasta do cofre $COFRE ainda não existe." >&2

ln -sfn "$AQUI" "$CONFIG"
mkdir -p "$DADOS/applications"
sed -e "s|@CONFIG@|$CONFIG|g" -e "s|@COFRE@|$COFRE|g" "$AQUI/pearwood.desktop.in" > "$DADOS/applications/pearwood.desktop"
echo "Pronto: $CONFIG -> $AQUI; atalho \"pearwood\" no menu de apps (cofre: $COFRE)."
