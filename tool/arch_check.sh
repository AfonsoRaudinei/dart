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
#   REGRA-NDVI — Invariants ADR-042 (lookup chain, fronteira, testes)
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
  "\(modules/consultoria/\|modules/agenda/\|modules/drawing/\)" \
  "marketing/ não importa módulos core de negócio (consultoria, agenda, drawing)"

check_lateral \
  "lib/modules/produtor/" \
  "\(modules/consultoria/\|modules/drawing/\|modules/agenda/\|modules/visitas/\)" \
  "produtor/ não importa outros módulos de domínio (ADR-040)"

check_lateral \
  "lib/modules/consultoria/" \
  "modules/produtor/" \
  "consultoria/ não importa produtor/ (ADR-039/040)"

check_lateral \
  "lib/modules/ndvi/" \
  "modules/consultoria/" \
  "ndvi/ não importa consultoria/ (ADR-042 — usar IFieldLookup)"

check_lateral \
  "lib/modules/ndvi/" \
  "modules/drawing/" \
  "ndvi/ não importa drawing/ (ADR-042 — usar IFieldLookup)"

# =============================================================================
# REGRA 2 (ADR-023) — visitas/ não pode importar consultoria/ nem drawing/
#
# Fundamento: visitas/ é bounded context isolado. Acesso a dados externos
#             deve ocorrer exclusivamente via contratos em core/contracts/.
#
# EXCEÇÕES AUTORIZADAS: nenhuma — DT-023-3 e DT-023-4 resolvidas em ADR-024 PROMPT 06.
# =============================================================================

# ── REGRA-VISITAS-1: visitas/ não importa consultoria/ ────────────────────────
REGRA_VISITAS_1=$(grep -rn "import.*modules/consultoria" \
  lib/modules/visitas/ --include="*.dart" \
  | grep -v "^\s*//" \
  || true)

if [ -n "$REGRA_VISITAS_1" ]; then
  fail "REGRA-VISITAS-1: visitas/ importa consultoria/ diretamente (ADR-023):"
  echo ""
  echo "$REGRA_VISITAS_1" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "visitas/ não importa consultoria/ (ADR-023 — DT-023-3 e DT-023-4 resolvidas)"
fi

# ── REGRA-VISITAS-2: visitas/ não importa drawing/ ────────────────────────────
REGRA_VISITAS_2=$(grep -rn "import.*modules/drawing" \
  lib/modules/visitas/ --include="*.dart" \
  | grep -v "^\s*//" \
  || true)

if [ -n "$REGRA_VISITAS_2" ]; then
  fail "REGRA-VISITAS-2: visitas/ importa drawing/ diretamente (ADR-023):"
  echo ""
  echo "$REGRA_VISITAS_2" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "visitas/ não importa drawing/ (ADR-023)"
fi

# ── REGRA-VISITAS-3: visitas/ não importa presentation layer de agenda/ ───────
REGRA_VISITAS_3=$(grep -rn "import.*modules/agenda.*presentation" \
  lib/modules/visitas/ --include="*.dart" \
  | grep -v "^\s*//" \
  || true)

if [ -n "$REGRA_VISITAS_3" ]; then
  fail "REGRA-VISITAS-3: visitas/ importa presentation de agenda/ diretamente (ADR-023):"
  echo ""
  echo "$REGRA_VISITAS_3" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "visitas/ não importa presentation de agenda/ (ADR-023 — DT-023-3 resolvida)"
fi

echo ""

# =============================================================================
# REGRA-MAP-1 (ADR-025) — ninguém importa modules/map/ externamente
# map/ é agregador — pode depender de tudo, ninguém depende dele
# EXCEÇÕES AUTORIZADAS:
#   - lib/core/router/app_router.dart (composição de rotas)
#   - lib/main.dart (bootstrap visit_completion_observer — ADR-010)
#   - lib/ui/components/map/ (camada de apresentação do mapa — DT-025-4)
#   - lib/ui/screens/ (camada de apresentação do mapa — DT-025-4)
# Quando Fase 3 (consolidação) for executada, remover as 4 exceções.
# =============================================================================
echo -e "── ${CYAN}REGRA-MAP-1${NC}: nenhum módulo externo importa map/ (ADR-025) ─────"
echo ""

MAP_IMPORTS_EXTERNOS=$(grep -rn "import.*modules/map" lib/ \
  --include="*.dart" \
  | grep -v "lib/modules/map/" \
  | grep -v "lib/core/router/app_router" \
  | grep -v "lib/main\.dart" \
  | grep -v "lib/ui/components/map/" \
  | grep -v "lib/ui/screens/" \
  | grep -v "^\s*//" \
  | wc -l | tr -d ' ')

