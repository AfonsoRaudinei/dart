#!/usr/bin/env bash
set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
COVERAGE_MIN="${COVERAGE_MIN:-36.46}"
COVERAGE_TARGET="${COVERAGE_TARGET:-60}"

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Coverage file not found: $LCOV_FILE" >&2
  exit 1
fi

summary="$(
  awk -F: '
    /^LF:/ { total += $2 }
    /^LH:/ { hit += $2 }
    END {
      if (total == 0) {
        print "0 0 0.00"
        exit 2
      }
      printf "%d %d %.2f\n", hit, total, (hit / total) * 100
    }
  ' "$LCOV_FILE"
)"

read -r hit total rate <<< "$summary"

echo "Coverage de linhas: ${rate}% (${hit}/${total})"
echo "Baseline minimo: ${COVERAGE_MIN}%"
echo "Alvo de qualidade: ${COVERAGE_TARGET}%"

awk -v rate="$rate" -v min="$COVERAGE_MIN" 'BEGIN { exit(rate + 0 >= min + 0 ? 0 : 1) }' || {
  echo "Coverage abaixo do baseline minimo." >&2
  exit 1
}

awk -v rate="$rate" -v target="$COVERAGE_TARGET" 'BEGIN { exit(rate + 0 >= target + 0 ? 0 : 1) }' || {
  echo "Coverage ainda abaixo do alvo de qualidade; gate incremental aprovado sem regressao."
  exit 0
}

echo "Coverage atingiu o alvo de qualidade."
