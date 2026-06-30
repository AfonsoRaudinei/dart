#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================

JSON_FILE="$(dirname "$0")/.env.local.json"
EXPORT_OPTIONS_PLIST="$(dirname "$0")/ios/ExportOptions.plist"

if [ ! -f "$JSON_FILE" ]; then
  echo "⚠️  Arquivo $JSON_FILE não encontrado."
  exit 1
fi

if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
  echo "❌ ERRO: ExportOptions.plist não encontrado em $EXPORT_OPTIONS_PLIST."
  exit 1
fi

# Lê variáveis do JSON explicitamente (dart-define-from-file não é confiável)
SUPABASE_URL=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_URL'])")
SUPABASE_ANON_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_ANON_KEY'])")
STADIA_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['STADIA_API_KEY'])")
MAPTILER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['MAPTILER_API_KEY'])")
GOOGLE_WEATHER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['GOOGLE_WEATHER_API_KEY'])")
SUPABASE_PROJECT_REF=$(python3 -c "from urllib.parse import urlparse; import json; d=json.load(open('$JSON_FILE')); print(urlparse(d['SUPABASE_URL']).hostname.split('.')[0])")

BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/version: [0-9.]*+//')
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "============================================"
echo "✅ Config. JSON        : $JSON_FILE"
echo "📦 Versão              : $VERSION"
echo "🔢 Build Number        : $BUILD_NUMBER"
echo "🔐 Credenciais         : carregadas (valores ocultos)"
echo "============================================"

# Valida que as credenciais não estão vazias nem são placeholders
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERRO: SUPABASE_URL ou SUPABASE_ANON_KEY vazios. Abortando."
  exit 1
fi

if [[ "$SUPABASE_URL" == *"seu-projeto.supabase.co"* ]] || [[ "$SUPABASE_URL" == *"example.supabase.co"* ]]; then
  echo "❌ ERRO: SUPABASE_URL ainda é placeholder. Configure a URL real antes de gerar IPA."
  exit 1
fi

if [[ "$SUPABASE_ANON_KEY" == *"sua-chave"* ]] || [[ "$SUPABASE_ANON_KEY" == *"your-anon-key"* ]]; then
  echo "❌ ERRO: SUPABASE_ANON_KEY ainda é placeholder. Configure a anon key real antes de gerar IPA."
  exit 1
fi

if [ -z "$MAPTILER_API_KEY" ]; then
  echo "❌ ERRO: MAPTILER_API_KEY vazia. Abortando para evitar fallback de mapa em produção."
  exit 1
fi

if [[ "$MAPTILER_API_KEY" == *"sua-chave"* ]]; then
  echo "❌ ERRO: MAPTILER_API_KEY ainda é placeholder. Configure a key real antes de gerar IPA."
  exit 1
fi

echo "🧹 Limpando cache..."
flutter clean
flutter pub get
cd ios && pod install --deployment && cd ..

echo "🔨 Iniciando build IPA..."
flutter build ipa \
  --release \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist="$EXPORT_OPTIONS_PLIST" \
  --dart-define=APP_VERSION="$VERSION+$BUILD_NUMBER" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=ENV=production

echo ""
echo "✅ Build $VERSION+$BUILD_NUMBER concluído."

IPA_FILE=$(find build/ios/ipa -maxdepth 1 -name "*.ipa" | head -n 1)
if [ -z "$IPA_FILE" ]; then
  echo "❌ ERRO: IPA não encontrado em build/ios/ipa."
  exit 1
fi

IPA_CHECK_DIR=$(mktemp -d)
unzip -q "$IPA_FILE" -d "$IPA_CHECK_DIR"
IPA_VERSION=$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$IPA_CHECK_DIR/Payload/Runner.app/Info.plist")
IPA_BUILD_NUMBER=$(/usr/bin/plutil -extract CFBundleVersion raw -o - "$IPA_CHECK_DIR/Payload/Runner.app/Info.plist")
rm -rf "$IPA_CHECK_DIR"

if [ "$IPA_VERSION" != "$VERSION" ] || [ "$IPA_BUILD_NUMBER" != "$BUILD_NUMBER" ]; then
  echo "❌ ERRO: IPA exportado com versão/build divergente."
  echo "   Esperado: $VERSION+$BUILD_NUMBER"
  echo "   IPA     : $IPA_VERSION+$IPA_BUILD_NUMBER"
  exit 1
fi

echo "✅ IPA confirmado com versão/build: $IPA_VERSION+$IPA_BUILD_NUMBER"

# Confirmação que credenciais entraram no binário
echo "🔍 Verificando credenciais no binário..."
if strings build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/App | grep -q "$SUPABASE_PROJECT_REF"; then
  echo "✅ SUPABASE_URL confirmada no binário."
else
  echo "❌ ATENÇÃO: SUPABASE_URL NÃO encontrada no binário. NÃO suba este IPA."
  exit 1
fi

echo "📦 IPA em: build/ios/ipa/"
ls -la build/ios/ipa/
