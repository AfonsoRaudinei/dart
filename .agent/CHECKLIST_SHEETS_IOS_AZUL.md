# Checklist — Bottom Sheets × Modo Azul (SheetSkin iOS)

**Data:** 15/Out/2026 (teclado) · 15/Ago/2026 (design Azul)  
**Fontes:** `design/sheets.md` · `.agent/AUDITORIA_REGRESSAO_IPA210.md` · `rg showSoloForteSheet`  
**SHA main (audit design):** inventário pós Fase 3  
**Status da auditoria:** **100% concluída** (design) · **teclado auditado 15/Out/2026**

---

## Critérios de pontuação

| Faixa | Significado |
|---|---|
| **100%** | Chrome + conteúdo iOS Azul (padrão imagens Camadas / Ações) |
| **70%** | Chrome iOS automático; conteúdo ainda com tokens escuros (risco visual parcial) |
| **50%** | `preserveMaterialDefaults: true` — opt-out escuro **seguro** (BLAST), sem design Azul |
| **≤45%** | Host dark legado / form sem skin iOS |

### Coluna Teclado

| Valor | Significado |
|---|---|
| **P0** | CTA sticky coberto pelo teclado + teclado não fecha — reparado nesta entrega |
| **P1** | Campo de texto sem `viewInsets` — reparado nesta entrega |
| **OK** | Já padava `viewInsets` (dismiss suave residual fora de escopo) |
| **N/A** | Sem TextField |

**Duas médias:**

| Métrica | Valor | Meta |
|---|---|---|
| Auditoria (inventário completo) | **100%** | ✅ |
| Design modo Azul (média 32 sheets) | **~100%** | 100% = Fase 3 ✅ |
| Segurança BLAST (legível / sem tela branca) | **~98%** | ≥95% ✅ |

---

## Lista completa (32 superfícies)

| # | Sheet | Design % | Safety % | Teclado | Estado |
|---|---|---|---|---|---|
| 1 | Map — Ferramentas / Camadas (`MapToolsBottomSheet`) | **100** | 100 | N/A | Referência (img 1) |
| 2 | Map — Ações + (`PublicationActions`) | **100** | 100 | N/A | Referência (img 2) |
| 3 | Map — DrawingSheet + ToolSelector | **100** | 100 | OK | Nested dark corrigido; `AnimatedPadding` |
| 4 | Map — LayersSheet | **100** | 100 | N/A | Contraste ok |
| 5 | Map — MapBottomSheet chrome | **100** | 100 | OK | Host + scope; detent − keyboard |
| 6 | Relatórios — visit photos | **100** | 100 | N/A | Conteúdo iOS |
| 7 | Map — Município search | **100** | 100 | P1 | `viewInsets` + scroll dismiss |
| 8 | Map — Publicação pin preview | **100** | 100 | N/A | Fase 3 |
| 9 | Map — Novo case launcher | **100** | 100 | OK | Fase 3 |
| 10 | Public map — publication preview | **100** | 100 | N/A | Fase 3 |
| 11 | Agenda — month page | **100** | 100 | N/A | Fase 3 |
| 12 | Auth — avatar picker | **100** | 100 | N/A | Fase 3 |
| 13 | Settings sheet | **100** | 100 | N/A | Fase 3 |
| 14 | Clima — settings / city / shared (3) | **100** | 100 | P1 | City: `viewInsets`; WhatsApp já OK |
| 15 | Marketing — draft saved | **100** | 100 | N/A | Fase 3 |
| 16 | NDVI field presenter | **100** | 100 | N/A | Fase 3 |
| 17 | Drawing — export format | **100** | 100 | N/A | Fase 3 |
| 18 | Planos — block sheet | **100** | 100 | N/A | Fase 3 |
| 19 | Helper genérico (`bottom_sheet_helper`) | **100** | 100 | N/A | Tokens iOS no helper |
| 20 | Ocorrências — detail (view) | **100** | 100 | N/A | Fase 3 |
| 21 | Map — Check-in / VisitSheet | **100** | 100 | OK | Conteúdo iOS via `themeId`; host keep preserve |
| 22 | Map — Visit active card | **100** | 100 | N/A | Fase 3 |
| 23 | Agenda — day event | **100** | 100 | N/A | Fase 3 |
| 24 | Agenda AI | **100** | 100 | P1 | Altura − teclado + `onTapOutside` |
| 25 | Carteira (screen/cliente/categoria) | **100** | 100 | OK | Dialogs já padam `viewInsets` |
| 26 | Clientes (form/edit/detail/farm/link) | **100** | 100 | OK | `clientSheetFormPadding` |
| 27 | Ocorrências — creation helpers | **100** | 100 | P0 | `OccurrenceDarkField` `onTapOutside` |
| 28 | Ocorrências — detail edit nested | **100** | 100 | P0 | CreationSheet modal 0.92 |
| 29 | Relatórios — page occurrence | **100** | 100 | P0 | CreationSheet modal 0.92 (img 1) |
| 30 | Marketing — case sheet | **100** | 100 | OK | Conteúdo iOS; preserve só layout DSS |
| 31 | Marketing — photo picker | **100** | 100 | N/A | Fase 3 |
| 32 | Marketing — edit case (lookup) | **100** | 100 | OK | `viewInsets` no scroll |

---

## Resumo por faixa

| Faixa design | Qtd | Sheets |
|---|---|---|
| 100% | **32** | Todas as superfícies do inventário |
| 70% | **0** | — |
| 50% | **0** | — |
| 45% | **0** | — |

### Superfícies extras (não estavam na tabela 32)

| Sheet | Teclado | Nota |
|---|---|---|
| Map — coordenada | P1 | `sheetFormKeyboardBottomPadding` |
| Map — download offline (form) | P1 | `sheetFormKeyboardBottomPadding` |
| Drawing — info edit | OK | Já tinha `viewInsets` |

### Teclado (15/Out/2026)

| Teclado | Qtd | Ação |
|---|---|---|
| P0 | 3 | OccurrenceCreationSheet modal (Relatórios + detail edit + helpers) |
| P1 | 5 | município, clima city, agenda AI, coordenada, offline form |
| OK | 8 | drawing / clientes / marketing / MapBottomSheet host / carteira |
| N/A | resto | sem TextField |

Kernel `showSoloForteSheet` **não** ganhou padding global (REGRA-SHEET-BLAST-1). PR #141 permanece fora.

---

## Preserve restantes (intencionais — layout, não opt-out dark)

```
lib/ui/screens/map/controllers/map_sheet_controller.dart  # check-in / DraggableScrollableSheet
lib/modules/marketing/presentation/widgets/marketing_case_sheet.dart  # DSS — conteúdo via themeId
```

Conteúdo Azul nestes hosts usa `themeId == 'blue'` (não só `soloForteSheetIsIos`), porque `preserveMaterialDefaults` força `SoloForteSheetSkinScope(isIos: false)`.

---

## Validação

```bash
rg -n "preserveMaterialDefaults: true" lib --glob '*.dart'
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart
flutter test test/core/ui/sheets/sheet_keyboard_inset_test.dart
flutter test test/modules/consultoria/occurrences/presentation/occurrence_creation_sheet_keyboard_test.dart
./tool/arch_check.sh
```

*Auditoria 100% · Design Azul ~100% · Safety ~98% · Fase 3 · 15/08/2026*  
*Teclado P0/P1 · `sheet_keyboard_inset.dart` · 15/10/2026*
