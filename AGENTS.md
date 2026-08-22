# AGENTS.md — SoloForte App

**Versão:** 1.1 | **Status:** ATIVO | **Data:** Jun/2026  
**Lido automaticamente pelo ChatGPT Codex em cada tarefa neste repositório**  
**Fonte da verdade para Cursor Rules, Copilot, Claude Code e Skills**

-----

## VERDADE DO PROJETO (atualizar somente aqui)

| Atributo | Valor |
|---|---|
| App | SoloForte — agri-tech, **mobile-only** (iOS + Android) |
| Baseline doc | v1.1 — `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md` |
| Release estabilização | v1.2 (`release/v1.2`) |
| Arquitetura | Map-First + Clean Architecture + Bounded Contexts |
| Estado | Riverpod `@riverpod` / `AsyncNotifier` (ADR-008) |
| Navegação | `context.go()` / `context.push()` — **nunca** `pop()` |
| Persistência | SQLite offline-first — schema **v41** (`database_helper.dart`) |
| Mapa | `flutter_map` — nunca `google_maps_flutter` |
| CI gate | `./tool/arch_check.sh` → Exit 0 |
| Coverage mínimo CI | 36.46% |

**Bounded contexts ativos:** `core` · `ui` · `map` · `drawing` · `agenda` · `agenda_ai` · `operacao` · `consultoria` · `visitas` · `settings` · `auth` · `planos` · `produtor` · `carteira` · `ndvi` · `marketing` · `feedback` · `dashboard` · `public` · `clima`

-----

## IDENTIDADE

Engenheiro sênior Flutter/Dart (top 5%).
Foco: Arquitetura limpa, contratos reais, estado previsível, zero improviso.

### Papéis dos agentes (3, não 4)

| Papel | Quem | Escreve `lib/`? | Mergeia `main`? |
|---|---|---|---|
| **Supervisor** | chat padrão | não | só via PR + auto-merge rebase, após o gate |
| **Executor** | `.cursor/agents/soloforte-executor.md` | sim, lista fechada | não — push da branch apenas |
| **Revisor** | `.cursor/agents/soloforte-revisor.md` | não | não |

Cadeado mecânico: `docs/03_ENFORCEMENT/supervisor-merge-gate.md`. Rule: `.cursor/rules/soloforte-supervisor.mdc`.

-----

## SETUP DO AMBIENTE

Antes de qualquer tarefa, execute:

```bash
chmod +x tool/arch_check.sh && ./tool/arch_check.sh
flutter analyze lib/
flutter test
```

**Entrega só é válida se `arch_check.sh` → Exit 0.**

-----

## PASSO 0 — OBRIGATÓRIO ANTES DE QUALQUER AÇÃO

```bash
find lib/ -name "nome_do_arquivo.dart"
rg -l "NomeClasse" lib/
```

Nunca assumir onde um arquivo está. Sempre auditar primeiro.

-----

## REGRAS ABSOLUTAS — NUNCA VIOLAR

### Arquitetura

- ❌ Não tratar como Flutter Web / Windows / Linux
- ❌ Não criar rotas fora de `lib/core/router/app_router.dart`
- ❌ Não usar `google_maps_flutter` — apenas `flutter_map`
- ❌ Não alterar `lib/ui/components/smart_button.dart` (FAB global — imutável)
- ❌ Não criar FAB local em nenhum módulo
- ❌ Não alterar tema ou Design System

### Navegação

- ❌ Não usar `context.pop()` ou `context.canPop()`
- ❌ Não criar sub-rotas sob `/map`
- ✅ Toda navegação via `context.go()` ou `context.push()` (GoRouter)

### Estado

- ❌ Não criar `StateNotifier` ou `ChangeNotifier` (exceto os 10 casos legados whitelisted no ADR-044)
- ❌ Não alterar providers compartilhados de `lib/core/` sem revisar impacto
- ✅ Usar `@riverpod` (function ou `AsyncNotifier`)
- ✅ `StateProvider<T>` para primitivos (bool, int, DateTime)

### Dados

- ❌ Não inventar dados fictícios
- ❌ Não criar placeholders com lógica
- ❌ Não fazer hard delete de dados sincronizáveis
- ✅ `user_id` obrigatório em todas as entidades persistidas
- ✅ `sync_status`: `local_only | pending_sync | synced | sync_error | deleted_local`

### Git

- ❌ Nunca `git add .` ou `git add -A`
- ✅ Commits por arquivo, mensagem descritiva por módulo
- ❌ Nunca `git push origin main` — a `main` só recebe rebase de PR
- ❌ **Nunca encerrar uma tarefa apenas com commit/push numa branch de feature** — isso não conta como entregue
- ✅ **Toda correção só está "no aplicativo" quando o commit aparece em `origin/main`** (ver REGRA-ENTREGA-1 abaixo). Auto-merge armado **não** é entrega.

