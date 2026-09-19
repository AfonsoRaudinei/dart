#!/usr/bin/env bash
# SoloForte — Fase 2: sync Cursor Desktop Mac após entrega cloud (REGRA-ENTREGA-1).
# Uso: ./tool/sync_mac.sh [--quiet]
set -euo pipefail

QUIET=0
if [[ "${1:-}" == "--quiet" ]]; then
  QUIET=1
fi

log() {
  if [[ "$QUIET" -eq 0 ]]; then
    echo "$@"
  fi
}

cd "$(git rev-parse --show-toplevel)"

git fetch origin
git checkout main >/dev/null 2>&1 || git checkout main

LOCAL_SHA="$(git rev-parse HEAD)"
REMOTE_SHA="$(git rev-parse origin/main)"

if [[ "$LOCAL_SHA" == "$REMOTE_SHA" ]]; then
  log "main já sincronizada: $LOCAL_SHA"
  exit 0
fi

log "Atualizando main: $LOCAL_SHA -> $REMOTE_SHA"
git pull origin main
flutter pub get
git log -1 --oneline
