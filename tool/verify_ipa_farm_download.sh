#!/usr/bin/env bash
# Confirma que o IPA contém o botão Baixar mapa da fazenda (AGENTIPA).
set -euo pipefail
IPA="${1:-build/ios/ipa/soloforte_app.ipa}"
if [[ ! -f "$IPA" ]]; then
  echo "❌ IPA não encontrado: $IPA"
  exit 1
fi
TMP=$(mktemp -d)
unzip -q "$IPA" -d "$TMP"
APP="$TMP/Payload/Runner.app/Frameworks/App.framework/App"
if grep -aFq "Baixar mapa" "$APP" && grep -aFq "Baixando mapa da fazenda" "$APP"; then
  echo "✅ Baixar mapa presente no binário."
  rm -rf "$TMP"
  exit 0
fi
echo "❌ Strings do download da fazenda ausentes no IPA."
rm -rf "$TMP"
exit 1
