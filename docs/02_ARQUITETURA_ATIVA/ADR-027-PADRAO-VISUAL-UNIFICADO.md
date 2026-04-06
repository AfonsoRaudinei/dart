# ADR-027 — Padrão Visual Unificado: `SoloForteSheet`
**Status:** APROVADO — tokens visuais confirmados por screenshot real  
**Data:** 06/04/2026  
**Módulos afetados:** Todos (cross-cutting concern de UI)  
**Risco:** MÉDIO — alteração visual sem toque em lógica de domínio  
**Autoridade:** ARCH_BASELINE_v1.1_SCORE_90.md  
**Referência visual:** `IMG_3809.png` — OccurrenceCreationSheet em produção
**Nota:** ADR-026 reservado para `IVisitWriter` (bounded contexts, Mar/2026)

---

## PROBLEMA

O SoloForte possui 37+ chamadas a `showModalBottomSheet` espalhadas por 7
módulos. Cada chamador define seus próprios parâmetros visuais localmente.

Consequência:
- Inconsistência visual entre módulos
- Duplicação de parâmetros em todo o codebase
- Impossibilidade de atualizar o padrão em um único lugar
- Risco de regressão visual a cada novo sheet criado

---

## FONTE DA VERDADE VISUAL

Screenshot confirmado: `OccurrenceCreationSheet` — `IMG_3809.png`
Este sheet é o padrão de referência para todos os outros.

---

## DESIGN TOKENS OFICIAIS

### Sheet container
```dart
backgroundColor : Color(0xFF1C1C1E)   // preto iOS — NÃO usar Colors.black
borderRadius    : BorderRadius.vertical(top: Radius.circular(20))
clipBehavior    : Clip.antiAliasWithSaveLayer
useSafeArea     : true
showDragHandle  : true
```

### Campos de input
```dart
fillColor       : Color(0xFF2C2C2E)
borderRadius    : BorderRadius.circular(12)
border          : InputBorder.none
textColor       : Colors.white
hintColor       : Color(0xFF8E8E93)
contentPadding  : EdgeInsets.symmetric(horizontal: 16, vertical: 14)
```

### Headers de seção
```dart
// ícone emoji + texto bold branco + Divider abaixo
labelColor      : Colors.white
fontSize        : 15
fontWeight      : FontWeight.w600
dividerColor    : Color(0xFF3A3A3C)
```

### Botões de categoria (círculos)
```dart
backgroundColor : Color(0xFF3A3A3C)
iconColor       : Colors.white
labelColor      : Color(0xFFAEAEB2)
circleDiameter  : 72.0
iconSize        : 28.0
```

### Seleção exclusiva (ex: Urgência)
```dart
// Não selecionado
borderColor     : Color(0xFF3A3A3C)
textColor       : Color(0xFF8E8E93)

// Selecionado
borderColor     : Color(0xFFF59E0B)   // âmbar
textColor       : Color(0xFFF59E0B)
borderWidth     : 2.0
borderRadius    : BorderRadius.circular(12)
```

### Chip de coordenadas
```dart
backgroundColor : Color(0xFF1A2E1A)
textColor       : Color(0xFF4ADE80)
borderRadius    : BorderRadius.circular(20)
fontSize        : 13
```

### Título inline do sheet
```dart
fontSize        : 20
fontWeight      : FontWeight.w700
color           : Colors.white
```

---

## DECISÃO

Criar `lib/core/ui/sheets/` com 5 arquivos:

```
lib/core/ui/sheets/
├── soloforte_sheet.dart          ← função wrapper (entry point)
├── sheet_tokens.dart             ← todas as constantes visuais
└── widgets/
    ├── sheet_section_header.dart ← seção: ícone + label + divider
    ├── sheet_input_field.dart    ← TextField padronizado
    └── sheet_chip_selector.dart  ← seleção exclusiva (Urgência, etc.)
```

Regra: todos os arquivos máx. 120 linhas. Nenhum importa `lib/modules/`.

---

## CONTRATO: `showSoloForteSheet`

```dart
Future<T?> showSoloForteSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  double? maxHeightFraction,
})
```

Parâmetros fixos internos:
```dart
backgroundColor : SoloForteSheetTokens.sheetBackground 
shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20))
)
useSafeArea     : true
clipBehavior    : Clip.antiAliasWithSaveLayer
```

---

## AUDITORIA DE CONFORMIDADE

### GRUPO A — Migração mecânica (sem risco)
Builder permanece idêntico. Apenas troca o wrapper.

