#!/bin/bash
# Script de execução SoloForte — ambiente de desenvolvimento
# Use este script em vez de 'flutter run' puro.
# Equivalente a pressionar F5 no VS Code com "SoloForte — iOS (dev)".
#
# ✅ Funciona SEM cabo (Wi-Fi) após o pareamento inicial já realizado.
#
# Uso:
#   ./run_dev.sh           → debug sem fio (hot reload ativo)
#   ./run_dev.sh --profile → profile sem fio (abre pelo ícone)
#   ./run_dev.sh --release → release

# UUID do dispositivo CoreDevice (wireless) — iPhone 16 "Raudinei"
DEVICE_ID="00008140-00160D362151801C"
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
MAPTILER_API_KEY="${MAPTILER_API_KEY:-}"
ENV="${ENV:-development}"

flutter run \
  -d "$DEVICE_ID" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=ENV="$ENV" \
  "$@"
