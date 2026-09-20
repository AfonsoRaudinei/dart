#!/usr/bin/env bash
# SoloForte — job periódico Mac (Fase 2): sync main apenas.
# Chamado por launchd (com.soloforte.sync-main). Não arma auto-merge.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SYNC="$REPO_ROOT/tool/sync_mac.sh"

"$SYNC" --quiet
