#!/bin/bash
# Script de execução SoloForte — macOS (Desktop Dev)
# Use este script para rodar no seu MacBook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env.local"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"
MAPTILER_API_KEY="${MAPTILER_API_KEY:-}"
GOOGLE_WEATHER_API_KEY="${GOOGLE_WEATHER_API_KEY:-}"
STADIA_API_KEY="${STADIA_API_KEY:-}"

flutter run \
  -d macos \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=ENV=development