-----

## REGRA-ENTREGA-1 — Correção só existe quando está na `main` (no app)

> Motivação: em Ago/2026 uma correção (`fix(map): coluna direita`, commit `302eeeb`) ficou
> **3 dias** só na branch `cursor/fix-map-chrome-canonical-spacing`, nunca chegou à `main` nem
> ao app publicado. Prompt executado + correção feita **não é o mesmo** que correção entregue.

**Definição de "pronto":** um prompt de correção/fix só está concluído quando o commit
aparece em `git log origin/main` — não quando aparece só em `git log` da branch local/feature.

| Etapa | Obrigatório | Comando |
|---|---|---|
| 1. Executor implementa + valida (`arch_check.sh`, analyze, testes) | ✅ | — |
| 2. Commit por arquivo + push da **branch** | ✅ | `git push -u origin <branch>` |
| 3. Supervisor abre PR + revisor DIFF | ✅ | `gh pr create` · Task `soloforte-revisor` |
| 4. Gate (P0/P1 bloqueia; path crítico pede ok; baixo risco + No findings segue) | ✅ | ver supervisor |
| 5. Auto-merge nativo **rebase** | ✅ | `gh pr merge --auto --rebase` — nunca `--admin`, nunca squash |
| 6. Encerramento honesto | ✅ | `gh pr view --json state,mergedAt,mergeStateStatus,autoMergeRequest,url` |

**Entregue** só com `mergedAt` (SHA em `origin/main`).  
**Não entregue:** `auto-merge armado, pendente de CI — ainda não está na main` + URL do PR.  
**Não entregue:** `autoMergeRequest` nulo e não merged (GitHub desarmou).

- ❌ Proibido `git push origin main` e `gh pr merge --admin`
- ❌ Proibido dizer "correção feita" com o código só na branch **ou** só com auto-merge armado
- ✅ Paths críticos (drawing, agenda, `core/database`, `core/ui/sheets`, `ui/screens/map`, `ui/components/map`) pedem ok no chat antes do `--auto --rebase`
- ✅ Cadeado: `docs/03_ENFORCEMENT/supervisor-merge-gate.md`
- ✅ Aplica-se a **todo** prompt neste repositório — ver `.agent/Prompt.md` (REGRA-ENTREGA-1)

-----

## FRONTEIRAS ENTRE MÓDULOS

Comunicação cross-module **APENAS** via `lib/core/contracts/`:

| Contrato | ADR | Implementador típico | Consumidores |
|---|---|---|---|
| `IClientLookup` | 015 | consultoria | drawing, agenda, marketing, carteira, visitas, dashboard |
| `IFarmLookup` | — | consultoria | drawing, ndvi, marketing |
| `IFieldLookup` | 022 | consultoria + drawing via `ChainedFieldLookup` em `main.dart` (ADR-042) | drawing, ndvi |
| `IVisitSessionLookup` | 020 | visitas | agenda, consultoria, dashboard |
| `IVisitClientLookup` | 020 | visitas | map |
| `IReportWriter` | 013 | consultoria/relatorios | visitas |
| `IAgendaSessionBridge` | — | agenda | agenda_ai |
| `IAgendaObservable` | — | agenda | map |
| `IOpportunityLookup` | — | carteira | map |
| `IMarketingCaseReportsLookup` | 050 | marketing | consultoria/relatorios |
| `IUserLocationLookup` | — | settings/clima | clima |
| `IOccurrenceRead` | — | consultoria | map |
| `IDrawingFieldWriter` | 038 | drawing | consultoria (via adapter) |
| `IProducerInviteWriter` | 039 | produtor | auth/settings |
| `IProducerPropertyGateway` | 040 | consultoria | produtor |
| `IOccurrenceAccessReader` | 041 | produtor | map |
| `IRadarOverlayController` | 043 | clima | ui/map |

**Dependências proibidas (diretas):**

```
drawing/     ❌ → consultoria/
agenda/      ❌ → consultoria/
consultoria/ ❌ → drawing/ ou agenda/ ou marketing/
visitas/     ❌ → consultoria/ ou drawing/ (só via contratos)
```

Se precisar cruzar fronteira → contrato em `core/contracts/` + ADR novo.

-----

## MÓDULOS DELETADOS — NUNCA REFERENCIAR

| Módulo | Status | Substituto |
|---|---|---|
| `lib/modules/reports/` | DELETADO (ADR-034) | `lib/modules/consultoria/relatorios/` |
| `lib/modules/consultoria/agenda/` | DELETADO (ADR-018) | `lib/modules/agenda/` |
| `lib/modules/relatorios/` (top-level) | NÃO EXISTE | `lib/modules/consultoria/relatorios/` |

