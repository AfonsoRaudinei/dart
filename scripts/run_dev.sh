#!/usr/bin/env bash
# =============================================================================
# run_dev.sh — Script de execução local (desenvolvimento)
#
# USO:
#   chmod +x scripts/run_dev.sh
#   ./scripts/run_dev.sh
#
# ANTES DE USAR:
#   1. Copie este arquivo: cp scripts/run_dev.sh scripts/run_dev.local.sh
#   2. Preencha as variáveis em run_dev.local.sh com suas credenciais reais
#   3. O arquivo *.local.sh está no .gitignore — nunca será commitado
#
# NUNCA commite credenciais reais neste arquivo.
# =============================================================================

# Variáveis de ambiente — substitua pelos valores reais no arquivo .local.sh
SUPABASE_URL="https://seu-projeto.supabase.co"
SUPABASE_ANON_KEY="sua-chave-anonima-aqui"
ENV="development"

flutter run \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=ENV="$ENV"
