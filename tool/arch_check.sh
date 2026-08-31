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
#   REGRA-NAV-1 — context.pop()/canPop() proibidos (Map-First)
#   REGRA-MARKETING — blindagem de pins, fronteiras e bottom sheets
#   REGRA-OCCURRENCE-SHEET — blindagem criação ocorrência P0/P1 (BUG-006)
#   REGRA-UI-MAP-CTA — anti-regressão CTA fantasma + sombra de atribuição
#   REGRA-RESTORE-1 — push agronômico PT-only (BUG-011 restore pós-reinstall)
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
  "modules/drawing/presentation/controllers/drawing_controller.dart"  # 1697 — vertex em part; CRUD/orchestrators pendentes
  "modules/drawing/domain/drawing_utils.dart"                          # 1010 — utilitário puro, candidato a split
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
# REGRA-MARKETING — blindagem de pins, fronteiras e bottom sheets
#
# Fundamento: marketing publica pins no mapa e sheets de criacao/detalhe.
#             Regressões aqui afetam legibilidade, poluição do mapa e padrão
#             visual global de bottom sheets.
# =============================================================================
echo -e "── ${CYAN}REGRA-MARKETING${NC}: pins e bottom sheets padronizados ───────────"
echo ""

MARKETING_CASE_MARKER="lib/modules/marketing/presentation/widgets/marketing_case_marker.dart"
ISOLATED_MARKER_LAYERS="lib/ui/components/map/widgets/isolated_marker_layers.dart"
PUBLIC_MAP_SCREEN="lib/ui/screens/public_map_screen.dart"
NOVO_CASE_SHEET="lib/modules/marketing/presentation/screens/novo_case_sheet.dart"

if [ -f "$MARKETING_CASE_MARKER" ] \
  && grep -q "PlanoMarketing.ouro => 10.0" "$MARKETING_CASE_MARKER" \
  && grep -q "PlanoMarketing.prata => 12.0" "$MARKETING_CASE_MARKER" \
  && grep -q "PlanoMarketing.bronze => 14.0" "$MARKETING_CASE_MARKER" \
  && grep -q "isVisibleAtZoom" "$MARKETING_CASE_MARKER"; then
  pass "REGRA-MARKETING-1: marker define visibilidade por zoom/plano"
else
  fail "REGRA-MARKETING-1: MarketingCaseMarker deve manter minZoom ouro=10, prata=12, bronze=14 e isVisibleAtZoom()"
fi

MARKETING_ZOOM_CONSUMERS=0
if [ -f "$ISOLATED_MARKER_LAYERS" ] && grep -q "MarketingCaseMarker.isVisibleAtZoom" "$ISOLATED_MARKER_LAYERS"; then
  MARKETING_ZOOM_CONSUMERS=$((MARKETING_ZOOM_CONSUMERS + 1))
fi
if [ -f "$PUBLIC_MAP_SCREEN" ] && grep -q "MarketingCaseMarker.isVisibleAtZoom" "$PUBLIC_MAP_SCREEN"; then
  MARKETING_ZOOM_CONSUMERS=$((MARKETING_ZOOM_CONSUMERS + 1))
fi

if [ "$MARKETING_ZOOM_CONSUMERS" -eq 2 ]; then
  pass "REGRA-MARKETING-2: camadas de mapa respeitam MarketingCaseMarker.isVisibleAtZoom()"
else
  fail "REGRA-MARKETING-2: mapa privado/publico devem filtrar pins via MarketingCaseMarker.isVisibleAtZoom()"
fi

RESULTADO_DUPLICATE_CLIENT=$(grep -rnE "Buscar Produtor/Fazenda|_buildClienteDropdown|clientLookupProvider" \
  "$NOVO_CASE_SHEET" \
  --include="*.dart" \
  2>/dev/null \
  | grep -v "^\s*//" \
  || true)

if [ -n "$RESULTADO_DUPLICATE_CLIENT" ]; then
  fail "REGRA-MARKETING-3: Resultado nao pode reintroduzir seletor branco duplicado de Produtor/Fazenda:"
  echo ""
  echo "$RESULTADO_DUPLICATE_CLIENT" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "REGRA-MARKETING-3: Resultado sem seletor duplicado de Produtor/Fazenda"