-----

## ESTRUTURA DE PASTAS (referência)

```
lib/
├── core/
│   ├── contracts/         ← contratos inter-módulos
│   ├── database/          ← database_helper.dart (schema v41)
│   ├── domain/            ← FieldMapEntity (canônico — Etapa 3)
│   ├── router/            ← app_router.dart (única exceção core→modules)
│   └── state/
├── modules/
│   ├── agenda/            ← planejamento agronômico
│   ├── consultoria/       ← clientes, fazendas, talhões, ocorrências
│   │   └── relatorios/    ← ADR-013 (relatorios_v2)
│   ├── drawing/           ← geometrias, KML/KMZ
│   ├── map/               ← domínio/adapters leves (NÃO é o host UI do mapa)
│   ├── visitas/           ← sessões de visita (ADR-023)
│   ├── produtor/          ← propriedade do produtor (ADR-039/040)
│   └── settings/
└── ui/                    ← host Map-First (chrome, layers, overlays)
    ├── components/
    │   ├── app_shell.dart      ← SmartButton FAB ÚNICO
    │   ├── smart_button.dart   ← NUNCA ALTERAR
    │   └── map/                ← MapBottomSheet, controls, layers sheet
    └── screens/
        ├── private_map_screen.dart ← tela principal Map-First
        └── map/                    ← controllers, handlers, orchestrator
```

**Regras por módulo:** ler `lib/modules/<modulo>/AGENTS.md` ou `lib/core/AGENTS.md` / `lib/ui/AGENTS.md`.

### Fronteira Map-First (política 4A — oficial Ago/2026)

| Camada | Onde vive | Exemplos |
|---|---|---|
| **Host UI do mapa** | `lib/ui/screens/map/` · `lib/ui/components/map/` · `private_map_screen.dart` | chrome coluna direita, layers, sheets do mapa, orchestrator |
| **Módulo `map/`** | `lib/modules/map/` | adapters (`FieldMapAdapter`), providers/observers finos, widgets de visita ainda colocados |
| **Entidade visual compartilhada** | `lib/core/domain/field_map_entity.dart` | `FieldMapEntity` — não duplicar em `modules/map/domain/` |

- Correções de **chrome / sheets / overlay** → editar **`lib/ui/`** (não procurar só em `modules/map/`).
- **Proibido** migrar em massa `ui/ → modules/map/` sem ADR + aprovação explícita (isso seria política **4B**, fora de escopo).
- Ninguém importa `modules/map` de outro módulo de domínio; UI pode compor o mapa.

-----

## REGRAS DE EXECUÇÃO

### O agente DEVE

- Fazer PASSO 0 (find/rg) antes de qualquer ação
- Sugerir abordagem antes de executar em mudanças estruturais
- Declarar bounded context antes de qualquer mudança
- Respeitar `kFabSafeArea = 76dp` em layouts com scroll
- Rodar `arch_check.sh` ao final e confirmar Exit 0

### Padrão de bottom sheets

- Wrapper padrão: `lib/core/ui/sheets/soloforte_sheet.dart`
- Tokens visuais: `lib/core/ui/sheets/sheet_tokens.dart`
- Não duplicar handles, títulos ou botões de fechar fora do padrão
- **REGRA-SHEET-BLAST-1:** mudança em `core/ui/sheets/` é transversal (8+ bounded contexts). Antes de alterar: `rg showSoloForteSheet` + `rg 'backgroundColor: Colors.transparent'`. Ver `.agent/AUDITORIA_REGRESSAO_IPA210.md`
- **REGRA-MAP-CHROME-1:** coluna direita do mapa travada em `kMapActionColumnBottomInset` — nunca `mapSheetChromeInsetProvider`. Ver `.agent/Prompt.md`. Host UI: `lib/ui/` (política 4A).

### O agente NÃO DEVE

- Refatorar fora do escopo definido
- Mover arquivos sem instrução explícita
- Alterar estado global sem revisão
- Criar rotas novas sem aprovação explícita
- Improvisar contratos de dados

-----

## CHECKLIST DE VALIDAÇÃO FINAL

```
[ ] arch_check.sh → Exit 0?            SIM
[ ] flutter analyze sem erros novos?    SIM
[ ] Testes passando?                    SIM
[ ] Módulos fora do escopo alterados?   NÃO
[ ] Navegação mudou?                    NÃO
[ ] Tema mudou?                         NÃO
[ ] Contrato de dados alterado?         NÃO (ou ADR criado)
[ ] Apenas o módulo alvo foi afetado?   SIM
[ ] SHA em origin/main (mergedAt)?      SIM — auto-merge armado NÃO conta (REGRA-ENTREGA-1)
```

