# PROMPT — Toolbar contextual na seleção de talhão (Map-First)

**Revisão de qualidade:** após implementação, o pipeline do agente roda **revisor DIFF** (`soloforte-revisor`, modelo padrão **Grok 4.6 High**). Esse passo substitui checkpoint humano de UI; P0/P1 bloqueiam merge.

**Agente executor:** `soloforte-executor` · Skill: `.cursor/skills/soloforte-task/SKILL.md`  
**Arquivo:** `claude/PROMPT_UI_TOOLBAR_CONTEXTUAL_SELECAO_TALHAO.md`  
**Data:** 27/10/2026  
**Bounded context:** `ui/` (host mapa) + `drawing/` (ações de feature) — política 4A  
**Tipo:** UX — mover ações de seleção do sheet para toolbar flutuante no mapa  
**arch_check.sh:** OBRIGATÓRIO Exit 0 antes de commit  
**flutter analyze:** sem erros novos no escopo antes de commit  
**Commits:** um arquivo por commit — **nunca** `git add .` / `git add -A`

---

## Contexto (produto)

Hoje, ao selecionar um talhão no mapa (`DrawingFeatureActionsMode.compact`), o app abre o sheet **“Ferramentas de Desenho”** com lista vertical (`DrawingActionsBar` em modo compact). O usuário quer **ações imediatas no mapa**, sem abrir sheet para o trio principal:

| Ação atual no sheet | Destino (decisão já tomada) |
|---|---|
| **Editar Geometria** | **Toolbar contextual** no mapa |
| **Vincular / editar dados** | **Toolbar contextual** no mapa |
| **Ver mapa NDVI** (quando `feature.id` não vazio) | **Toolbar contextual** no mapa |

**Justificativa (não reabrir com o usuário):** são as três ações de maior frequência na seleção por toque no polígono; o sheet compete com o mapa e esconde o contexto visual (NDVI, geometria). Operações avançadas (união, export, lote, excluir) permanecem no fluxo **full** (`DrawingFeatureActionsMode.full`) — menu “…” / ferramentas completas — **fora** deste prompt, salvo descoberta no PASSO 0.

Referência visual: screenshot com sheet “Ferramentas de Desenho” e itens acima.

---

## Objetivo

1. Com talhão selecionado no mapa (modo compact), exibir **barra de ícones contextual** sobre o mapa (estilo chrome existente: botões circulares/quadrados da coluna direita / padrão `_MapRoundToggleButton` ou equivalente em `lib/ui/components/map/`).
2. **Não** exigir abrir o sheet só para Editar geometria, Vincular dados ou NDVI.
3. Reutilizar **os mesmos callbacks** já ligados em `drawing_sheet_builders_b.dart` (`startEditMode`, metadata edit, `mapNdviOverlayFieldIdProvider`) — **sem duplicar lógica de negócio**.
4. Manter `showSoloForteSheet` / `DrawingActionsBar` para modo **full** e para edição de metadados embutida quando fizer sentido.

---

## Classificação de ações (fixa — sem Gate 1)

| Ação | Classificação | Observação |
|---|---|---|
| Editar Geometria | **Toolbar contextual** | Ícone + semantics + haptic |
| Vincular / editar dados | **Toolbar contextual** | Pode abrir sheet de metadados **depois** do tap; toolbar só dispara o fluxo |
| Ver mapa NDVI | **Toolbar contextual** | Só se hoje `onShowNdviMap != null` (talhão persistido) |
| União, Diferença, Interseção, Export, Lote, Excluir | **Permanecem no sheet full** | Não mover neste PR |
| Qualquer outra ação encontrada no PASSO 0 no caminho **compact** | **Mesma regra: toolbar** | Documentar no RELATÓRIO; **não interromper** o fluxo para perguntar |

---

## PASSO 0 — Descoberta obrigatória (executar e registrar no RELATÓRIO)

```bash
find lib/ -name "drawing_actions_bar.dart"
find lib/ -name "drawing_sheet*.dart"
rg -n "DrawingFeatureActionsMode\\.compact|featureActionsMode" lib/
rg -n "Ferramentas de Desenho|DrawingActionsBar" lib/
rg -n "mapNdviOverlayFieldIdProvider|startEditMode|_isEditingMetadata" lib/
rg -n "showSoloForteSheet|DrawingSheet" lib/ui/ lib/modules/drawing/
rg -n "kMapActionColumn|map_controls_overlay" lib/ui/components/map/
```

**Registrar no RELATÓRIO (sem pausar):**

- [ ] Onde o sheet compact é aberto ao selecionar feature no mapa
- [ ] Lista exata de ações visíveis em `compact` hoje (incluindo qualquer item além das três — aplicar regra toolbar)
- [ ] Arquivos que **não** podem ser alterados (teto): ver seção Escopo
- [ ] Testes existentes que assertam sheet / keys (`drawing_selected_*`, `DrawingActionsBar`)

---

## Escopo fechado (teto de arquivos)

**Pode tocar (típico):**

