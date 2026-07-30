#!/bin/bash
# Script de execução SoloForte — ambiente de desenvolvimento
# Use este script em vez de 'flutter run' puro.
# Equivalente a pressionar F5 no VS Code com "SoloForte — iOS (dev)".
#
# Credenciais: .env.local.json (preferido, igual ao TestFlight) → fallback .env.local
# Nunca commite arquivos .env* com segredos reais.
#
# ✅ Funciona SEM cabo (Wi-Fi) após o pareamento inicial já realizado.
#
# Uso:
#   ./run_dev.sh           → debug sem fio (hot reload ativo)
#   ./run_dev.sh --profile → profile sem fio (abre pelo ícone)
#   ./run_dev.sh --release → release

set -euo pipefail

# UUID do dispositivo CoreDevice (wireless) — iPhone 16 "Raudinei"
DEVICE_ID="00008140-00160D362151801C"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# shellcheck disable=SC1091
source "$SCRIPT_DIR/tool/load_local_env.sh"
soloforte_load_local_env "$SCRIPT_DIR"

flutter run \
  -d "$DEVICE_ID" \
  --dart-define=GOOGLE_WEATHER_API_KEY="$GOOGLE_WEATHER_API_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  --dart-define=STADIA_API_KEY="$STADIA_API_KEY" \
  --dart-define=MAPTILER_API_KEY="$MAPTILER_API_KEY" \
  --dart-define=ENV="$ENV" \
  "$@"
