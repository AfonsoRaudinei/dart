#!/usr/bin/env bash
# =============================================================================
# tool/test_clock_bomb_check.sh — Bombas-relógio em test/ (WARNING-ONLY)
#
# Detecta fixtures que dependem do calendário real e quebram o CI quando a data
# passa (ex.: publicoAte = liberado.add(days) sem reference, expiraEm fixo).
#
# Modo padrão: Exit 0 (só avisa). Não incrementa VIOLATIONS do arch_check.
# Allowlist: tool/test_clock_bomb_allowlist.txt (uma entrada por linha: path relativo)
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

WARNINGS=0
ALLOWLIST="$SCRIPT_DIR/test_clock_bomb_allowlist.txt"

is_allowlisted() {
  local file="$1"
  [ ! -f "$ALLOWLIST" ] && return 1
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    if [ "$file" = "$line" ] || [[ "$file" == *"$line"* ]]; then
      return 0
    fi
  done < "$ALLOWLIST"
  return 1
}

warn_hit() {
  local rule="$1"
  local detail="$2"
  echo -e "  ${YELLOW}⚠️  WARN${NC}  ${rule}: ${detail}"
  WARNINGS=$((WARNINGS + 1))
}

if ! command -v rg >/dev/null 2>&1; then
  echo -e "  ${YELLOW}⚠️  WARN${NC}  TEST-CLOCK: rg ausente — pulando checagem"
  exit 0
fi

# ── TEST-CLOCK-1 — expiraEm / expiresAt com ano fixo (sem DateTime.now) ───────
while IFS= read -r line; do
  file="${line%%:*}"
  rest="${line#*:}"
  is_allowlisted "$file" && continue
  if echo "$rest" | grep -q 'DateTime.now()'; then
    continue
  fi
  warn_hit "TEST-CLOCK-1" "$rest"
done < <(
  rg -n "expiraEm:\s*DateTime\.(utc\()?20(26|27)" test --glob '*.dart' 2>/dev/null || true
  rg -n "expiresAt:\s*DateTime\.(utc\()?20(26|27)" test --glob '*.dart' 2>/dev/null || true
)

# ── TEST-CLOCK-2 — visibilidade de case no mapa: janela .add(days) sem reference
while IFS= read -r file; do
  [ -z "$file" ] && continue
  is_allowlisted "$file" && continue
  if rg -q '\.add\(const Duration\(days:' "$file" && ! rg -q 'reference:' "$file"; then
    warn_hit "TEST-CLOCK-2" "$file usa add(days) em janela pública sem parâmetro reference:"
  fi
done < <(rg -l 'isVisibleOnMapFor' test --glob '*.dart' 2>/dev/null || true)

# ── TEST-CLOCK-3 — DateTime fixo 2026/2027 encadeado com .add( ───────────────
while IFS= read -r line; do
  file="${line%%:*}"
  is_allowlisted "$file" && continue
  warn_hit "TEST-CLOCK-3" "$line"
done < <(rg -n 'DateTime\.(utc\()?20(26|27),[^)]+\)\.add\(' test --glob '*.dart' 2>/dev/null || true)

if [ "$WARNINGS" -eq 0 ]; then
  echo -e "  ${CYAN}ℹ️  INFO${NC}  TEST-CLOCK: nenhum padrão de bomba-relógio detectado"
else
  echo -e "  ${CYAN}ℹ️  INFO${NC}  TEST-CLOCK: $WARNINGS aviso(s) — use reference: ou DateTime.now().add(...)"
  echo "              Allowlist: tool/test_clock_bomb_allowlist.txt"
fi

exit 0