if [ "$MAP_IMPORTS_EXTERNOS" -gt "0" ]; then
  fail "REGRA-MAP-1: módulo externo importa map/ diretamente (ADR-025):"
  echo ""
  grep -rn "import.*modules/map" lib/ --include="*.dart" \
    | grep -v "lib/modules/map/" \
    | grep -v "lib/core/router/app_router" \
    | grep -v "lib/main\.dart" \
    | grep -v "lib/ui/components/map/" \
    | grep -v "lib/ui/screens/" \
    | grep -v "^\s*//"
  echo ""
else
  pass "nenhum módulo externo importa map/ (ADR-025 — DT-025-4 pending Fase 3)"
fi

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
  "ui/screens/private_map_screen.dart"                                 # 900+ — DT-025-5: God Object com comentário de governança ADR-025
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
# REGRA-SHEET-1 — showModalBottomSheet direto é proibido (ADR-027)
# =============================================================================
echo -e "── ${CYAN}REGRA-SHEET-1${NC}: showModalBottomSheet direto proibido ─────────"
echo ""

DIRECT_MODAL=$(grep -rn "showModalBottomSheet" lib/ \
  --include="*.dart" \
  | grep -v "lib/core/ui/sheets/soloforte_sheet.dart" \
  | grep -v "^\s*//" \
  | wc -l | tr -d ' ')

if [ "$DIRECT_MODAL" -gt "0" ]; then
  fail "REGRA-SHEET-1: showModalBottomSheet direto detectado."
  echo "   Use showSoloForteSheet() de lib/core/ui/sheets/soloforte_sheet.dart"
  grep -rn "showModalBottomSheet" lib/ --include="*.dart" \
    | grep -v "lib/core/ui/sheets/soloforte_sheet.dart" \
    | grep -v "^\s*//" | while IFS= read -r line; do
      echo -e "      ${RED}→${NC} $line"
    done
  echo ""
else
  pass "Nenhum showModalBottomSheet direto detectado (ADR-027)"
fi

echo ""

# =============================================================================
# REGRA-CROSS-MODULE-2 — Acoplamentos laterais entre bounded contexts
#
# Modo v1.1: WARNING-ONLY. A regra reporta dependencias diretas conhecidas,
# mas nao incrementa VIOLATIONS ate a migracao para contratos neutros.
# =============================================================================
echo -e "── ${CYAN}REGRA-CROSS-MODULE-2${NC}: acoplamentos laterais warning-only ─────"
echo ""

CROSS_MODULE_VIOLATIONS=()
CROSS_MODULE_WHITELIST=()
CROSS_MODULE_GROUPS=0
CROSS_MODULE_WHITELIST_GROUPS=0

add_cross_violation() {
  local LABEL="$1"
  local FILE="$2"
  local PATTERN="$3"
  local SUGGESTION="$4"

  if [ ! -f "$FILE" ]; then
    warn "REGRA-CROSS-MODULE-2: arquivo nao encontrado para $LABEL: $FILE"
    return
  fi

  local RESULT
  RESULT=$(grep -nE "$PATTERN" "$FILE" || true)

  if [ -n "$RESULT" ]; then
    CROSS_MODULE_GROUPS=$((CROSS_MODULE_GROUPS + 1))
    while IFS= read -r line; do
      CROSS_MODULE_VIOLATIONS+=("$LABEL|$FILE:$line|$SUGGESTION")
    done <<< "$RESULT"
  fi
}

add_cross_whitelist() {
  local LABEL="$1"
  local FILE="$2"
  local PATTERN="$3"
  local ADR="$4"

  if [ ! -f "$FILE" ]; then
    warn "REGRA-CROSS-MODULE-2: arquivo whitelist nao encontrado para $LABEL: $FILE"
    return
  fi

  local RESULT
  RESULT=$(grep -nE "$PATTERN" "$FILE" || true)

  if [ -n "$RESULT" ]; then
    CROSS_MODULE_WHITELIST_GROUPS=$((CROSS_MODULE_WHITELIST_GROUPS + 1))
    while IFS= read -r line; do
      CROSS_MODULE_WHITELIST+=("$LABEL|$FILE:$line|$ADR")
    done <<< "$RESULT"
  fi
}

