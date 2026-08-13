#!/bin/bash
set -euo pipefail

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================
# Fix IPA 179: caminhos absolutos + pod install resiliente após flutter pub get.
# ============================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

# App Store Connect 90068 (Spring 2027): MinimumOSVersion >= 15.0 em todos os bundles.
# O Flutter SDK ainda grava 13.0 em App.framework/Info.plist após o build — corrigimos no archive.
IOS_MIN_VERSION="15.0"

JSON_FILE="$ROOT/.env.local.json"
EXPORT_OPTIONS_PLIST="$ROOT/ios/ExportOptions.plist"

if [ ! -f "$JSON_FILE" ]; then
  echo "⚠️  Arquivo $JSON_FILE não encontrado."
  exit 1
fi

if [ ! -f "$EXPORT_OPTIONS_PLIST" ]; then
  echo "❌ ERRO: ExportOptions.plist não encontrado em $EXPORT_OPTIONS_PLIST."
  exit 1
fi

# Flutter/Xcode exigem path absoluto — relativo "./ios/..." falha no export.
EXPORT_OPTIONS_PLIST="$(cd "$(dirname "$EXPORT_OPTIONS_PLIST")" && pwd)/$(basename "$EXPORT_OPTIONS_PLIST")"

# Lê variáveis do JSON explicitamente (dart-define-from-file não é confiável)
SUPABASE_URL=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_URL'])")
SUPABASE_ANON_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['SUPABASE_ANON_KEY'])")
STADIA_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['STADIA_API_KEY'])")
MAPTILER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['MAPTILER_API_KEY'])")
GOOGLE_WEATHER_API_KEY=$(python3 -c "import json; d=json.load(open('$JSON_FILE')); print(d['GOOGLE_WEATHER_API_KEY'])")
SUPABASE_PROJECT_REF=$(python3 -c "from urllib.parse import urlparse; import json; d=json.load(open('$JSON_FILE')); print(urlparse(d['SUPABASE_URL']).hostname.split('.')[0])")

BUILD_NUMBER=$(grep "^version:" "$ROOT/pubspec.yaml" | sed 's/version: [0-9.]*+//')
VERSION=$(grep "^version:" "$ROOT/pubspec.yaml" | sed 's/version: //' | sed 's/+.*//')

echo "============================================"
echo "✅ Config. JSON        : $JSON_FILE"
echo "📄 ExportOptions       : $EXPORT_OPTIONS_PLIST"
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

# Flutter.podspec é regenerado com deployment_target 13.0 — alinhar com Podfile (15.0).
FLUTTER_PODSPEC="$ROOT/ios/Flutter/Flutter.podspec"
if [ -f "$FLUTTER_PODSPEC" ]; then
  sed -i '' "s/s.ios.deployment_target = '13.0'/s.ios.deployment_target = '$IOS_MIN_VERSION'/" "$FLUTTER_PODSPEC"
fi

# Após flutter clean + pub get, plugins iOS (ex.: path_provider_foundation)
# podem divergir do Podfile.lock. `pod install --deployment` às vezes só
# avisa e segue (exit 0) com Pods inconsistentes — IPA 179. Sempre
# reconciliar com pod install completo no release.
echo "📦 Instalando CocoaPods (reconciliar com flutter pub get)..."
(
  cd "$ROOT/ios"
  pod install
  echo "✅ pod install OK"
)

echo "🔨 Iniciando build IPA..."

ARCHIVE="$ROOT/build/ios/archive/Runner.xcarchive"
_BUILD_IPA_OK=true

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
  --dart-define=ENV=production || _BUILD_IPA_OK=false

# Workaround: CoreSimulator desatualizado faz flutter build ipa falhar em
# "-destination generic/platform=iOS" mesmo quando o archive é criado.
# O "Xcode archive done" nos logs confirma que Runner.xcarchive existe.
# xcodebuild -exportArchive NÃO usa destination — funciona sem CoreSimulator.
if [ "$_BUILD_IPA_OK" = false ]; then
  echo ""
  echo "⚠️  flutter build ipa retornou erro (provavelmente CoreSimulator desatualizado)."
  if [ ! -d "$ARCHIVE" ]; then
    echo "❌ Archive não encontrado em $ARCHIVE. Falha irrecuperável."
    echo "   Corrija: atualize o macOS (Software Update) para alinhar CoreSimulator."
    exit 1
  fi
  echo "✅ Archive existe em $ARCHIVE — tentando exportar IPA diretamente..."
  rm -rf "$ROOT/build/ios/ipa"
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$ROOT/build/ios/ipa" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
    -allowProvisioningUpdates
  echo "✅ Export concluído via fallback."
