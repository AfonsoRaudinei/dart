#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================

# ─── Arquivo de Configuração JSON ─────────────────────────────────────
# Agora estamos utilizando o .env.local.json diretamente,
# resolvendo o problema das atualizações de configuração não passarem pro IPA.
JSON_FILE="$(dirname "$0")/.env.local.json"

if [ ! -f "$JSON_FILE" ]; then
  echo "⚠️  Arquivo de configuração $JSON_FILE não encontrado."
  echo "   Crie o arquivo ou verifique se o nome está correto antes de buildar."
  exit 1
fi
echo "📋 Arquivo JSON de configurações encontrado."
# ─────────────────────────────────────────────────────────────────────

BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/version: [0-9.]*+//')
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "============================================"
echo "✅ Config. JSON     : $JSON_FILE"
echo "📦 Versão           : $VERSION"
echo "🔢 Build Number     : $BUILD_NUMBER"
echo "============================================"

echo "🧹 Limpando cache iOS e Flutter (garante envio das atualizações)..."
rm -rf ios/Pods ios/Podfile.lock
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..

echo "🔨 Iniciando build IPA para TestFlight..."

flutter build ipa \
  --release \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --dart-define-from-file="$JSON_FILE" \
  --dart-define=ENV=production

echo ""
echo "✅ Build $VERSION+$BUILD_NUMBER concluído com sucesso."
echo "📦 Arquivo gerado em: build/ios/ipa/"
ls -la build/ios/ipa/ 2>/dev/null || echo "⚠️  Diretório build/ios/ipa/ não encontrado."
