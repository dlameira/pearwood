#!/usr/bin/env bash
# Aplica na hora uma mudança feita no editor: pede a cada pearwood aberto que salve tudo,
# reinicie e volte à mesma nota, no mesmo ponto (ver lua/cofre/recarregar.lua).
dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
achou=0
for sock in "$dir"/pearwood.*.0; do
  [ -S "$sock" ] || continue
  achou=1
  nvim --server "$sock" --remote-send '<Cmd>lua require("cofre.recarregar").agora()<CR>' >/dev/null 2>&1
done
[ "$achou" = 1 ] || echo "nenhum pearwood aberto"