fi
APP_FW_PLIST="$ARCHIVE/Products/Applications/Runner.app/Frameworks/App.framework/Info.plist"
if [ -f "$APP_FW_PLIST" ]; then
  APP_FW_MIN=$(/usr/bin/plutil -extract MinimumOSVersion raw -o - "$APP_FW_PLIST" 2>/dev/null || echo "")
  if [ "$APP_FW_MIN" != "$IOS_MIN_VERSION" ]; then
    echo "🔧 App.framework MinimumOSVersion ($APP_FW_MIN → $IOS_MIN_VERSION) — Flutter SDK fix ASC 90068..."
    /usr/bin/plutil -replace MinimumOSVersion -string "$IOS_MIN_VERSION" "$APP_FW_PLIST"
    echo "📦 Re-exportando IPA após patch do archive..."
    rm -rf "$ROOT/build/ios/ipa"
    xcodebuild -exportArchive \
      -archivePath "$ARCHIVE" \
      -exportPath "$ROOT/build/ios/ipa" \
      -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
      -allowProvisioningUpdates
  fi
fi

echo ""
echo "✅ Build $VERSION+$BUILD_NUMBER concluído."

IPA_FILE=$(find "$ROOT/build/ios/ipa" -maxdepth 1 -name "*.ipa" | head -n 1)
if [ -z "$IPA_FILE" ]; then
  echo "❌ ERRO: IPA não encontrado em $ROOT/build/ios/ipa."
  exit 1
fi

IPA_CHECK_DIR=$(mktemp -d)
unzip -q "$IPA_FILE" -d "$IPA_CHECK_DIR"
RUNNER_PLIST="$IPA_CHECK_DIR/Payload/Runner.app/Info.plist"
IPA_VERSION=$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - "$RUNNER_PLIST")
IPA_BUILD_NUMBER=$(/usr/bin/plutil -extract CFBundleVersion raw -o - "$RUNNER_PLIST")
RUNNER_MIN=$(/usr/bin/plutil -extract MinimumOSVersion raw -o - "$RUNNER_PLIST" 2>/dev/null || echo "")
APP_FW_MIN=$(/usr/bin/plutil -extract MinimumOSVersion raw -o - "$IPA_CHECK_DIR/Payload/Runner.app/Frameworks/App.framework/Info.plist" 2>/dev/null || echo "")
rm -rf "$IPA_CHECK_DIR"

if [ "$IPA_VERSION" != "$VERSION" ] || [ "$IPA_BUILD_NUMBER" != "$BUILD_NUMBER" ]; then
  echo "❌ ERRO: IPA exportado com versão/build divergente."
  echo "   Esperado: $VERSION+$BUILD_NUMBER"
  echo "   IPA     : $IPA_VERSION+$IPA_BUILD_NUMBER"
  exit 1
fi

echo "✅ IPA confirmado com versão/build: $IPA_VERSION+$IPA_BUILD_NUMBER"

if [ "$RUNNER_MIN" != "$IOS_MIN_VERSION" ] || [ "$APP_FW_MIN" != "$IOS_MIN_VERSION" ]; then
  echo "❌ ERRO: MinimumOSVersion incorreto no IPA (ASC 90068)."
  echo "   Runner.app       : $RUNNER_MIN (esperado $IOS_MIN_VERSION)"
  echo "   App.framework    : $APP_FW_MIN (esperado $IOS_MIN_VERSION)"
  exit 1
fi
echo "✅ MinimumOSVersion confirmado: Runner=$RUNNER_MIN App.framework=$APP_FW_MIN"

# Confirmação que credenciais entraram no binário.
# Evitar `strings | grep -q` com pipefail: grep -q fecha o pipe cedo → SIGPIPE
# (exit 141) e o check falha mesmo com a URL presente (falso negativo IPA 180).
echo "🔍 Verificando credenciais no binário..."
APP_BIN="$ROOT/build/ios/archive/Runner.xcarchive/Products/Applications/Runner.app/Frameworks/App.framework/App"
if ! grep -aFq "$SUPABASE_PROJECT_REF" "$APP_BIN"; then
  echo "❌ ATENÇÃO: SUPABASE_URL NÃO encontrada no binário. NÃO suba este IPA."
  exit 1
fi
echo "✅ SUPABASE_URL confirmada no binário."

echo "📦 IPA em: $ROOT/build/ios/ipa/"
ls -la "$ROOT/build/ios/ipa/"
