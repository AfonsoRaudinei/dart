#!/usr/bin/env bash
#
# Envio do IPA SoloForte para App Store Connect / TestFlight.
#
# Issuer ID: App Store Connect → Users and Access → Integrations →
# App Store Connect API → Issuer ID (UUID)
#
# Forneça via:
#   1) ./tool/upload_testflight.sh <ISSUER_ID>
#   2) export ASC_ISSUER_ID=...
#   3) echo "<ISSUER_ID>" > ios/.asc_issuer_id   (gitignored)
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA_PATH="${ROOT}/build/ios/ipa/soloforte_app.ipa"
API_KEY_ID="M3424Q9LY2"

ISSUER_ID="${1:-${ASC_ISSUER_ID:-}}"
if [[ -z "${ISSUER_ID}" && -f "${ROOT}/ios/.asc_issuer_id" ]]; then
  ISSUER_ID="$(tr -d '[:space:]' < "${ROOT}/ios/.asc_issuer_id")"
fi

if [[ -z "${ISSUER_ID}" ]]; then
  echo "ERRO: Issuer ID não informado."
  echo "  ./tool/upload_testflight.sh <ISSUER_ID>"
  exit 1
fi

if [[ ! -f "${IPA_PATH}" ]]; then
  echo "ERRO: IPA não encontrado em ${IPA_PATH}"
  echo "Gere antes com: ./build_testflight.sh"
  exit 1
fi

echo "Enviando ${IPA_PATH} (API key ${API_KEY_ID})..."
xcrun altool --upload-app \
  --type ios \
  -f "${IPA_PATH}" \
  --apiKey "${API_KEY_ID}" \
  --apiIssuer "${ISSUER_ID}"

echo "Upload concluído. Aguarde processamento no TestFlight (App Store Connect)."
