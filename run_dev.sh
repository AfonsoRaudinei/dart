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

flutter run \
  -d "$DEVICE_ID" \
  --dart-define=SUPABASE_URL=https://pyoejhhkjlrjijiviryq.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB5b2VqaGhramxyamlqaXZpcnlxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTI1MDQsImV4cCI6MjA2OTcyODUwNH0.2P5wKq7b6viMa9kutLOZADsqAvSZx6X8fbLZMlooG1U \
  --dart-define=ENV=development \
  "$@"
