#!/usr/bin/env bash
# Build AAB de release com chaves Supabase embutidas em tempo de compilação.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFINES="${ROOT}/dart_defines.json"
BUILD_NUMBER="${1:-153}"

cd "$ROOT"

if [[ ! -f "$DEFINES" ]]; then
  echo "ERRO: copie dart_defines.example.json para dart_defines.json e preencha as chaves."
  exit 1
fi

if grep -q "COLE_SUA_ANON_KEY" "$DEFINES"; then
  echo "ERRO: substitua a anon key placeholder em dart_defines.json."
  exit 1
fi

flutter pub get

flutter build appbundle \
  --build-number="${BUILD_NUMBER}" \
  --dart-define-from-file="${DEFINES}"

echo "AAB: build/app/outputs/bundle/release/app-release.aab"
