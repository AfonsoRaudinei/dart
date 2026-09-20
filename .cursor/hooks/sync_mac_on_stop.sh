#!/usr/bin/env bash
# Cursor stop hook — sync Mac + armar auto-merge após cada turno (workspace local).
set -uo pipefail

cat >/dev/null

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SYNC="$REPO_ROOT/tool/sync_mac.sh"
ARM="$REPO_ROOT/tool/arm_auto_merge.sh"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/soloforte-sync.log"

mkdir -p "$LOG_DIR"

if [[ ! -x "$SYNC" ]]; then
  exit 0
fi

{
  echo "=== $(date -Iseconds) stop hook ==="
  "$SYNC" --quiet
  if [[ -x "$ARM" ]]; then
    "$ARM" --quiet || true
    "$ARM" --all --quiet &
  fi
} >>"$LOG_FILE" 2>&1 &

exit 0
