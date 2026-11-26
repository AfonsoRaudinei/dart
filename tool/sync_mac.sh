#!/usr/bin/env bash
# SoloForte — Fase 2: sync Cursor Desktop Mac após entrega cloud (REGRA-ENTREGA-1).
# Uso: ./tool/sync_mac.sh [--quiet]
#
# Na main (ou detached HEAD): checkout main + pull + flutter pub get (se mudou).
# Fora da main (ex.: cursor/*): NÃO troca de branch nem toca no working tree;
# só avança o ref local `main` (fast-forward) a partir de origin/main.
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

CURRENT_BRANCH="$(git branch --show-current)"

if [[ -n "$CURRENT_BRANCH" && "$CURRENT_BRANCH" != "main" ]]; then
  log "Branch atual '$CURRENT_BRANCH' != main: sem checkout, working tree intacto."
  FF_ERR=""
  if FF_ERR="$(git fetch origin main:main 2>&1)"; then
    log "Ref local main atualizado (fast-forward) para $(git rev-parse main)."
  else
    echo "AVISO sync_mac: não foi possível avançar o ref local main sem forçar" \
      "(main local divergiu de origin/main ou está em uso por outro worktree)." \
      "Nada foi alterado. Detalhe: $FF_ERR" >&2
  fi
  log "flutter pub get ignorado (working tree não mudou)."
  exit 0
fi

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
