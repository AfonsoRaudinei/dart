#!/usr/bin/env bash
# Instala sync automático da main no Mac (launchd, a cada 5 min).
# Uso: ./tool/install_mac_sync_launchd.sh
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SYNC_SCRIPT="$REPO_ROOT/tool/sync_mac.sh"
PERIODIC_SCRIPT="$REPO_ROOT/tool/mac_periodic.sh"
ARM_SCRIPT="$REPO_ROOT/tool/arm_auto_merge.sh"
PLIST_TEMPLATE="$REPO_ROOT/tool/com.soloforte.sync-main.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.soloforte.sync-main.plist"
LOG_FILE="$HOME/Library/Logs/soloforte-sync.log"
ERR_LOG_FILE="$HOME/Library/Logs/soloforte-sync.err.log"

chmod +x "$SYNC_SCRIPT" "$PERIODIC_SCRIPT" "$ARM_SCRIPT"
chmod +x "$REPO_ROOT/.cursor/hooks/sync_mac_on_stop.sh" 2>/dev/null || true

mkdir -p "$HOME/Library/Logs" "$HOME/Library/LaunchAgents"

sed \
  -e "s|__PERIODIC_SCRIPT__|$PERIODIC_SCRIPT|g" \
  -e "s|__REPO_ROOT__|$REPO_ROOT|g" \
  -e "s|__LOG_FILE__|$LOG_FILE|g" \
  -e "s|__ERR_LOG_FILE__|$ERR_LOG_FILE|g" \
  "$PLIST_TEMPLATE" >"$PLIST_DEST"

launchctl bootout "gui/$(id -u)/com.soloforte.sync-main" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"
launchctl enable "gui/$(id -u)/com.soloforte.sync-main" 2>/dev/null || true

echo "OK: com.soloforte.sync-main instalado"
echo "  plist: $PLIST_DEST"
echo "  log:   $LOG_FILE"
echo "  sync:  a cada 5 min + RunAtLoad (sync_mac apenas — Fase 2)"
echo "  hook:  .cursor/hooks/sync_mac_on_stop.sh (sync + arm_auto_merge da branch corrente cursor/* → main)"

"$PERIODIC_SCRIPT" || true
tail -n 5 "$LOG_FILE" 2>/dev/null || true
