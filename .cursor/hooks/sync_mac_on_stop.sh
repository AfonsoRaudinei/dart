#!/usr/bin/env bash
# Cursor stop hook — sync Mac + armar auto-merge da branch corrente (workspace local).
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

BRANCH="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"

{
  echo "=== $(date -Iseconds) stop hook ==="
  "$SYNC" --quiet
  if [[ -x "$ARM" && -n "$BRANCH" && "$BRANCH" != "main" && "$BRANCH" == cursor/* ]]; then
    "$ARM" --quiet "$BRANCH" || true
  fi
} >>"$LOG_FILE" 2>&1 &

exit 0
