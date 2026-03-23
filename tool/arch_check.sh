#!/usr/bin/env bash
# =============================================================================
# tool/arch_check.sh — SoloForte Architectural Enforcement
#
# Valida as fronteiras arquiteturais do projeto SoloForte.
# Deve ser executado via CI em cada Pull Request.
#
# Exit 0 → arquitetura conforme
# Exit 1 → violação detectada (PR deve ser bloqueado)
#
# Regras implementadas:
#   REGRA 1 — core/ não pode importar modules/
#   REGRA 2 — Acoplamentos laterais proibidos entre módulos
#   REGRA 3 — Arquivos novos não podem ultrapassar 900 linhas
# =============================================================================

set -uo pipefail

# ── Cores ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Contadores ────────────────────────────────────────────────────────────────
VIOLATIONS=0

# ── Funções de log ────────────────────────────────────────────────────────────
pass() { echo -e "  ${GREEN}✅ PASS${NC}  $1"; }
fail() { echo -e "  ${RED}❌ FAIL${NC}  $1"; VIOLATIONS=$((VIOLATIONS + 1)); }
warn() { echo -e "  ${YELLOW}⚠️  WARN${NC}  $1"; }
info() { echo -e "  ${CYAN}ℹ️  INFO${NC}  $1"; }

# ── Header ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  SoloForte — Enforcement Arquitetural Automático${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

# =============================================================================
# REGRA 1 — core/ não pode importar modules/
#
# Fundamento: core/ é camada de infraestrutura pura.
#             Conhecer módulos de negócio cria acoplamento descendente.
#
# Exceção autorizada (ADR-008):
#   lib/core/router/app_router.dart → ponto de composição oficial de rotas.
#   É o único arquivo de core/ autorizado a conhecer módulos.
# =============================================================================
echo -e "── ${CYAN}REGRA 1${NC}: core/ não pode importar modules/ ─────────────────────"
echo ""

CORE_VIOLATIONS=$(grep -rn "import.*['\"].*modules/" lib/core/ --include="*.dart" \
  | grep -v "lib/core/router/app_router\.dart" \
  | grep -v "^\s*//" \
  || true)

if [ -n "$CORE_VIOLATIONS" ]; then
  fail "core/ contém import ilegal de modules/:"
  echo ""
  echo "$CORE_VIOLATIONS" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "core/ está isento de imports de modules/"
  info "Exceção autorizada: core/router/app_router.dart (composição de rotas)"
fi

echo ""

# =============================================================================
# REGRA 2 — Acoplamentos laterais proibidos entre módulos
#
# Fundamento: módulos de negócio no mesmo nível não devem se conhecer
#             diretamente, pois cria acoplamento difícil de rastrear
#             e impede evolução independente.
#
# Regras ativas:
#   drawing  → consultoria : PROIBIDO
#   agenda   → consultoria : PROIBIDO
#   consultoria → drawing  : PROIBIDO
#
# Relações permitidas (não bloqueadas por este script):
#   operacao → consultoria  : PERMITIDO (execução usa dados agronômicos)
#   consultoria → consultoria: PERMITIDO (submódulos do mesmo domínio)
#   agenda   → agenda       : PERMITIDO
# =============================================================================
echo -e "── ${CYAN}REGRA 2${NC}: acoplamentos laterais proibidos ──────────────────────"
echo ""

# Função auxiliar para verificar acoplamento lateral
check_lateral() {
  local FROM_DIR="$1"
  local TO_PATTERN="$2"
  local LABEL="$3"

  if [ ! -d "$FROM_DIR" ]; then
    info "$LABEL — diretório origem não existe (sem violação)"
    return
  fi

  local RESULT
  RESULT=$(grep -rn "import.*['\"].*${TO_PATTERN}" "$FROM_DIR" --include="*.dart" \
    | grep -v "^\s*//" \
    || true)

  if [ -n "$RESULT" ]; then
    fail "$LABEL:"
    echo ""
    echo "$RESULT" | while IFS= read -r line; do
      echo -e "      ${RED}→${NC} $line"
    done
    echo ""
  else
    pass "$LABEL"
  fi
}

# Função auxiliar para verificar acoplamento lateral via imports relativos.
check_lateral_relative() {
  local FROM_DIR="$1"
  local TO_SEGMENT="$2"
  local LABEL="$3"

  if [ ! -d "$FROM_DIR" ]; then
    info "$LABEL — diretório origem não existe (sem violação)"
    return
  fi

  local RESULT
  RESULT=$(grep -rnE "import.*['\"][^'\"]*\\.\\./[^'\"]*${TO_SEGMENT}/" "$FROM_DIR" --include="*.dart" \
    | grep -v "^\s*//" \
    || true)

  if [ -n "$RESULT" ]; then
    fail "$LABEL:"
    echo ""
    echo "$RESULT" | while IFS= read -r line; do
      echo -e "      ${RED}→${NC} $line"
    done
    echo ""
  else
    pass "$LABEL"
  fi
}

check_lateral \
  "lib/modules/drawing/" \
  "modules/consultoria/" \
  "drawing/ não importa consultoria/"

check_lateral_relative \
  "lib/modules/drawing/" \
  "consultoria" \
  "drawing/ não importa consultoria/ via caminho relativo"