add_cross_violation \
  "agenda_ai -> agenda" \
  "lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart" \
  "import.*package:soloforte_app/modules/agenda/" \
  "Criar contrato neutro para leitura de agenda/visitas em core/contracts"

add_cross_violation \
  "agenda_ai -> carteira" \
  "lib/modules/agenda_ai/presentation/widgets/agenda_ai_sheet.dart" \
  "import.*package:soloforte_app/modules/carteira/" \
  "Criar contrato neutro de resumo de carteira/oportunidades em core/contracts"

add_cross_violation \
  "agenda -> agenda_ai" \
  "lib/modules/agenda/presentation/pages/agenda_month_page.dart" \
  "import.*package:soloforte_app/modules/agenda_ai/" \
  "Mover composicao para camada neutra ou criar IAgendaAILookup"

add_cross_violation \
  "agenda -> carteira" \
  "lib/modules/agenda/presentation/widgets/oportunidades_cliente_section.dart" \
  "import.*package:soloforte_app/modules/carteira/" \
  "Usar IOpportunityLookup em core/contracts em vez de provider de carteira"

add_cross_violation \
  "map -> consultoria/ndvi" \
  "lib/modules/map/presentation/widgets/visit_active_card.dart" \
  "import.*package:soloforte_app/modules/(consultoria|ndvi)/" \
  "Usar DTOs/contratos neutros para dados de cliente, talhao e NDVI"

add_cross_violation \
  "consultoria -> ndvi" \
  "lib/modules/consultoria/clients/presentation/screens/field_detail_screen.dart" \
  "import.*package:soloforte_app/modules/ndvi/" \
  "Expor imagens NDVI via contrato neutro ou rota/composicao externa"

add_cross_violation \
  "ndvi -> drawing" \
  "lib/modules/ndvi/presentation/providers/ndvi_providers.dart" \
  "import.*package:soloforte_app/modules/drawing/" \
  "Usar IFieldLookup de core/contracts em vez de provider de drawing"

add_cross_violation \
  "consultoria -> marketing" \
  "lib/modules/consultoria/relatorios/presentation/relatorios_page.dart" \
  "import.*package:soloforte_app/modules/marketing/" \
  "Criar contrato neutro para resumo de cases de marketing"

add_cross_whitelist \
  "map -> visitas" \
  "lib/modules/map/presentation/widgets/visit_active_card.dart" \
  "import.*package:soloforte_app/modules/visitas/" \
  "DT-025-3 — migrar para contrato em ciclo futuro"

add_cross_whitelist \
  "ui/components/map -> marketing" \
  "lib/ui/components/map/widgets/isolated_marker_layers.dart" \
  "import.*modules/marketing/" \
  "DT-035 — ADR-035 aceita divida temporaria para v1.1"

if [ "${#CROSS_MODULE_VIOLATIONS[@]}" -gt 0 ]; then
  warn "REGRA-CROSS-MODULE-2: $CROSS_MODULE_GROUPS grupo(s) de acoplamento lateral detectado(s)"
  echo "      Ocorrencias de import: ${#CROSS_MODULE_VIOLATIONS[@]}"
  echo "      MODO WARNING-ONLY — nao bloqueia CI nesta versao v1.1"
  echo ""
  for violation in "${CROSS_MODULE_VIOLATIONS[@]}"; do
    IFS="|" read -r label location suggestion <<< "$violation"
    echo -e "      ${YELLOW}→${NC} $location"
    echo "        $label"
    echo "        Sugestao: $suggestion"
  done
  echo ""
  echo "      Solucao: usar contratos em core/contracts/ para comunicacao entre modulos."
  echo "      Enforcement rigido planejado para v1.2 apos migracao."
  echo ""
  # v1.1 warning-only: nao incrementar VIOLATIONS ainda.
  # VIOLATIONS=$((VIOLATIONS + ${#CROSS_MODULE_VIOLATIONS[@]}))
else
  pass "REGRA-CROSS-MODULE-2: nenhum acoplamento lateral detectado"
fi

if [ "${#CROSS_MODULE_WHITELIST[@]}" -gt 0 ]; then
  info "REGRA-CROSS-MODULE-2: $CROSS_MODULE_WHITELIST_GROUPS divida(s) em whitelist temporaria (${#CROSS_MODULE_WHITELIST[@]} ocorrencia(s))"
  echo "      DT-025-3 — map -> visitas direto"
  echo "      DT-035 — ui/components/map -> marketing direto"
  echo ""
fi

echo ""

