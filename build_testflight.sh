#!/bin/bash
set -e

# ============================================================
# SoloForte — Build TestFlight (iOS)
# ============================================================
# Variáveis obrigatórias — defina via .env.local (nunca commitar):
#   export SUPABASE_URL=https://SEU_PROJETO.supabase.co
#   export SUPABASE_ANON_KEY=SUA_CHAVE_ANON
#
# Ou passe diretamente antes de executar:
#   SUPABASE_URL=https://... SUPABASE_ANON_KEY=... ./build_testflight.sh
# ============================================================

# Carregar variáveis locais se existirem
if [ -f ".env.local" ]; then
  # shellcheck source=/dev/null
  source .env.local
  echo "📋 Variáveis carregadas de .env.local"
fi

# Fallback: se variáveis ainda vazias, usar valores hardcoded (legado)
if [ -z "$SUPABASE_URL" ]; then
  SUPABASE_URL="https://pyoejhhkjlrjijiviryq.supabase.co"
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5b2VqaGhramxyamlqaXZpcnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTI1MDQsImV4cCI6MjA2OTcyODUwNH0.2P5wKq7b6viMa9kutLOZADsqAvSZx6X8fbLZMlooG1U"
fi

# Validação fail-fast
if [ -z "$SUPABASE_URL" ]; then
  echo "❌ ERRO: SUPABASE_URL não definida."
  exit 1
fi

if [ -z "$SUPABASE_ANON_KEY" ]; then
  echo "❌ ERRO: SUPABASE_ANON_KEY não definida."
  exit 1
fi

echo "✅ SUPABASE_URL: $SUPABASE_URL"
echo "✅ SUPABASE_ANON_KEY: [configurada]"
echo ""
echo "🔨 Iniciando build IPA para TestFlight..."

flutter build ipa \
  --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV=production

echo ""
echo "✅ Build concluído com sucesso."
echo "📦 Arquivo gerado em: build/ios/ipa/"
ls build/ios/ipa/ 2>/dev/null || echo "⚠️  Diretório build/ios/ipa/ não encontrado."