check_lateral \
  "lib/modules/agenda/" \
  "modules/consultoria/" \
  "agenda/ não importa consultoria/"

check_lateral_relative \
  "lib/modules/agenda/" \
  "consultoria" \
  "agenda/ não importa consultoria/ via caminho relativo"

check_lateral \
  "lib/modules/consultoria/" \
  "modules/drawing/" \
  "consultoria/ não importa drawing/"

check_lateral_relative \
  "lib/modules/consultoria/" \
  "drawing" \
  "consultoria/ não importa drawing/ via caminho relativo"

# =============================================================================
# REGRA 2 (ADR-009) — consultoria/ não pode importar diretamente de operacao/
#
# Fundamento: consultoria consome dados de VisitSession exclusivamente via
#             VisitSessionSnapshot (DTO próprio de consultoria/relatorios/models/).
#             Importação direta criaria ciclo com operacao → consultoria.
# =============================================================================
check_lateral \
  "lib/modules/consultoria/" \
  "modules/operacao/" \
  "consultoria/ não importa operacao/ (usa VisitSessionSnapshot — ADR-009)"

check_lateral \
  "lib/modules/consultoria/" \
  "modules/visitas/" \
  "consultoria/ não importa visitas/ (usa contratos em core/contracts — ADR-020)"

check_lateral \
  "lib/modules/visitas/" \
  "modules/consultoria/" \
  "visitas/ não importa consultoria/ (usa contratos em core/contracts — ADR-020)"

check_lateral \
  "lib/modules/marketing/" \
  "\(modules/consultoria/\|modules/operacao/\|modules/agenda/\|modules/drawing/\)" \
  "marketing/ não importa módulos core de negócio (consultoria, operacao, agenda, drawing)"

echo ""

# =============================================================================
# REGRA 3 — Arquivos novos não podem ultrapassar 900 linhas
#
# Fundamento: arquivos > 900 linhas indicam God Objects que violam SRP.
#             O crescimento silencioso é o maior risco estrutural a longo prazo.
#
# Exceções legadas (arquivos que já excedem o limite na baseline v1.1):
#   Estes arquivos existiam antes do enforcement e têm decomposição planejada.
#   Qualquer arquivo NÃO listado aqui que ultrapassar 900 linhas é BLOQUEANTE.
# =============================================================================
echo -e "── ${CYAN}REGRA 3${NC}: arquivos novos não podem ultrapassar 900 linhas ──────"
echo ""

# Exceções legadas — arquivos da baseline que excedem 900 linhas.
# Remover desta lista quando o arquivo for decomposto.
LEGACY_EXCEPTIONS=(
  "modules/drawing/presentation/controllers/drawing_controller.dart"  # 1344 — decomposição planejada
  "modules/drawing/presentation/widgets/drawing_sheet.dart"            # 1177 — decomposição planejada
  "ui/components/map/map_occurrence_sheet.dart"                        # 1064 — decomposição planejada
  "modules/drawing/domain/drawing_utils.dart"                          # 1010 — utilitário puro, candidato a split
  "core/database/database_helper.dart"                                 # 1128 — legado pré-baseline v1.1, decomposição planejada
)

SIZE_VIOLATIONS=0
SIZE_WARNINGS=0

while IFS= read -r dart_file; do
  line_count=$(wc -l < "$dart_file" | tr -d ' ')

  if [ "$line_count" -gt 900 ]; then
    is_exception=false

    for exception in "${LEGACY_EXCEPTIONS[@]}"; do
      if [[ "$dart_file" == *"$exception"* ]]; then
        is_exception=true
        warn "$(printf '%4d linhas' "$line_count")  [exceção legada]  $dart_file"
        SIZE_WARNINGS=$((SIZE_WARNINGS + 1))
        break
      fi
    done

    if [ "$is_exception" = false ]; then
      echo -e "  ${RED}❌ FAIL${NC}  $(printf '%4d linhas' "$line_count")  [NOVO violador]   $dart_file"
      SIZE_VIOLATIONS=$((SIZE_VIOLATIONS + 1))
    fi
  fi
done < <(find lib/ -name "*.dart" | sort)

VIOLATIONS=$((VIOLATIONS + SIZE_VIOLATIONS))

if [ "$SIZE_VIOLATIONS" -eq 0 ]; then
  pass "Nenhum arquivo novo ultrapassa 900 linhas"
  if [ "$SIZE_WARNINGS" -gt 0 ]; then
    info "$SIZE_WARNINGS exceção(ões) legada(s) monitorada(s) — remover quando decompostas"
  fi
fi

echo ""

# =============================================================================
# RESULTADO FINAL
# =============================================================================
echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"

if [ "$VIOLATIONS" -gt 0 ]; then
  echo -e "${RED}  ❌ REPROVADO — ${VIOLATIONS} violação(ões) detectada(s)${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "  Corrija as violações acima antes de mergear este PR."
  echo "  Dúvidas: consulte docs/AUDITORIA_ARQUITETURAL_COMPLETA_V1_1.md"
  echo ""
  exit 1
else
  echo -e "${GREEN}  ✅ APROVADO — Arquitetura conforme${NC}"
  echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
  echo ""
  exit 0
fi
