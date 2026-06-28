#!/usr/bin/env bash
# =============================================================================
# tool/test_matrix_gate.sh — Matriz de testes por setor (Fase 5)
#
# Valida:
#   - Presença mínima de arquivos *_test.dart nos setores P0/P1
#   - Coverage por módulo crítico (via lcov) vs baseline congelado
#
# Uso:
#   flutter test --coverage
#   ./tool/test_matrix_gate.sh
#   STRICT=1 ./tool/test_matrix_gate.sh   # falha CI em regressão
# =============================================================================

set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
STRICT="${STRICT:-0}"
REGRESSIONS=0

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}✅ PASS${NC}  $1"; }
warn() { echo -e "  ${YELLOW}⚠️  WARN${NC}  $1"; REGRESSIONS=$((REGRESSIONS + 1)); }
info() { echo -e "  ${CYAN}ℹ️  INFO${NC}  $1"; }

count_tests() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    echo 0
    return
  fi
  find "$dir" -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' '
}

module_coverage_pct() {
  local module="$1"
  python3 - "$LCOV_FILE" "$module" << 'PY'
import sys
from collections import defaultdict
from pathlib import Path

lcov_path = Path(sys.argv[1])
module = sys.argv[2]
prefix = f"lib/modules/{module}/"

groups = defaultdict(lambda: [0, 0])
current = None
lf = lh = 0

for raw in lcov_path.read_text(encoding="utf-8", errors="replace").splitlines():
    line = raw.strip()
    if line.startswith("SF:"):
        if current is not None and current.startswith(prefix):
            groups[module][0] += lf
            groups[module][1] += lh
        current = line[3:].replace("\\", "/")
        lf = lh = 0
    elif line == "end_of_record":
        if current is not None and current.startswith(prefix):
            groups[module][0] += lf
            groups[module][1] += lh
        current = None
        lf = lh = 0
    elif line.startswith("LF:"):
        lf = int(line[3:])
    elif line.startswith("LH:"):
        lh = int(line[3:])

total, hit = groups.get(module, (0, 0))
if total == 0:
    print("-1")
else:
    print(f"{hit / total * 100:.1f}")
PY
}

check_min_tests() {
  local label="$1"
  local dir="$2"
  local min="$3"
  local count
  count="$(count_tests "$dir")"
  if [[ "$count" -ge "$min" ]]; then
    pass "$label: $count arquivo(s) *_test.dart (mínimo $min)"
  else
    warn "$label: $count arquivo(s) *_test.dart < mínimo $min"
  fi
}

check_module_floor() {
  local module="$1"
  local floor="$2"
  local pct
  pct="$(module_coverage_pct "$module")"
  if [[ "$pct" == "-1" ]]; then
    warn "modules/$module: sem linhas instrumentáveis no lcov"
    return
  fi
  if awk -v pct="$pct" -v floor="$floor" 'BEGIN { exit (pct + 0 >= floor + 0 ? 0 : 1) }'; then
    pass "modules/$module coverage ${pct}% (piso ${floor}%)"
  else
    warn "modules/$module coverage ${pct}% < piso ${floor}%"
  fi
}

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SoloForte — Matriz de Testes Fase 5${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ ! -f "$LCOV_FILE" ]]; then
  echo "Arquivo lcov não encontrado: $LCOV_FILE" >&2
  echo "Execute: flutter test --coverage" >&2
  exit 1
fi

echo -e "── ${CYAN}Presença de testes por setor${NC}"
echo ""
check_min_tests "P0 consultoria" "test/modules/consultoria" 15
check_min_tests "P0 marketing" "test/modules/marketing" 2
check_min_tests "P0 carteira" "test/modules/carteira" 3
check_min_tests "P1 public" "test/modules/public" 1

echo ""
echo -e "── ${CYAN}Coverage por setor crítico (piso Fase 5)${NC}"
echo ""
check_module_floor "consultoria" 35
check_module_floor "marketing" 25
check_module_floor "carteira" 70
check_module_floor "public" 15

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
if [[ "$REGRESSIONS" -eq 0 ]]; then
  echo -e "${GREEN}  ✅ Matriz de testes Fase 5 conforme ($REGRESSIONS regressões)${NC}"
else
  echo -e "${YELLOW}  ⚠️  $REGRESSIONS regressão(ões) vs baseline Fase 5${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$STRICT" -eq 1 && "$REGRESSIONS" -gt 0 ]]; then
  exit 1
fi

exit 0
