#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================

JSON_FILE="$(dirname "$0")/.env.local.json"

if [ ! -f "$JSON_FILE" ]; then
  echo "⚠️  Arquivo $JSON_FILE não encontrado."
  exit 1
fi

# Lê variáveis do JSON explicitamente (dart-define-from-file não é confiável)
SUPABASE_URL=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_URL'])")
SUPABASE_ANON_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_ANON_KEY'])")
STADIA_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['STADIA_API_KEY'])")
MAPTILER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['MAPTILER_API_KEY'])")
GOOGLE_WEATHER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['GOOGLE_WEATHER_API_KEY'])")

BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/version: [0-9.]*+//')
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "============================================"
echo "✅ Config. JSON        : $JSON_FILE"
echo "📦 Versão              : $VERSION"
echo "🔢 Build Number        : $BUILD_NUMBER"
echo "🔗 SUPABASE_URL        : ${SUPABASE_URL:0:40}..."
echo "🔑 SUPABASE_ANON_KEY   : ${SUPABASE_ANON_KEY:0:20}..."
echo "============================================"

# Valida que as credenciais não estão vazias
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERRO: SUPABASE_URL ou SUPABASE_ANON_KEY vazios. Abortando."
  exit 1
fi

echo "🧹 Limpando cache..."
rm -rf ios/Pods ios/Podfile.lock
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..

echo "🔨 Iniciando build IPA..."
flutter build ipa \
  --release \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=ENV=production

echo ""
echo "✅ Build $VERSION+$BUILD_NUMBER concluído."

# Confirmação que credenciais entraram no binário
echo "🔍 Verificando credenciais no binário..."
if strings build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/App | grep -q "pyoejhhkjlrjijiviryq"; then
  echo "✅ SUPABASE_URL confirmada no binário."
else
  echo "❌ ATENÇÃO: SUPABASE_URL NÃO encontrada no binário. NÃO suba este IPA."
  exit 1
fi

echo "📦 IPA em: build/ios/ipa/"
ls -la build/ios/ipa/