-----

## FORMATO DE ENTREGA

- Mudanças no app → commits por módulo, PR rebaseado na `main` (REGRA-ENTREGA-1). Auto-merge armado não é entrega.
- Prompts para agente → arquivo `.md` em `prompt/`
- Documentação humana → `.md` na raiz ou `docs/`
- Prompts para agente → arquivo `.md` em `prompt/`
- Documentação humana → `.md` na raiz ou `docs/`

-----

## ADRs ATIVOS (008–050)

| ADR | Decisão |
|---|---|
| 008 | Riverpod normalization |
| 009 | relatorios/ e publicacoes/ em consultoria/ |
| 010 | FarmName proxy |
| 011 | Marketing cases |
| 012 | Módulo planos |
| 013 | relatorios/ domain (relatorios_v2) |
| 014 | Occurrence schema v14 |
| 015 | IClientLookup contract |
| 016 | Query params navegação cliente |
| 017 | clientId relatorio domain |
| 018 | consultoria/agenda/ deletado |
| 019 | Drawing client notifier |
| 020 | Visitas-consultoria contract |
| 022 | NDVI module + IFieldLookup |
| 023 | Módulo visitas |
| 024 | Visitas blindagem completa |
| 025 | Módulo map |
| 027 | Padrão visual unificado |
| 032 | Settings user profile |
| 033 | Visitas bounded context |
| 034 | reports/ deletado (ver `docs/01_BASELINE/`) |
| 035 | DT isolated marker layers |
| 036 | Bypass temporário v1.1 |
| 037 | Drawing remote store |
| 038 | IDrawingFieldWriter contract |
| 039 | IProducerInviteWriter contract |
| 040 | IProducerPropertyGateway |
| 041 | IOccurrenceAccessReader |
| 042 | NDVI ChainedFieldLookup + cache + fetch lazy |
| 043 | IRadarOverlayController (radar RainViewer) |
| 044 | Whitelist oficial de StateNotifier/ChangeNotifier legados |
| 045 | Contratos NDVI e visita ativa |
| 046 | Contratos Agenda AI |
| 047 | OccurrenceSummary campos ricos (IReportWriter) |
| 048 | Agenda session mirror visit sessions |
| 049 | IDrawingFieldWriter.linkFieldToFarm |
| 050 | IMarketingCaseReportsLookup (consultoria ↔ marketing) |

Detalhes: `docs/02_ARQUITETURA_ATIVA/ADR-*.md`

-----

## HIERARQUIA DE AUTORIDADE (conflito entre docs)

1. `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
2. `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`
3. ADRs em `docs/02_ARQUITETURA_ATIVA/`
4. Este `AGENTS.md`
5. `lib/**/AGENTS.md` do módulo afetado
6. `docs/03_ENFORCEMENT/enforcement-rules.md` + `docs/03_ENFORCEMENT/supervisor-merge-gate.md`

### O que ler (índice operacional)

| Precisa de… | Ler |
|---|---|
| Verdade do produto / proibições | Este `AGENTS.md` |
| Memória operacional (sync, IPA, preferências) | `.agent/AGENT_MEMORIA.md` (**canônico**) |
| Regras de execução do agente | `.agent/AGENT_REGRAS.md` (**canônico**) |
| Sheets / chrome mapa (anti-regressão) | `.agent/AUDITORIA_REGRESSAO_IPA210.md` · `.agent/Prompt.md` · `design/sheets.md` |
| Fronteira Map-First (`ui/` vs `modules/map`) | Este `AGENTS.md` → “Fronteira Map-First (política 4A)” · `lib/ui/AGENTS.md` · `lib/modules/map/AGENTS.md` |
| Cadeado de merge / papéis dos agentes | `docs/03_ENFORCEMENT/supervisor-merge-gate.md` · `.cursor/rules/soloforte-supervisor.mdc` |
| Workflow Cursor (executor) | `.cursor/skills/soloforte-task/SKILL.md` |
| IPA / archive | `AGENTIPA.md` |

**Não usar como verdade ativa:** `PROJECT_RULES.md`, cópias em `prompt/AGENT_*.md` (stubs), auditorias em `docs/05_HISTORICO/`, snapshots antigos com schema v40.

**Canônico de memória/regras:** `.agent/AGENT_*` vence. `prompt/AGENT_*` só redireciona.

-----

## PRINCÍPIOS NÃO NEGOCIÁVEIS

> Zero achismo. Zero dado inventado. Zero refatoração oportunista.
> Arquitetura > rapidez. Contrato > UI. Estado previsível > mágica.