| Arquivo | Função | Módulo |
|---|---|---|
| `plano_block_sheet.dart` | `showPlanoUpgradeSheet` | core/planos |
| `profile_avatar_picker.dart` | `_showPickerOptions` | settings/ |
| `settings_screen.dart` | `showLanguageSelectionSheet` | settings/ |
| `clima_settings_sheet.dart` | `showClimaSettings` | settings/ |
| `relatorios_list_screen.dart` | `showRelatorioFilterSheet` | consultoria/ |
| `draft_saved_sheet.dart` | `DraftSavedSheet` | marketing/ |
| `marketing_case_sheet.dart` | `MarketingCaseSheet` | marketing/ |
| `publicacao_pin_preview.dart` | `showPublicacaoPinPreview` | map/ |
| `public_publication_preview.dart` | `showPublicPublicationPreview` | map/ |
| `occurrence_detail_sheet.dart` | `showOccurrenceDetailSheet` | consultoria/ |
| `private_map_sheets.dart` | `showLayerSelectionSheet` | map/ |

### GRUPO B — Migração com inspeção prévia obrigatória

| Arquivo | Função | Verificar antes |
|---|---|---|
| `visit_active_card.dart` | `_showCheckInSheet` | Provider chamado dentro do builder, não fora |
| `visit_active_card.dart` | `_showVisitDetailsSheet` | Navegação pós-ação via `context.go()` |
| `agenda_month_page.dart` | `_showCreateEventSheet` | Cadeia `CreateEventUseCase` completa |
| `day_event_card.dart` | `_showEventDetailsSheet` | Ações usam `context.go()`, não `pop()` |
| `carteira_screen.dart` | `_showAddCategorySheet` | Provider correto para persistência |
| `carteira_screen.dart` | `_showEditCategorySheet` | Idem |
| `marketing_photo_service.dart` | seleção de fotos | Context válido no momento da chamada |

### GRUPO C — Tracked Debt (não migrar nesta ADR)

| ID | Arquivo | Problema |
|---|---|---|
| DT-027-1 | `occurrence_creation_sheet.dart` | Fluxo multi-step encadeado. Risco de `Navigator.pop()` entre steps. ADR separado. |
| DT-027-2 | `client_detail_sub_widgets.dart` | Auditar imports cruzados em `consultoria/`. |
| DT-027-3 | `client_edit_form.dart` | Origem dos dados Cidade/Estado indefinida. |

---

## PLANO DE EXECUÇÃO — 3 FASES

### FASE 1 — Criar utilitário (nada migrado ainda)
Arquivos tocados: 5 novos em `lib/core/ui/sheets/`.  ✅ CONCLUÍDA 06/04/2026
Nenhum arquivo existente alterado.
Gate: `arch_check.sh` Exit 0 + `flutter analyze` 0 erros.

### FASE 2 — Migrar Grupo A (11 arquivos, commit por arquivo)
Substituir wrapper. Builder intocado.
Gate por arquivo: visual confirmado + `flutter analyze` 0 erros.

### FASE 3 — Migrar Grupo B (7 arquivos, inspeção + migração)
PASSO 0 obrigatório por arquivo.
Inspeção escrita documentada antes de qualquer edição.

---

## REGRA DE PREVENÇÃO — `arch_check.sh` REGRA-SHEET-1

```bash
# REGRA-SHEET-1: showModalBottomSheet direto é proibido (ADR-027)
DIRECT_MODAL=$(grep -rn "showModalBottomSheet" lib/ \
  --include="*.dart" \
  | grep -v "lib/core/ui/sheets/soloforte_sheet.dart" \
  | grep -v "^\s*//" | wc -l)

if [ "$DIRECT_MODAL" -gt 0 ]; then
  echo "❌ REGRA-SHEET-1: showModalBottomSheet direto detectado."
  echo "   Use showSoloForteSheet() de lib/core/ui/sheets/soloforte_sheet.dart"
  EXIT_CODE=1
fi
```

---

## IMPACTO TOTAL

| Item | Status |
|---|---|
| Lógica de domínio alterada | ❌ NÃO |
| Contratos de dados alterados | ❌ NÃO |
| Providers alterados | ❌ NÃO |
| Rotas alteradas | ❌ NÃO |
| Map-First afetado | ❌ NÃO |
| arch_check.sh — nova regra | ✅ REGRA-SHEET-1 |
| Testes existentes impactados | ❌ NÃO |
| Arquivos novos em core/ | ✅ 5 arquivos (zero imports de modules/) |

---

*Tokens extraídos de screenshot real em produção (IMG_3809.png).*  
*Divergências visuais em outros módulos devem usar estes tokens como correção.*  
*ADR-026 reservado para `IVisitWriter` — não reutilizar este número.*