- `lib/ui/components/map/widgets/` — novo widget toolbar contextual + integração no orchestrator/overlay
- `lib/modules/drawing/presentation/widgets/` — reduzir/abrir sheet compact; extrair callbacks se necessário
- `lib/modules/drawing/presentation/widgets/components/drawing_actions_bar.dart` — só se precisar compartilhar labels/ícones (preferir não duplicar strings)
- `test/` — regressão toolbar + seleção compact

**Proibido (freio — auto-checagem no RELATÓRIO):**

- `lib/ui/components/smart_button.dart`
- Tema global / `PremiumTokens` fora de sheets já existentes
- `lib/core/router/app_router.dart` (rotas novas)
- `lib/core/database/` · contratos em `core/contracts/` · schema SQLite
- `context.pop()` / `Navigator.pop()` para navegação entre telas (dialogs/sheets modais: permitido)
- FAB local novo
- Refatoração oportunista fora do fluxo seleção compact

**Se durante a implementação tocar algo proibido ou outro módulo:** **desfazer** o trecho fora do escopo, registrar motivo no RELATÓRIO — **não** parar esperando resposta humana.

---

## PASSO 1 — Implementação

### 1.1 Toolbar contextual

- Aparece **somente** quando há feature selecionada no mapa em modo **compact** (mesma condição que hoje abre lista no sheet).
- Posição sugerida: acima da coluna direita ou faixa horizontal acima do FAB — **respeitar** `kMapActionColumnBottomInset` / `kFabSafeArea` (REGRA-MAP-CHROME-1: não mover coluna direita sem necessidade).
- Três botões mínimos (keys de teste sugeridas):
  - `map_talhao_toolbar_edit_geometry`
  - `map_talhao_toolbar_edit_metadata`
  - `map_talhao_toolbar_ndvi` (omitir widget se NDVI indisponível)
- Ícones: preferir `SFIcons` / Cupertino alinhados ao map chrome; evitar Material genérico decorativo.
- Long-press opcional: label temporário (padrão `_BasemapToggleButton`).

### 1.2 Sheet compact

- Ao selecionar talhão no mapa: **não** abrir automaticamente o sheet só por causa das três ações (ou abrir sheet mínimo/vazio se o código exigir estado — preferir **não** cobrir o mapa).
- Se o sheet ainda existir para outros subfluxos, remover do modo compact os três itens migrados (evitar duplicata UI).

### 1.3 Comportamento NDVI

- Igual ao atual: `mapNdviOverlayFieldIdProvider` + `invalidate(mapNdviOverlaySummaryProvider)`; colormap continua ao fechar toolbar/sheet.

### 1.4 Modo full

- Inalterado para quem abre ferramentas completas (`DrawingFeatureActionsMode.full`).

---

## PASSO 2 — Testes

- Widget/regressão: toolbar visível com seleção compact; tap dispara callback (mock provider/controller).
- Garantir que keys legadas do sheet compact não quebram modo full.
- Rodar:

```bash
./tool/arch_check.sh
flutter analyze lib/ui/components/map/ lib/modules/drawing/presentation/
flutter test test/modules/drawing/ test/regression/map/
```

(ajustar paths aos testes realmente afetados)

---

## PASSO 3 — Entrega Git

- Branch: `cursor/ui-talhao-context-toolbar-148e`
- PR + revisor DIFF + `gh pr merge --auto --rebase` (supervisor)
- REGRA-ENTREGA-1: só entregue com `mergedAt` em `origin/main`

---

## RELATÓRIO final (obrigatório no corpo do PR)

```markdown
## RELATÓRIO — Toolbar contextual seleção talhão

### PASSO 0
- Arquivos encontrados: …
- Ações no compact além das 3: … (classificação aplicada: toolbar)

### Auto-checagem de escopo
- [ ] Nenhum arquivo proibido tocado (ou revertido: …)
- [ ] Nenhum contrato/schema alterado
- [ ] Nenhuma rota nova
- [ ] REGRA-MAP-CHROME-1 respeitada

### Implementação
- Widget toolbar: …
- Sheet compact: …

### Validação
- arch_check: Exit …
- flutter analyze: …
- flutter test: …

### Revisor (Grok 4.6)
- Veredito: …
- P0/P1: …
```

---

## O que NÃO fazer neste prompt

- Redesenhar todo o `DrawingActionsBar` ou migrar operações booleanas para toolbar
- Alterar `smart_button` ou criar segundo FAB global
- Pedir **Gate 1** / aprovação humana de classificação UI (já decidida acima)
- Parar o fluxo por dúvida de escopo — reverter, documentar, seguir

---

## Referências

- `lib/modules/drawing/domain/drawing_feature_actions_mode.dart`
- `lib/modules/drawing/presentation/widgets/components/drawing_actions_bar.dart`
- `lib/modules/drawing/presentation/widgets/drawing_sheet_builders_b.dart`
- `lib/ui/AGENTS.md` · `lib/modules/drawing/AGENTS.md`
- `AGENTS.md` (raiz) · `docs/03_ENFORCEMENT/supervisor-merge-gate.md`
