#!/usr/bin/env bash
# Confere se a MAPTILER_API_KEY realmente serve tile de satélite.
#
# MapTiler responde 403 "Invalid key" para chave apagada/errada; o app trata
# isso como tile vazio e o mapa fica branco sem nenhum erro visível.
#
# Uso: tool/check_maptiler_key.sh [CHAVE]   (padrão: $MAPTILER_API_KEY)
# Saída: 0 = chave serve tile · 1 = chave recusada (401/403/outro HTTP) ·
#        2 = sem rede ou chave vazia (não foi possível provar nada)
# A chave nunca é impressa.

set -u

KEY="${1:-${MAPTILER_API_KEY:-}}"
if [ -z "$KEY" ]; then
  echo "❌ MAPTILER_API_KEY vazia." >&2
  exit 2
fi

# Tile z12 sobre o Brasil central — mesma URL base que MapConfig usa.
URL="https://api.maptiler.com/maps/satellite-v4/256/12/1519/2310.jpg?key=$KEY"
STATUS="$(curl -s -o /dev/null -m 15 -A 'com.soloforte.soloforteApp' \
  -w '%{http_code}' "$URL" || true)"

case "$STATUS" in
  200)
    echo "✅ MAPTILER_API_KEY serve tile de satélite (HTTP 200)."
    exit 0
    ;;
  000|"")
    echo "⚠️  Sem resposta do MapTiler (rede?). Chave não validada." >&2
    exit 2
    ;;
  *)
    echo "❌ MapTiler recusou a chave (HTTP $STATUS). O satélite ficaria branco." >&2
    echo "   Gere/ative uma chave em https://cloud.maptiler.com/account/keys/" >&2
    exit 1
    ;;
esac