# =============================================================================
# REGRA-NDVI (ADR-042) — blindagem do modulo NDVI
#
# Fundamento: recuperacao NDVI depende de lookup encadeado em main.dart,
#             fronteira sem import de consultoria/drawing e suite de regressao.
# =============================================================================
echo -e "── ${CYAN}REGRA-NDVI${NC}: invariants ADR-042 (lookup chain + regressao) ───"
echo ""

# ── REGRA-NDVI-1: main.dart registra ChainedFieldLookup no iFieldLookupProvider
if [ ! -f "lib/main.dart" ]; then
  fail "REGRA-NDVI-1: lib/main.dart ausente"
else
  MAIN_CHAIN=$(grep -n "ChainedFieldLookup" lib/main.dart | grep -v "^\s*//" || true)
  MAIN_OVERRIDE=$(grep -n "iFieldLookupProvider.overrideWith" lib/main.dart | grep -v "^\s*//" || true)
  if [ -z "$MAIN_CHAIN" ] || [ -z "$MAIN_OVERRIDE" ]; then
    fail "REGRA-NDVI-1: main.dart deve registrar ChainedFieldLookup em iFieldLookupProvider (ADR-042)"
  else
    pass "main.dart registra ChainedFieldLookup em iFieldLookupProvider (ADR-042)"
  fi
fi

# ── REGRA-NDVI-2: artefatos obrigatorios do modulo
NDVI_REQUIRED_FILES=(
  "lib/modules/ndvi/infra/chained_field_lookup.dart"
  "lib/modules/ndvi/data/ndvi_cache_policy.dart"
  "lib/modules/ndvi/domain/ndvi_image_utils.dart"
)

NDVI_MISSING_FILES=0
for ndvi_file in "${NDVI_REQUIRED_FILES[@]}"; do
  if [ ! -f "$ndvi_file" ]; then
    fail "REGRA-NDVI-2: arquivo obrigatorio ausente: $ndvi_file"
    NDVI_MISSING_FILES=$((NDVI_MISSING_FILES + 1))
  fi
done

if [ "$NDVI_MISSING_FILES" -eq 0 ]; then
  pass "artefatos NDVI obrigatorios presentes (lookup chain, cache, source utils)"
fi

# ── REGRA-NDVI-3: suite de regressao obrigatoria
NDVI_REQUIRED_TESTS=(
  "test/modules/ndvi/chained_field_lookup_test.dart"
  "test/modules/ndvi/ndvi_phase1_integration_test.dart"
  "test/modules/ndvi/ndvi_phase2_test.dart"
  "test/modules/ndvi/ndvi_phase3_widget_test.dart"
  "test/supabase/ndvi_fetch_contract_test.dart"
)

NDVI_MISSING_TESTS=0
for ndvi_test in "${NDVI_REQUIRED_TESTS[@]}"; do
  if [ ! -f "$ndvi_test" ]; then
    fail "REGRA-NDVI-3: teste de regressao ausente: $ndvi_test"
    NDVI_MISSING_TESTS=$((NDVI_MISSING_TESTS + 1))
  fi
done

if [ "$NDVI_MISSING_TESTS" -eq 0 ]; then
  pass "suite de regressao NDVI presente (fases 1-3 + contrato edge)"
fi

# ── REGRA-NDVI-4: ndvi_providers usa IFieldLookup via core/contracts
if [ -f "lib/modules/ndvi/presentation/providers/ndvi_providers.dart" ]; then
  NDVI_PROVIDER_CONTRACT=$(grep -n "iFieldLookupProvider" \
    lib/modules/ndvi/presentation/providers/ndvi_providers.dart \
    | grep -v "^\s*//" || true)
  NDVI_PROVIDER_DRAWING=$(grep -nE "import.*modules/drawing/" \
    lib/modules/ndvi/presentation/providers/ndvi_providers.dart \
    | grep -v "^\s*//" || true)

  if [ -z "$NDVI_PROVIDER_CONTRACT" ]; then
    fail "REGRA-NDVI-4: ndvi_providers.dart deve consumir iFieldLookupProvider (core/contracts)"
  elif [ -n "$NDVI_PROVIDER_DRAWING" ]; then
    fail "REGRA-NDVI-4: ndvi_providers.dart nao pode importar drawing/ diretamente"
  else
    pass "ndvi_providers.dart consome iFieldLookupProvider sem import de drawing/"
  fi
else
  fail "REGRA-NDVI-4: ndvi_providers.dart ausente"
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
