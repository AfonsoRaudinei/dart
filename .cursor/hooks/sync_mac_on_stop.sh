#!/usr/bin/env bash
# Cursor stop hook — dispara sync Mac após cada turno do agente (workspace local).
set -uo pipefail

cat >/dev/null

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SYNC="$REPO_ROOT/tool/sync_mac.sh"
LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/soloforte-sync.log"

mkdir -p "$LOG_DIR"

if [[ ! -x "$SYNC" ]]; then
  exit 0
fi

{
  echo "=== $(date -Iseconds) stop hook ==="
  "$SYNC" --quiet
} >>"$LOG_FILE" 2>&1 &

exit 0
