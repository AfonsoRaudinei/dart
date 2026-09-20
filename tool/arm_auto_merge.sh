#!/usr/bin/env bash
# SoloForte — arma gh pr merge --auto --rebase no PR da branch cursor/* (base main).
# Uso: ./tool/arm_auto_merge.sh [--quiet] [branch]
# --all: só uso manual explícito no terminal (nunca hook/launchd).
# Exit 0 em skips (launchd/hook). Nunca usa --admin.
set -uo pipefail

QUIET=0
ALL=0
BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet)
      QUIET=1
      shift
      ;;
    --all)
      ALL=1
      shift
      ;;
    -*)
      if [[ "$QUIET" -eq 0 ]]; then
        echo "arm_auto_merge: opção desconhecida: $1" >&2
      fi
      exit 0
      ;;
    *)
      BRANCH="$1"
      shift
      ;;
  esac
done

log() {
  if [[ "$QUIET" -eq 0 ]]; then
    echo "$@"
  fi
}

cd "$(git rev-parse --show-toplevel)" 2>/dev/null || exit 0

if ! command -v gh >/dev/null 2>&1; then
  log "arm_auto_merge: gh não encontrado — skip"
  exit 0
fi

arm_pr() {
  local pr_number="$1"
  local head_ref="$2"

  if gh pr merge "$pr_number" --auto --rebase 2>/dev/null; then
    log "arm_auto_merge: auto-merge armado em PR #$pr_number ($head_ref)"
    return 0
  fi

  log "arm_auto_merge: falha ao armar PR #$pr_number ($head_ref) — skip"
  return 0
}

process_branch() {
  local branch="$1"

  if [[ -z "$branch" || "$branch" == "main" ]]; then
    log "arm_auto_merge: skip branch '$branch'"
    return 0
  fi

  if [[ "$branch" != cursor/* ]]; then
    log "arm_auto_merge: skip '$branch' (não é cursor/*)"
    return 0
  fi

  local pr_number is_draft auto_merge state head_ref base_ref
  pr_number="$(gh pr list --head "$branch" --state open --json number -q '.[0].number' 2>/dev/null || true)"

  if [[ -z "$pr_number" || "$pr_number" == "null" ]]; then
    log "arm_auto_merge: sem PR aberto para '$branch'"
    return 0
  fi

  is_draft="$(gh pr view "$pr_number" --json isDraft -q '.isDraft' 2>/dev/null || true)"
  auto_merge="$(gh pr view "$pr_number" --json autoMergeRequest -q '.autoMergeRequest' 2>/dev/null || true)"
  state="$(gh pr view "$pr_number" --json state -q '.state' 2>/dev/null || true)"
  head_ref="$(gh pr view "$pr_number" --json headRefName -q '.headRefName' 2>/dev/null || true)"
  base_ref="$(gh pr view "$pr_number" --json baseRefName -q '.baseRefName' 2>/dev/null || true)"

  if [[ "$state" == "MERGED" || "$state" == "CLOSED" ]]; then
    log "arm_auto_merge: skip PR #$pr_number ($branch) — $state"
    return 0
  fi

  if [[ "$base_ref" != "main" ]]; then
    log "arm_auto_merge: skip PR #$pr_number ($branch) — base não é main ($base_ref)"
    return 0
  fi

  if [[ "$is_draft" == "true" ]]; then
    log "arm_auto_merge: skip PR #$pr_number ($branch) — draft"
    return 0
  fi

  if [[ -n "$auto_merge" && "$auto_merge" != "null" ]]; then
    log "arm_auto_merge: skip PR #$pr_number ($branch) — auto-merge já armado"
    return 0
  fi

  arm_pr "$pr_number" "${head_ref:-$branch}"
}

if [[ "$ALL" -eq 1 ]]; then
  pr_list="$(gh pr list --state open \
    --json number,headRefName,isDraft,autoMergeRequest,baseRefName \
    -q '.[] | select(.headRefName | startswith("cursor/")) | select(.baseRefName == "main") | select(.isDraft == false) | select(.autoMergeRequest == null) | "\(.number) \(.headRefName)"' \
    2>/dev/null || true)"

  if [[ -z "$pr_list" ]]; then
    log "arm_auto_merge: --all — nenhum PR cursor/* → main pendente de auto-merge"
    exit 0
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    pr_number="${line%% *}"
    head_ref="${line#* }"
    arm_pr "$pr_number" "$head_ref"
  done <<<"$pr_list"

  exit 0
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH="$(git branch --show-current 2>/dev/null || true)"
fi

process_branch "$BRANCH"
exit 0
