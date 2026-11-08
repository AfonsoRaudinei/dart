#!/usr/bin/env bash
# Publica a Edge loja-verificar-compra no projeto Supabase linkado.
# Secrets Apple/Google: configurar no Dashboard ou via supabase secrets set (não commitar).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null; then
  echo "❌ supabase CLI não encontrado. Instale: https://supabase.com/docs/guides/cli"
  exit 1
fi

if [ ! -d "$ROOT/supabase/functions/loja-verificar-compra" ]; then
  echo "❌ Pasta supabase/functions/loja-verificar-compra ausente"
  exit 1
fi

echo "→ Deno tests (loja-verificar-compra)…"
if command -v deno >/dev/null; then
  deno test --allow-env "$ROOT/supabase/functions/loja-verificar-compra/process_store_purchase_test.ts"
else
  echo "⚠️  deno não instalado — pulando testes locais"
fi

echo "→ supabase functions deploy loja-verificar-compra"
supabase functions deploy loja-verificar-compra

echo "✅ Deploy concluído."
echo "ℹ️  Confira secrets: APPLE_IAP_* e GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
echo "ℹ️  Guia: docs/store/PUBLICACAO_COMPRA_LOJAS.md"
