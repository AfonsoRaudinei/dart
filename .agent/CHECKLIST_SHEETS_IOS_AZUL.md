# Checklist — Bottom Sheets × Modo Azul (SheetSkin iOS)

**Data:** 15/Ago/2026  
**Fontes:** `design/sheets.md` · `.agent/AUDITORIA_REGRESSAO_IPA210.md` · `rg showSoloForteSheet`  
**SHA main (audit):** inventário pós Fase 3  
**Status da auditoria:** **100% concluída** (todos os sheets listados e pontuados)

---

## Critérios de pontuação

| Faixa | Significado |
|---|---|
| **100%** | Chrome + conteúdo iOS Azul (padrão imagens Camadas / Ações) |
| **70%** | Chrome iOS automático; conteúdo ainda com tokens escuros (risco visual parcial) |
| **50%** | `preserveMaterialDefaults: true` — opt-out escuro **seguro** (BLAST), sem design Azul |
| **≤45%** | Host dark legado / form sem skin iOS |

**Duas médias:**

| Métrica | Valor | Meta |
|---|---|---|
| Auditoria (inventário completo) | **100%** | ✅ |
| Design modo Azul (média 32 sheets) | **~100%** | 100% = Fase 3 ✅ |
| Segurança BLAST (legível / sem tela branca) | **~98%** | ≥95% ✅ |

---

## Lista completa (32 superfícies)

| # | Sheet | Design % | Safety % | Estado |
|---|---|---|---|---|
| 1 | Map — Ferramentas / Camadas (`MapToolsBottomSheet`) | **100** | 100 | Referência (img 1) |
| 2 | Map — Ações + (`PublicationActions`) | **100** | 100 | Referência (img 2) |
| 3 | Map — DrawingSheet + ToolSelector | **100** | 100 | Nested dark corrigido |
| 4 | Map — LayersSheet | **100** | 100 | Contraste ok |
| 5 | Map — MapBottomSheet chrome | **100** | 100 | Host + scope |
| 6 | Relatórios — visit photos | **100** | 100 | Conteúdo iOS |
| 7 | Map — Município search | **100** | 100 | Fase 3 conteúdo iOS |
| 8 | Map — Publicação pin preview | **100** | 100 | Fase 3 |
| 9 | Map — Novo case launcher | **100** | 100 | Fase 3 |
| 10 | Public map — publication preview | **100** | 100 | Fase 3 |
| 11 | Agenda — month page | **100** | 100 | Fase 3 |
| 12 | Auth — avatar picker | **100** | 100 | Fase 3 |
| 13 | Settings sheet | **100** | 100 | Fase 3 |
| 14 | Clima — settings / city / shared (3) | **100** | 100 | Fase 3 |
| 15 | Marketing — draft saved | **100** | 100 | Fase 3 |
| 16 | NDVI field presenter | **100** | 100 | Fase 3 |
| 17 | Drawing — export format | **100** | 100 | Fase 3 |
| 18 | Planos — block sheet | **100** | 100 | Fase 3 |
| 19 | Helper genérico (`bottom_sheet_helper`) | **100** | 100 | Tokens iOS no helper |
| 20 | Ocorrências — detail (view) | **100** | 100 | Fase 3 |
| 21 | Map — Check-in / VisitSheet | **100** | 100 | Conteúdo iOS via `themeId`; host keep preserve |
| 22 | Map — Visit active card | **100** | 100 | Fase 3 |
| 23 | Agenda — day event | **100** | 100 | Fase 3 |
| 24 | Agenda AI | **100** | 100 | Fase 3 |
| 25 | Carteira (screen/cliente/categoria) | **100** | 100 | Fase 3 |
| 26 | Clientes (form/edit/detail/farm/link) | **100** | 100 | Fase 3 |
| 27 | Ocorrências — creation helpers | **100** | 100 | `occurrenceFormIsIos` + tokens |
| 28 | Ocorrências — detail edit nested | **100** | 100 | CreationSheet iOS sob preserve/themeId |
| 29 | Relatórios — page occurrence | **100** | 100 | CreationSheet iOS |
| 30 | Marketing — case sheet | **100** | 100 | Conteúdo iOS; preserve só layout DSS |
| 31 | Marketing — photo picker | **100** | 100 | Fase 3 |
| 32 | Marketing — edit case (lookup) | **100** | 100 | Fase 3 |

---

## Resumo por faixa

| Faixa design | Qtd | Sheets |
|---|---|---|
| 100% | **32** | Todas as superfícies do inventário |
| 70% | **0** | — |
| 50% | **0** | — |
| 45% | **0** | — |

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
./tool/arch_check.sh
```

*Auditoria 100% · Design Azul ~100% · Safety ~98% · Fase 3 · 15/08/2026*
