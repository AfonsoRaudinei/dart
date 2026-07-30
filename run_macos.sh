#!/bin/bash
# Script de execução SoloForte — macOS (Desktop Dev)
# Use este script para rodar no seu MacBook.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/tool/load_local_env.sh"
soloforte_load_local_env "$SCRIPT_DIR"

flutter run \
  -d macos \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=ENV="$ENV"
