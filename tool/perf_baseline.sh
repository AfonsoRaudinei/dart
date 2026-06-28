#!/usr/bin/env bash
# =============================================================================
# tool/perf_baseline.sh — SoloForte Performance Baseline (Fase 0)
#
# Conta métricas de hot paths e compara com snapshot congelado em Fase 0.
# Modo WARNING-ONLY: Exit 0 sempre (não bloqueia CI); regressões são visíveis.
#
# Uso:
#   ./tool/perf_baseline.sh
#   ./tool/perf_baseline.sh --strict   # Exit 1 se métrica piorar vs baseline
# =============================================================================

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

STRICT=0
if [[ "${1:-}" == "--strict" ]]; then
  STRICT=1
fi

REGRESSIONS=0

pass() { echo -e "  ${GREEN}✅ OK${NC}    $1"; }
warn() { echo -e "  ${YELLOW}⚠️  WARN${NC}  $1"; REGRESSIONS=$((REGRESSIONS + 1)); }
info() { echo -e "  ${CYAN}ℹ️  INFO${NC}  $1"; }

count_in_file() {
  local pattern="$1"
  local file="$2"
  if [[ ! -f "$file" ]]; then
    echo "0"
    return
  fi
  rg -o "$pattern" "$file" 2>/dev/null | wc -l | tr -d ' '
}

check_metric() {
  local label="$1"
  local file="$2"
  local pattern="$3"
  local baseline="$4"
  local current
  current="$(count_in_file "$pattern" "$file")"

  if [[ "$current" -le "$baseline" ]]; then
    pass "$label: $current (baseline ≤ $baseline) — $file"
  else
    warn "$label: $current > baseline $baseline — $file"
  fi
}

check_lines() {
  local label="$1"
  local file="$2"
  local baseline="$3"
  local current
  if [[ ! -f "$file" ]]; then
    warn "$label: arquivo ausente — $file"
    return
  fi
  current="$(wc -l < "$file" | tr -d ' ')"
  if [[ "$current" -le "$baseline" ]]; then
    pass "$label: ${current} linhas (baseline ≤ $baseline)"
  else
    warn "$label: ${current} linhas > baseline $baseline — $file"
  fi
}

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SoloForte — Performance Baseline (Fase 0)${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "── ${CYAN}Hot paths — rebuild / notify${NC}"
echo ""

check_metric "ref.watch" \
  "lib/ui/screens/map/widgets/map_build_orchestrator.dart" \
  'ref\.watch\(' 9

check_metric "ref.watch" \
  "lib/ui/components/map/widgets/isolated_marker_layers.dart" \
  'ref\.watch\(' 12

check_metric "notifyListeners" \
  "lib/modules/drawing/presentation/controllers/drawing_controller.dart" \
  'notifyListeners\(' 44

check_metric "setState" \
  "lib/modules/drawing/presentation/widgets/drawing_sheet.dart" \
  'setState\(' 20

check_metric "setState" \
  "lib/ui/components/map/map_occurrence_sheet.dart" \
  'setState\(' 10

echo ""
echo -e "── ${CYAN}God files — tamanho (monitoramento)${NC}"
echo ""

check_lines "drawing_controller" \
  "lib/modules/drawing/presentation/controllers/drawing_controller.dart" 1697
check_lines "drawing_sheet" \
  "lib/modules/drawing/presentation/widgets/drawing_sheet.dart" 439
check_lines "database_helper" \
  "lib/core/database/database_helper.dart" 342
check_lines "map_occurrence_sheet" \
  "lib/ui/components/map/map_occurrence_sheet.dart" 659
check_lines "map_build_orchestrator" \
  "lib/ui/screens/map/widgets/map_build_orchestrator.dart" 639

echo ""
echo -e "── ${CYAN}Agregados lib/${NC}"
echo ""

TOTAL_WATCH="$(rg -o 'ref\.watch\(' lib/ 2>/dev/null | wc -l | tr -d ' ')"
TOTAL_SELECT="$(rg -o 'ref\.watch\([^)]+\.select\(' lib/ 2>/dev/null | wc -l | tr -d ' ')"
TOTAL_SETSTATE="$(rg -o 'setState\(' lib/ 2>/dev/null | wc -l | tr -d ' ')"
LIST_BUILDER="$(rg -o 'ListView\.builder|GridView\.builder' lib/ 2>/dev/null | wc -l | tr -d ' ')"

info "ref.watch total em lib/: $TOTAL_WATCH (baseline Fase 0: 360)"
info "ref.watch(...select...) em lib/: $TOTAL_SELECT (baseline Fase 0: 1)"
info ".select( total em lib/: $(rg -o '\.select\(' lib/ 2>/dev/null | wc -l | tr -d ' ') (baseline Fase 0: 48)"
info "setState total em lib/: $TOTAL_SETSTATE (baseline Fase 0: 310)"
info "ListView/GridView.builder em lib/: $LIST_BUILDER (baseline Fase 0: 11)"

STATENOTIFIER="$(rg -l 'extends StateNotifier' lib/ 2>/dev/null | wc -l | tr -d ' ')"
RIVERPOD_CODEGEN="$(rg -l '@Riverpod|@riverpod' lib/modules/agenda/presentation/providers/ 2>/dev/null | wc -l | tr -d ' ')"

info "StateNotifier classes em lib/: $STATENOTIFIER (baseline Fase 4: 5)"
info "@riverpod codegen em agenda/providers: $RIVERPOD_CODEGEN arquivos (baseline Fase 4: 2)"

if [[ "$STATENOTIFIER" -gt 5 ]]; then
  warn "StateNotifier total regressão: $STATENOTIFIER > 5"
fi

if [[ "$TOTAL_WATCH" -gt 360 ]]; then
  warn "ref.watch total regressão: $TOTAL_WATCH > 360"
fi
if [[ "$TOTAL_SETSTATE" -gt 310 ]]; then
  warn "setState total regressão: $TOTAL_SETSTATE > 310"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
if [[ "$REGRESSIONS" -eq 0 ]]; then
  echo -e "${GREEN}  ✅ Baseline de performance mantido ($REGRESSIONS regressões)${NC}"
else
  echo -e "${YELLOW}  ⚠️  $REGRESSIONS regressão(ões) vs baseline Fase 0 (modo warning)${NC}"
fi
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ "$STRICT" -eq 1 && "$REGRESSIONS" -gt 0 ]]; then
  exit 1
fi

exit 0