fi

MARKETING_SHEET_DOCS_OK=0
for agents_file in \
  "lib/modules/marketing/AGENTS.md" \
  "lib/modules/map/AGENTS.md" \
  "lib/ui/AGENTS.md"; do
  if [ -f "$agents_file" ] \
    && grep -q "showSoloForteSheet" "$agents_file" \
    && grep -q "SoloForteSheetTokens" "$agents_file"; then
    MARKETING_SHEET_DOCS_OK=$((MARKETING_SHEET_DOCS_OK + 1))
  fi
done

if [ "$MARKETING_SHEET_DOCS_OK" -eq 3 ]; then
  pass "REGRA-MARKETING-4: AGENTS locais documentam showSoloForteSheet + SoloForteSheetTokens"
else
  fail "REGRA-MARKETING-4: marketing/map/ui AGENTS devem documentar o padrão de bottom sheets"
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
  echo "      MODO FAIL — bloqueia CI (v1.2 Fase 2)"
  echo ""
  for violation in "${CROSS_MODULE_VIOLATIONS[@]}"; do
    IFS="|" read -r label location suggestion <<< "$violation"
    echo -e "      ${YELLOW}→${NC} $location"
    echo "        $label"
    echo "        Sugestao: $suggestion"
  done
  echo ""
  echo "      Solucao: usar contratos em core/contracts/ para comunicacao entre modulos."
  echo "      Enforcement v1.2 — bloqueia CI após migração Fase 2."
  echo ""
  VIOLATIONS=$((VIOLATIONS + ${#CROSS_MODULE_VIOLATIONS[@]}))
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

# ── REGRA-CLIMA-RADAR-1: radar RainViewer vive em clima/
CLIMA_RADAR_REQUIRED_FILES=(
  "lib/modules/clima/presentation/providers/radar_providers.dart"
  "lib/modules/clima/presentation/widgets/radar_layer_widget.dart"
  "lib/modules/clima/data/datasources/rainviewer_radar_datasource.dart"
  "lib/modules/clima/domain/radar_overlay_state.dart"
  "lib/modules/clima/domain/entities/radar_fetch_result.dart"
  "lib/core/contracts/i_radar_overlay_controller.dart"
  "docs/02_ARQUITETURA_ATIVA/ADR-043-RADAR-OVERLAY-CONTRACT.md"
  "test/fixtures/rainviewer_manifest_v2.json"
)

CLIMA_RADAR_MISSING=0
for clima_radar_file in "${CLIMA_RADAR_REQUIRED_FILES[@]}"; do
  if [ ! -f "$clima_radar_file" ]; then
    fail "REGRA-CLIMA-RADAR-1: arquivo obrigatorio ausente: $clima_radar_file"
    CLIMA_RADAR_MISSING=$((CLIMA_RADAR_MISSING + 1))
  fi
done

if [ "$CLIMA_RADAR_MISSING" -eq 0 ]; then
  pass "artefatos radar clima/ presentes (providers, widget, contrato ADR-043)"
fi

# ── REGRA-CLIMA-RADAR-2: providers legados em ui/ proibidos
if [ -f "lib/ui/components/map/providers/rainviewer_provider.dart" ]; then
  fail "REGRA-CLIMA-RADAR-2: rainviewer_provider.dart legado ainda existe em ui/"
elif rg -n "radarEnabledProvider|RainviewerRadarFrame" lib/ui/components/map/ 2>/dev/null | grep -v "^\s*//" | grep -q .; then
  fail "REGRA-CLIMA-RADAR-2: ui/components/map ainda referencia providers legados de radar"
else
  pass "ui/components/map sem providers RainViewer legados"
fi

# ── REGRA-CLIMA-RADAR-3: testes de regressao obrigatorios
CLIMA_RADAR_REQUIRED_TESTS=(
  "test/modules/clima/radar_providers_test.dart"
  "test/modules/clima/radar_layer_widget_test.dart"
  "test/modules/clima/radar_overlay_controller_test.dart"
  "test/modules/clima/radar_layer_order_test.dart"
  "test/modules/clima/radar_persistence_test.dart"
  "test/modules/clima/radar_overlay_states_test.dart"
  "test/modules/clima/rainviewer_contract_test.dart"
  "test/architecture/clima_radar_boundary_test.dart"
)

CLIMA_RADAR_TEST_MISSING=0
for clima_radar_test in "${CLIMA_RADAR_REQUIRED_TESTS[@]}"; do
  if [ ! -f "$clima_radar_test" ]; then
    fail "REGRA-CLIMA-RADAR-3: teste de regressao ausente: $clima_radar_test"
    CLIMA_RADAR_TEST_MISSING=$((CLIMA_RADAR_TEST_MISSING + 1))
  fi
done

if [ "$CLIMA_RADAR_TEST_MISSING" -eq 0 ]; then
  pass "suite de regressao radar clima presente"
fi

# ── REGRA-CLIMA-RADAR-4: main.dart registra IRadarOverlayController
if grep -q "radarOverlayControllerProvider.overrideWith" lib/main.dart; then
  pass "main.dart registra RadarOverlayControllerAdapter (ADR-043)"
else
  fail "REGRA-CLIMA-RADAR-4: main.dart deve registrar radarOverlayControllerProvider"
fi

# ── REGRA-CLIMA-RADAR-5: z-order canonico no map_build_orchestrator
if [ -f "lib/ui/screens/map/widgets/map_build_orchestrator.dart" ]; then
  RADAR_POS=$(grep -n "const ClimaRadarTileLayerWidget()" lib/ui/screens/map/widgets/map_build_orchestrator.dart | head -1 | cut -d: -f1)
  DRAWING_POS=$(grep -n "DrawingEditLayer(" lib/ui/screens/map/widgets/map_build_orchestrator.dart | head -1 | cut -d: -f1)
  MARKERS_POS=$(grep -n "const MapMarkersWidget()" lib/ui/screens/map/widgets/map_build_orchestrator.dart | head -1 | cut -d: -f1)

  if [ -z "$RADAR_POS" ] || [ -z "$DRAWING_POS" ] || [ -z "$MARKERS_POS" ]; then
    fail "REGRA-CLIMA-RADAR-5: map_build_orchestrator.dart deve conter radar, desenho e markers"
  elif [ "$RADAR_POS" -le "$DRAWING_POS" ] || [ "$MARKERS_POS" -le "$RADAR_POS" ]; then
    fail "REGRA-CLIMA-RADAR-5: ClimaRadarTileLayerWidget deve ficar apos DrawingEditLayer e antes de MapMarkersWidget"
  else
    pass "z-order radar valido (desenho < radar < markers)"
  fi
else
  fail "REGRA-CLIMA-RADAR-5: map_build_orchestrator.dart ausente"
fi

# ── REGRA-CLIMA-RADAR-6: toggle persistido e estados UX diferenciados
if grep -q "clima_radar_enabled_v1" lib/modules/clima/presentation/providers/radar_providers.dart; then
  pass "toggle climaRadarEnabled persistido em SharedPreferences"
else
  fail "REGRA-CLIMA-RADAR-6: climaRadarEnabled deve persistir via clima_radar_enabled_v1"
fi

if grep -q "ClimaRadarOverlayMessages.noPrecipitation" lib/modules/clima/domain/radar_overlay_state.dart && \
   grep -q "map_status_indicator" lib/ui/components/map/widgets/map_controls_overlay.dart && \
   grep -q "climaRadarEnabledProvider" lib/ui/components/map/widgets/map_controls_overlay.dart; then
  pass "estados UX diferenciados do radar (offline, vazio, erro + indicador unificado no mapa)"
else
  fail "REGRA-CLIMA-RADAR-6: radar_overlay_state.dart e indicador unificado do mapa devem diferenciar estados UX"
fi

# ── REGRA-CLIMA-RADAR-7: telemetria sanitizada via AppLogger
if grep -q "tag: 'Radar'" lib/modules/clima/domain/radar_overlay_logger.dart && \
   grep -q "AppLogger" lib/modules/clima/data/datasources/rainviewer_radar_datasource.dart; then
  pass "telemetria radar usa AppLogger sanitizado"
else
  fail "REGRA-CLIMA-RADAR-7: datasource/logger do radar devem usar AppLogger (tag Radar)"
fi

echo ""

# =============================================================================
# REGRA-MAP-CHROME-1 — coluna direita do mapa com posição travada
#
# Coluna atual: camadas / check-in (sem botão +). Não reage ao detent do sheet.
# Posição: kMapActionColumnBottomInset + safe-area (+ compensação draw = 16+44).
# =============================================================================
echo -e "── ${CYAN}REGRA-MAP-CHROME-1${NC}: coluna direita do mapa — posição travada ───────────────"
echo ""

MAP_CONTROLS_OVERLAY="lib/ui/components/map/widgets/map_controls_overlay.dart"
LAYOUT_CONSTANTS="lib/core/constants/layout_constants.dart"
if [ ! -f "$MAP_CONTROLS_OVERLAY" ]; then
  fail "REGRA-MAP-CHROME-1: $MAP_CONTROLS_OVERLAY ausente"
elif grep -q "mapSheetChromeInsetProvider" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: coluna de ações não pode depender de mapSheetChromeInsetProvider"
elif ! grep -q "kMapActionColumnBottomInset" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: usar kMapActionColumnBottomInset em map_controls_overlay.dart"
elif ! grep -q "kMapActionColumnSpacingAboveCheckIn" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: usar kMapActionColumnSpacingAboveCheckIn (gap 16) no overlay"
elif ! grep -q "kMapActionColumnButtonSize" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: usar kMapActionColumnButtonSize (não magic 44) no overlay"
elif grep -q "MapActionFabMenu" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: MapActionFabMenu não pode voltar à coluna sem ADR"
elif grep -q "map_control_actions_btn" "$MAP_CONTROLS_OVERLAY"; then
  fail "REGRA-MAP-CHROME-1: map_control_actions_btn não pode voltar à coluna sem ADR"
elif ! grep -q "kMapActionColumnSpacingAboveCheckIn + kMapActionColumnButtonSize" "$LAYOUT_CONSTANTS"; then
  fail "REGRA-MAP-CHROME-1: DrawModeCompensation deve ser SpacingAboveCheckIn + ButtonSize"
elif grep -q "kMapActionColumnSpacingAboveActions" "$LAYOUT_CONSTANTS"; then
  fail "REGRA-MAP-CHROME-1: constante morta kMapActionColumnSpacingAboveActions não deve existir"
else
  pass "coluna direita ancorada (inset + gap 16 + buttonSize; sem sheet/+ morto)"
fi

echo ""

# =============================================================================
# REGRA-SHEET-BLAST-1 — contrato de fundo do sheet (IPA 210)
#
# Mudança em core/ui/sheets é transversal. O teste de contrato garante que
# transparent no tema Azul resolve para SoloForteSheetSkinIos.background e que
# preserveMaterialDefaults não força o prata.
# Doc: .agent/AUDITORIA_REGRESSAO_IPA210.md · design/sheets.md
# =============================================================================
echo -e "── ${CYAN}REGRA-SHEET-BLAST-1${NC}: contrato showSoloForteSheet (blast radius sheets) ─────"
echo ""

SHEET_CONTRACT_TEST="test/regression/sheets/soloforte_sheet_contract_test.dart"
SHEET_IMPL="lib/core/ui/sheets/soloforte_sheet.dart"
if [ ! -f "$SHEET_CONTRACT_TEST" ]; then
  fail "REGRA-SHEET-BLAST-1: $SHEET_CONTRACT_TEST ausente"
elif [ ! -f "$SHEET_IMPL" ]; then
  fail "REGRA-SHEET-BLAST-1: $SHEET_IMPL ausente"
elif ! grep -q "resolveSoloForteSheetBackgroundColor" "$SHEET_IMPL"; then
  fail "REGRA-SHEET-BLAST-1: soloforte_sheet.dart deve expor resolveSoloForteSheetBackgroundColor"
else
  pass "contrato de sheet documentado e testável (REGRA-SHEET-BLAST-1)"
fi

# =============================================================================
# REGRA-NAV-1 — context.pop()/canPop() proibidos (Map-First, Fase 7)
#
# Fundamento: navegação declarativa via context.go()/push() com AppRoutes.
#             pop() cria stack implícita e quebra contrato SmartButton L1/L2+.
#
# Exceções: lib/ui/components/smart_button.dart — único ponto autorizado
#           a usar pop()/canPop() (volta à tela anterior; fallback /map).
# =============================================================================
echo -e "── ${CYAN}REGRA-NAV-1${NC}: context.pop()/canPop() proibidos fora do SmartButton ───────────────"
echo ""

NAV_VIOLATIONS=$(grep -rn "context\.pop()\|context\.canPop()" lib/ --include="*.dart" \
  | grep -v "lib/ui/components/smart_button.dart" \
  | grep -v "^\s*//" \
  || true)

if [ -n "$NAV_VIOLATIONS" ]; then
  fail "REGRA-NAV-1: context.pop()/canPop() detectados (usar context.go + AppRoutes):"
  echo ""
  echo "$NAV_VIOLATIONS" | while IFS= read -r line; do
    echo -e "      ${RED}→${NC} $line"
  done
  echo ""
else
  pass "nenhum context.pop()/canPop() fora de documentação"
fi

echo ""

# =============================================================================
# REGRA-UI-MAP-CTA — anti-regressão CTA fantasma + sombra de atribuição
#
# Fundamento (fix 2d72677 / reopen IPA):
#   1) Popup de atribuição NÃO pode auto-expandir (parece sombra/bug).
#   2) CTA AccessSoloForte e shell chrome usam políticas tipadas.
#   3) Redirect de autenticado em rota pública ocorre ANTES do await de perfil.
# =============================================================================
echo -e "── ${CYAN}REGRA-UI-MAP-CTA${NC}: CTA fantasma + sombra atribuição ────────"
echo ""

if grep -q "kMapAttributionPopupInitialDuration" \
  lib/ui/screens/map/widgets/map_build_orchestrator.dart && \
   grep -q "const Duration kMapAttributionPopupInitialDuration = Duration.zero" \
  lib/ui/components/map/map_attribution_policy.dart; then
  pass "atribuição do mapa usa Duration.zero (sem popup preto na entrada)"
else
  fail "REGRA-UI-MAP-CTA: map_build_orchestrator deve usar kMapAttributionPopupInitialDuration=Duration.zero"
fi

if grep -q "popupInitialDisplayDuration: const Duration(seconds:" \
  lib/ui/screens/map/widgets/map_build_orchestrator.dart; then
  fail "REGRA-UI-MAP-CTA: popupInitialDisplayDuration com Duration(seconds:) reintroduz sombra preta"
else
  pass "nenhum auto-expand de atribuição com Duration(seconds:) no orchestrator"
fi

if grep -q "shouldShowPublicAccessCta" lib/ui/screens/public_map_screen.dart && \
   grep -q "shouldShowShellChrome" lib/ui/components/app_shell.dart; then
  pass "CTA público e shell chrome gated por política tipada"
else
  fail "REGRA-UI-MAP-CTA: public_map_screen/app_shell devem usar public_access_cta_policy"
fi

# Garante ordem: redirect de rota pública ANTES do early-return de perfil loading.
# Sem isso, autenticado permanece em /public-map e o CTA fantasma reaparece.
ROUTER_PUBLIC_REDIRECT_LINE=$(grep -n "if (isPublicRoute)" lib/core/router/app_router.dart \
  | head -1 | cut -d: -f1 || true)
ROUTER_PROFILE_LOADING_LINE=$(grep -n "profileAsync.isLoading" lib/core/router/app_router.dart \
  | head -1 | cut -d: -f1 || true)

if [ -n "$ROUTER_PUBLIC_REDIRECT_LINE" ] && [ -n "$ROUTER_PROFILE_LOADING_LINE" ] && \
   [ "$ROUTER_PUBLIC_REDIRECT_LINE" -lt "$ROUTER_PROFILE_LOADING_LINE" ]; then
  pass "router redireciona autenticado fora de rota pública antes do await de perfil"
else
  fail "REGRA-UI-MAP-CTA: em app_router.dart, if (isPublicRoute) deve vir ANTES de profileAsync.isLoading"
fi

echo ""

# =============================================================================
# REGRA-OCCURRENCE-SHEET — blindagem P0/P1 criação de ocorrência no mapa
#
# Fundamento (BUG-006): sheet preso em 350px, perda de dados após foto.
# =============================================================================
echo -e "── ${CYAN}REGRA-OCCURRENCE-SHEET${NC}: criação de ocorrência no mapa ───────"
echo ""

MAP_BOTTOM_SHEET="lib/ui/components/map/map_bottom_sheet.dart"
OCC_UI_HELPERS="lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet_ui_helpers.dart"
OCC_CREATION_SHEET="lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart"
OCC_DRAFT_PROVIDER="lib/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart"
MAP_PERF_HOSTS="lib/ui/screens/map/widgets/map_performance_hosts.dart"
OCC_REGRESSION_TEST="test/regression/map/occurrence_creation_flow_regression_test.dart"

if [ -f "$MAP_BOTTOM_SHEET" ] \
  && grep -q "_resolveInitialDetent" "$MAP_BOTTOM_SHEET" \
  && grep -q "SheetDetent.expanded" "$MAP_BOTTOM_SHEET" \
  && grep -q "isCreatingOccurrence" "$MAP_BOTTOM_SHEET" \
  && ! grep -q "final initialHeight = 350.0" "$MAP_BOTTOM_SHEET"; then
  pass "REGRA-OCC-1: MapBottomSheet abre criação expandida sem altura 350px fixa"
else
  fail "REGRA-OCC-1: MapBottomSheet deve usar _resolveInitialDetent expanded (sem 350px hardcoded)"
fi

if [ -f "$MAP_BOTTOM_SHEET" ] \
  && grep -q "OccurrenceCloseCoordinator" "$MAP_BOTTOM_SHEET" \
  && grep -q "confirmDiscardIfDirty" "$MAP_BOTTOM_SHEET"; then
  pass "REGRA-OCC-2: dismiss de ocorrência passa pelo OccurrenceCloseCoordinator"
else
  fail "REGRA-OCC-2: MapBottomSheet deve confirmar descarte via OccurrenceCloseCoordinator"
fi

if [ -f "$OCC_UI_HELPERS" ] \
  && grep -q "Navigator.of(sheetContext).pop()" "$OCC_UI_HELPERS" \
  && grep -q "_capturePhotoFromSource" "$OCC_UI_HELPERS"; then
  pass "REGRA-OCC-3: foto fecha modal de origem antes do ImagePicker"
else
  fail "REGRA-OCC-3: occurrence_creation_sheet_ui_helpers deve pop sheet antes de pickImage"
fi

if [ -f "$MAP_BOTTOM_SHEET" ] \
  && grep -q "_shouldShowSheetContent" "$MAP_BOTTOM_SHEET" \
  && grep -q "_tabContentKey" "$MAP_BOTTOM_SHEET"; then
  pass "REGRA-OCC-4: showContent e tab key estáveis na criação"
else
  fail "REGRA-OCC-4: MapBottomSheet deve ter _shouldShowSheetContent e _tabContentKey"
fi

if [ -f "$OCC_DRAFT_PROVIDER" ] \
  && [ -f "$OCC_CREATION_SHEET" ] \
  && grep -q "_restoreDraftIfAny" "$OCC_CREATION_SHEET" \
  && grep -q "_persistDraft" "$OCC_CREATION_SHEET" \
  && grep -q "clearOccurrenceDraft" "$OCC_DRAFT_PROVIDER"; then
  pass "REGRA-OCC-5: rascunho keyed por pin com persist/restore/clear"
else
  fail "REGRA-OCC-5: occurrence draft provider + persist/restore no formulário"
fi

if [ -f "$MAP_PERF_HOSTS" ] && ! grep -q "clearOccurrenceDraft" "$MAP_PERF_HOSTS"; then
  pass "REGRA-OCC-6: onClose do host não apaga rascunho indiscriminadamente"
else
  fail "REGRA-OCC-6: map_performance_hosts não deve chamar clearOccurrenceDraft no onClose"
fi

if [ -f "$OCC_REGRESSION_TEST" ]; then
  pass "REGRA-OCC-7: regression shield BUG-006 presente"
else
  fail "REGRA-OCC-7: test/regression/map/occurrence_creation_flow_regression_test.dart obrigatório"
fi

echo ""

# =============================================================================
# REGRA-RESTORE-1 — push agronômico PT-only (BUG-011 restore pós-reinstall)
#
# Aliases EN no upsert (name/phone/city/state/document/area_ha) geram PGRST204
# no live; o upsert inteiro cai e wipe+pull deixa public.clients=0.
# Grep só o intervalo de cada *LocalToRemote — pull ainda aceita name legado.
# =============================================================================
echo -e "── ${CYAN}REGRA-RESTORE-1${NC}: push agronômico PT-only (BUG-011) ────────────────────────"
echo ""

RESTORE_MAPPER="lib/modules/consultoria/services/agronomic_sync_service.dart"
RESTORE_TEST="test/regression/consultoria/agronomic_restore_push_regression_test.dart"
DRAWINGS_MIGRATION="supabase/migrations/20260825050000_drawings_remote_sync.sql"

if [ ! -f "$RESTORE_TEST" ] || ! grep -q "BUG-011" "$RESTORE_TEST"; then
  fail "REGRA-RESTORE-1: $RESTORE_TEST ausente ou sem BUG-011"
else
  pass "regression shield BUG-011 presente"
fi

if [ ! -f "$DRAWINGS_MIGRATION" ]; then
  fail "REGRA-RESTORE-1: $DRAWINGS_MIGRATION ausente"
else
  pass "migration drawings remote sync presente"
fi

if [ ! -f "$RESTORE_MAPPER" ]; then
  fail "REGRA-RESTORE-1: $RESTORE_MAPPER ausente"
else
  CLIENT_PUSH=$(sed -n '/static Map<String, dynamic> clientLocalToRemote/,/static Map<String, dynamic> farmLocalToRemote/p' "$RESTORE_MAPPER")
  FARM_PUSH=$(sed -n '/static Map<String, dynamic> farmLocalToRemote/,/static Map<String, dynamic> fieldLocalToRemote/p' "$RESTORE_MAPPER")
  FIELD_PUSH=$(sed -n '/static Map<String, dynamic> fieldLocalToRemote/,/static Map<String, dynamic> clientCulturaLocalToRemote/p' "$RESTORE_MAPPER")

  if [ -z "$CLIENT_PUSH" ] || [ -z "$FARM_PUSH" ] || [ -z "$FIELD_PUSH" ]; then
    fail "REGRA-RESTORE-1: não encontrou intervalo *LocalToRemote no mapper"
  elif echo "$CLIENT_PUSH" | grep -E -q "'(name|phone|city|state|document|area_ha)':"; then
    fail "REGRA-RESTORE-1: clientLocalToRemote não pode enviar aliases EN (name/phone/city/state/document/area_ha)"
  else
    pass "clientLocalToRemote PT-only (sem aliases EN)"
  fi

  if echo "$FARM_PUSH" | grep -E -q "'(client_id|name|area_ha)':"; then
    fail "REGRA-RESTORE-1: farmLocalToRemote não pode enviar client_id/name/area_ha"
  else
    pass "farmLocalToRemote PT-only (cliente_id/nome/area_total)"
  fi

  if echo "$FIELD_PUSH" | grep -E -q "'(farm_id|geometry|area_ha)':"; then
    fail "REGRA-RESTORE-1: fieldLocalToRemote não pode enviar farm_id/geometry/area_ha"
  else
    pass "fieldLocalToRemote PT-only (fazenda_id/nome/area_produtiva)"
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
