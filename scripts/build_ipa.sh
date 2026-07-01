#!/usr/bin/env bash
# Build IPA de release com chaves Supabase embutidas em tempo de compilação.
# Requer: macOS, Xcode, Flutter stable, dart_defines.json preenchido.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${ROOT}/dart_defines.json"
BUILD_NUMBER="${1:-153}"

cd "$ROOT"

if [[ ! -f "$DEFINES" ]]; then
  echo "ERRO: arquivo dart_defines.json não encontrado."
  echo "Copie o template e preencha a anon key:"
  echo "  cp dart_defines.example.json dart_defines.json"
  exit 1
fi

if grep -q "COLE_SUA_ANON_KEY" "$DEFINES"; then
  echo "ERRO: substitua COLE_SUA_ANON_KEY_AQUI em dart_defines.json pela anon key real."
  exit 1
fi

echo "==> SoloForte IPA build ${BUILD_NUMBER}"
echo "==> dart_defines.json encontrado (Supabase URL/key serão compilados no app)"

flutter pub get

flutter build ipa \
  --build-number="${BUILD_NUMBER}" \
  --dart-define-from-file="${DEFINES}"

echo ""
echo "IPA gerado. Saída típica:"
echo "  build/ios/ipa/*.ipa"
echo ""
echo "Verifique no dispositivo: login Supabase deve funcionar (build ${BUILD_NUMBER})."
