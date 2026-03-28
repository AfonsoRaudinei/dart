#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================

if [ -f ".env.local" ]; then
  source .env.local
  echo "📋 Variáveis carregadas de .env.local"
fi

if [ -z "$SUPABASE_URL" ]; then
  SUPABASE_URL="https://pyoejhhkjlrjijiviryq.supabase.co"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5b2VqaGhramxyamlqaXZpcnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTI1MDQsImV4cCI6MjA2OTcyODUwNH0.2P5wKq7b6viMa9kutLOZADsqAvSZx6X8fbLZMlooG1U"
fi

if [ -z "$STADIA_API_KEY" ]; then
  STADIA_API_KEY="5b0c0038-b833-4e1d-adfa-756241cab907"
fi

if [ -z "$SUPABASE_URL" ]; then echo "❌ ERRO: SUPABASE_URL não definida." && exit 1; fi
if [ -z "$SUPABASE_ANON_KEY" ]; then echo "❌ ERRO: SUPABASE_ANON_KEY não definida." && exit 1; fi

BUILD_NUMBER=$(grep "^version:" pubspec.yaml | sed 's/version: [0-9.]*+//')
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "============================================"
echo "✅ SUPABASE_URL     : $SUPABASE_URL"
echo "✅ SUPABASE_ANON_KEY: [configurada]"
echo "✅ STADIA_API_KEY   : [configurada]"
echo "📦 Versão           : $VERSION"
echo "🔢 Build Number     : $BUILD_NUMBER"
echo "============================================"

echo "🧹 Limpando cache Flutter..."
flutter clean
flutter pub get

echo "🔨 Iniciando build IPA para TestFlight..."

flutter build ipa \
  --release \
  --build-name="$VERSION" \
  --build-number="$BUILD_NUMBER" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=ENV=production

echo ""
echo "✅ Build $VERSION+$BUILD_NUMBER concluído com sucesso."
echo "📦 Arquivo gerado em: build/ios/ipa/"
ls -la build/ios/ipa/ 2>/dev/null || echo "⚠️  Diretório build/ios/ipa/ não encontrado."
