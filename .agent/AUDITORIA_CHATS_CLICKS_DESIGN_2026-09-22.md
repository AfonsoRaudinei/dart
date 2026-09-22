# Auditoria — chats Cursor × PR × `origin/main`

**Data:** 2026-09-22  
**SHA `origin/main` no fechamento:** `e0411297` — `test(drawing): freeze edição e beginEditVertexDrag (IPA-238)`  
**Objetivo:** explicar por que o app “mudou” no device sem bater com expectativas de **Auditoria de cliques** ou **Design**, e onde está cada entrega.

---

## Resumo executivo

| Expectativa comum | Realidade na `main` hoje |
|---|---|
| Premium iOS nos sheets de talhão (menu, dados, união) | **Entregue** — PRs **#137** + **#143** (ancestral `9d05058c` na história) |
| **Auditoria de cliques** (menos toques, ficha única, mapa) | **Não entregue** — PR **#148** aberto (`cursor/menos-cliques-7486`) |
| Teclado unificado em sheets | **Não entregue** — PR **#141** aberto |
| Labels cultura/área no mapa | **Não entregue** — PR **#145** aberto |
| Mudança recente no app só com `git pull` | Provável **IPA-238 / drawing** (`e0411297`), não #148 |

**REGRA-ENTREGA-1:** só conta o que tem `mergedAt` em `origin/main`. Branch + auto-merge armado **não** contam.

---

## Tabela chat / branch / PR / estado

| Nome no Cursor (aprox.) | Branch | PR | Estado | O que muda no app se estiver na `main` |
|---|---|---|---|---|
| Premium iOS talhão sheets | `cursor/premium-ios-talhao-sheets-807c` | [#137](https://github.com/AfonsoRaudinei/dart/pull/137) | **MERGED** 2026-09-21 | Menu curto, sheet dados, união, Fatia A |
| Vistoria gaps G1–G6 | `cursor/vistoria-sheet-gaps-807c` | [#143](https://github.com/AfonsoRaudinei/dart/pull/143) | **MERGED** 2026-09-21 | Handle unificado, `ClientSheetIosRadio`, banner inline, widgets genéricos |
| **Auditoria de cliques** | `cursor/menos-cliques-7486` | [#148](https://github.com/AfonsoRaudinei/dart/pull/148) | **OPEN** | Camadas mapa, `map_mark_sheet`, agenda, relatórios, drawing sheet, pontes “menos cliques” |
| Bottom sheets + teclado | `cursor/sheet-keyboard-merge-497d` | [#141](https://github.com/AfonsoRaudinei/dart/pull/141) | **OPEN** | Merge P0/P1/P2 teclado em sheets |
| Área / labels talhão no mapa | `cursor/map-talhao-area-labels-9733` | [#145](https://github.com/AfonsoRaudinei/dart/pull/145) | **OPEN** | Cultura/material no talhão, labels no mapa |
| Split KML multipolygon | `cursor/split-kml-multipolygon-talhoes-807c` | (verificar no GitHub) | variável | Geometria KML — **não** é o pacote “Design premium sheets” |
| Drawing IPA-238 | (commits diretos na `main`) | — | **na `main`** | Edição de vértices / freeze testes drawing |

---

## Por que o premium talhão “não aparece” no olho

1. **Tema Azul obrigatório** — `soloForteSheetIsIos(context)` só fica `true` com `SoloForteThemeExtension.themeId == 'blue'` (Settings → tema). Verde/Preto mantém chrome legado nos ícones/cards consultoria.
2. **Caminho de entrada** — fluxo documentado em `design/sheets.md` BLOCO 5: **Cliente → Fazenda → talhão → ações** (`showTalhaoActionsSheet`), não menus antigos espalhados.
3. **Build** — hot restart **não** substitui IPA/TestFlight; após merge, usar `flutter run` ou novo IPA a partir de SHA ≥ `9d05058c`.
4. **Confusão com #148** — testar “auditoria de cliques” num build só da `main` **nunca** mostrará o diff de #148.

---

## Verificação no Mac (Fase 2)

```bash
git fetch origin && git checkout main && git pull origin main
git log -1 --oneline   # deve bater com origin/main (ex.: e0411297)
flutter pub get
```

Device:

- Tema **Azul** em Settings
- Abrir talhão pelo fluxo BLOCO 5
- Checklist visual: `design/sheets.md` → **BLOCO 5** (5.1–5.14)

Agente read-only para QA visual: `.cursor/agents/soloforte-designer-visual.md`  
Prompt operacional: `prompt/DESIGN_QA_TALHAO_SHEETS.md`

---

## Próximos passos (decisão produto)

| Se quiser… | Ação |
|---|---|
| Cliques / mapa / ficha única na `main` | Revisar + gate PR **#148** |
| Teclado sheets na `main` | Revisar PR **#141** |
| Labels área no mapa | Revisar PR **#145** |
| Só validar premium talhão já mergeado | QA BLOCO 5 + tema Azul — sem novo PR |

---

## Referências

- `.agent/AGENT_MEMORIA.md` — sync Mac, IPA, hot restart
- `.cursor/rules/soloforte-designer.mdc` — HTML/mapa/ocorrência (sem agent separado para HTML)
- `.agent/AUDITORIA_CLEANUP_BOTTOM_SHEETS_2026-02-18.md` — auditoria **doc** antiga (≠ chat “Auditoria de cliques”)
