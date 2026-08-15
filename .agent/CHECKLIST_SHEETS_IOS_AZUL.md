# Checklist — Bottom Sheets × Modo Azul (SheetSkin iOS)

**Data:** 15/Ago/2026  
**Fontes:** `design/sheets.md` · `.agent/AUDITORIA_REGRESSAO_IPA210.md` · `rg showSoloForteSheet`  
**SHA main (audit):** inventário pós `1d08295`  
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
| Design modo Azul (média 32 sheets) | **~68%** | 100% = Fase 3 |
| Segurança BLAST (legível / sem tela branca) | **~94%** | ≥95% ✅ |

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
| 7 | Map — Município search | 70 | 85 | Chrome only |
| 8 | Map — Publicação pin preview | 70 | 85 | Chrome only |
| 9 | Map — Novo case launcher | 70 | 85 | Chrome only |
| 10 | Public map — publication preview | 70 | 85 | Chrome only |
| 11 | Agenda — month page | 70 | 90 | Chrome only |
| 12 | Auth — avatar picker | 70 | 85 | Chrome only |
| 13 | Settings sheet | 70 | 85 | Chrome only |
| 14 | Clima — settings / city / shared (3) | 70 | 85 | Chrome only |
| 15 | Marketing — draft saved | 70 | 90 | Chrome only |
| 16 | NDVI field presenter | 70 | 90 | Chrome only |
| 17 | Drawing — export format | 70 | 85 | Chrome only |
| 18 | Planos — block sheet | 70 | 85 | Chrome only |
| 19 | Helper genérico (`bottom_sheet_helper`) | 70 | 90 | Depende do caller |
| 20 | Ocorrências — detail (view) | 70 | 80 | Chrome; tokens escuros? |
| 21 | Map — Check-in / VisitSheet | **45** | 100 | Form dark + preserve |
| 22 | Map — Visit active card | 50 | 100 | Opt-out |
| 23 | Agenda — day event | 50 | 100 | Opt-out |
| 24 | Agenda AI | 50 | 100 | Opt-out |
| 25 | Carteira (screen/cliente/categoria) | 50 | 100 | Opt-out |
| 26 | Clientes (form/edit/detail/farm/link) | 50 | 100 | Opt-out (~10 sites) |
| 27 | Ocorrências — creation helpers | 50 | 100 | Opt-out |
| 28 | Ocorrências — detail edit nested | 50 | 100 | Opt-out |
| 29 | Relatórios — page occurrence | 50 | 100 | Opt-out (IPA 210) |
| 30 | Marketing — case sheet | 50 | 100 | Opt-out |
| 31 | Marketing — photo picker | 50 | 100 | Opt-out |
| 32 | Marketing — edit case (lookup) | 50 | 100 | Opt-out |

---

## Resumo por faixa

| Faixa design | Qtd | Sheets |
|---|---|---|
| 100% | **6** | Camadas, Ações+, Drawing, Layers, MapBottomSheet chrome, Relatórios photos |
| 70% | **14** | Chrome iOS sem migração de conteúdo |
| 50% | **11** | Opt-out dark (`preserveMaterialDefaults`) |
| 45% | **1** | Check-in / VisitSheet |

---

## O que falta para Design Azul = 100%

**Fase 3 (prompts cirúrgicos separados, REGRA-SHEET-BLAST-1):**

1. Migrar conteúdo dos **14** chrome-only → `soloForteSheetIsIos` + tokens iOS  
2. Remover opt-out dos **11** `preserveMaterialDefaults` **só depois** de adaptar o conteúdo escuro  
3. VisitSheet / check-in → anatomia iOS (hoje dark intencional)  
4. Smoke QA tema Azul em cada bounded context da tabela BLAST

**Não fazer em lote único** — blast radius transversal (IPA 210).

---

## Validação desta auditoria

```bash
rg -l "showSoloForteSheet" lib --glob '*.dart'
rg -n "preserveMaterialDefaults: true" lib --glob '*.dart'
flutter test test/regression/sheets/soloforte_sheet_contract_test.dart
./tool/arch_check.sh
```

*Auditoria 100% · Design Azul ~68% · Safety ~94% · 15/08/2026*
