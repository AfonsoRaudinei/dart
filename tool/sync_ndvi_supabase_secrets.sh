#!/usr/bin/env bash
# Sincroniza secrets NDVI/Planet do .env.local.json para o projeto Supabase linkado.
# Requer: supabase CLI logado + projeto linkado (supabase link).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=tool/load_local_env.sh
source "$ROOT/tool/load_local_env.sh"
soloforte_load_local_env "$ROOT"

if ! command -v supabase >/dev/null; then
  echo "❌ supabase CLI não encontrado."
  exit 1
fi

ARGS=()
[ -n "${PLANET_API_KEY:-}" ] && ARGS+=(PLANET_API_KEY="$PLANET_API_KEY")
[ -n "${PLANET_API_SECRET:-}" ] && ARGS+=(PLANET_API_SECRET="$PLANET_API_SECRET")
[ -n "${SENTINEL_HUB_CLIENT_ID:-}" ] && ARGS+=(SENTINEL_HUB_CLIENT_ID="$SENTINEL_HUB_CLIENT_ID")
[ -n "${SENTINEL_HUB_CLIENT_SECRET:-}" ] && ARGS+=(SENTINEL_HUB_CLIENT_SECRET="$SENTINEL_HUB_CLIENT_SECRET")
[ -n "${SENTINEL_API_USER_ID:-}" ] && ARGS+=(SENTINEL_API_USER_ID="$SENTINEL_API_USER_ID")
[ -n "${SENTINEL_API_TOKEN:-}" ] && ARGS+=(SENTINEL_API_TOKEN="$SENTINEL_API_TOKEN")
[ -n "${SENTINEL_HUB_TOKEN:-}" ] && ARGS+=(SENTINEL_HUB_TOKEN="$SENTINEL_HUB_TOKEN")

if [ "${#ARGS[@]}" -eq 0 ]; then
  echo "❌ Nenhum secret NDVI/Planet em .env.local.json"
  exit 1
fi

echo "→ supabase secrets set (${#ARGS[@]} chaves)…"
supabase secrets set "${ARGS[@]}"
echo "→ supabase functions deploy ndvi-fetch"
supabase functions deploy ndvi-fetch
echo "✅ Secrets + deploy concluídos."
