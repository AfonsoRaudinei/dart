#!/bin/bash
# Script de execução SoloForte — Web (Chrome)
# Use este script para rodar no navegador Google Chrome.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.local"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

GOOGLE_WEATHER_API_KEY="${GOOGLE_WEATHER_API_KEY:-}"
SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
STADIA_API_KEY="${STADIA_API_KEY:-}"
ENV="${ENV:-development}"

flutter run \
  -d chrome \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=ENV="$ENV" \
  --web-renderer html
