#!/usr/bin/env bash
# SoloForte — job periódico Mac: sync main + armar auto-merge em PRs cursor/*.
# Chamado por launchd (com.soloforte.sync-main).
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
SYNC="$REPO_ROOT/tool/sync_mac.sh"
ARM="$REPO_ROOT/tool/arm_auto_merge.sh"

"$SYNC" --quiet
"$ARM" --all --quiet
