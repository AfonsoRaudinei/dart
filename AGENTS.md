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
| Persistência | SQLite offline-first — schema **v40** (`database_helper.dart`) |
| Mapa | `flutter_map` — nunca `google_maps_flutter` |
| CI gate | `./tool/arch_check.sh` → Exit 0 |
| Coverage mínimo CI | 36.46% |

**Bounded contexts ativos:** `core` · `ui` · `map` · `drawing` · `agenda` · `agenda_ai` · `operacao` · `consultoria` · `visitas` · `settings` · `auth` · `planos` · `produtor` · `carteira` · `ndvi` · `marketing` · `feedback` · `dashboard` · `public` · `clima`

-----

## IDENTIDADE

Você é um Engenheiro Sênior Flutter/Dart (top 5%).
Foco: Arquitetura limpa, contratos reais, estado previsível, zero improviso.

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
consultoria/ ❌ → drawing/ ou agenda/
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
│   ├── database/          ← database_helper.dart (schema v40)
│   ├── router/            ← app_router.dart (única exceção core→modules)
│   └── state/
├── modules/
│   ├── agenda/            ← planejamento agronômico
│   ├── consultoria/       ← clientes, fazendas, talhões, ocorrências
│   │   └── relatorios/    ← ADR-013 (relatorios_v2)
│   ├── drawing/           ← geometrias, KML/KMZ
│   ├── visitas/           ← sessões de visita (ADR-023)
│   ├── produtor/          ← propriedade do produtor (ADR-039/040)
│   └── settings/
└── ui/
    ├── components/
    │   ├── app_shell.dart      ← SmartButton FAB ÚNICO
    │   └── smart_button.dart   ← NUNCA ALTERAR
    └── screens/
        └── private_map_screen.dart ← tela principal Map-First
```

**Regras por módulo:** ler `lib/modules/<modulo>/AGENTS.md` ou `lib/core/AGENTS.md` / `lib/ui/AGENTS.md`.

-----

## REGRAS DE EXECUÇÃO

### O agente DEVE

- Fazer PASSO 0 (find/rg) antes de qualquer ação
- Sugerir abordagem antes de executar em mudanças estruturais
- Declarar bounded context antes de qualquer mudança
- Respeitar `kFabSafeArea = 100dp` em layouts com scroll
- Rodar `arch_check.sh` ao final e confirmar Exit 0

### Padrão de bottom sheets

- Wrapper padrão: `lib/core/ui/sheets/soloforte_sheet.dart`
- Tokens visuais: `lib/core/ui/sheets/sheet_tokens.dart`
- Não duplicar handles, títulos ou botões de fechar fora do padrão

### O agente NÃO DEVE

- Refatorar fora do escopo definido
- Mover arquivos sem instrução explícita
- Alterar estado global sem revisão
- Criar rotas novas sem aprovação explícita
- Improvisar contratos de dados

-----

## CHECKLIST DE CONCLUSÃO DE TAREFA (obrigatório antes de commit)

O agente **DEVE** colar este bloco no chat ao encerrar a implementação,
**antes** de `git commit` / `git push` / IPA. Marcar cada item com ✅ ou ❌
e evidência (comando ou `arquivo:linha`). Se algum ❌ crítico (arch_check,
analyze, testes do escopo, contrato), **parar e corrigir** — não commitar.

```
### Checklist de conclusão
| # | Critério | Status | Evidência |
|---|---|---|---|
| 1 | Escopo declarado (módulo / BC / arquivos) respeitado | ✅/❌ | … |
| 2 | PASSO 0 feito (find/rg) | ✅/❌ | … |
| 3 | arch_check.sh Exit 0 | ✅/❌ | … |
| 4 | flutter analyze sem erro novo no escopo | ✅/❌ | … |
| 5 | Testes do escopo verdes | ✅/❌ | … |
| 6 | Navegação Map-First intacta (sem pop/sub-rota /map) | ✅/❌ | … |
| 7 | Sem google_maps_flutter / FAB local / smart_button | ✅/❌ | … |
| 8 | Sem dados fictícios / hard delete sync | ✅/❌ | … |
| 9 | Agentrevisor (DIFF) sem P0/P1 aberto | ✅/❌ | … |
| 10 | Pronto para commit | ✅/❌ | … |
| 11 | Pronto para IPA (só se pedido) | ✅/❌/N/A | … |

Veredito: 🟢 COMMIT OK | 🟡 AJUSTAR | 🔴 BLOQUEADO
```

**Regra:** commit só com Veredito 🟢. IPA só se item 11 = ✅ e AGENTIPA seguido.

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
[ ] Checklist de conclusão colado no chat antes do commit? SIM
```

-----

## FORMATO DE ENTREGA

- Mudanças no app → commits por módulo, PR com descrição de escopo
- Prompts para agente → arquivo `.md` em `prompt/`
- Documentação humana → `.md` na raiz ou `docs/`

-----

## ADRs ATIVOS (008–043)

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

Detalhes: `docs/02_ARQUITETURA_ATIVA/ADR-*.md`

-----

## HIERARQUIA DE AUTORIDADE (conflito entre docs)

1. `docs/01_BASELINE/ARCH_BASELINE_v1.1_SCORE_90.md`
2. `docs/02_ARQUITETURA_ATIVA/bounded_contexts.md`
3. ADRs em `docs/02_ARQUITETURA_ATIVA/`
4. Este `AGENTS.md`
5. `lib/**/AGENTS.md` do módulo afetado
6. `docs/03_ENFORCEMENT/enforcement-rules.md`

-----

## PRINCÍPIOS NÃO NEGOCIÁVEIS

> Zero achismo. Zero dado inventado. Zero refatoração oportunista.
> Arquitetura > rapidez. Contrato > UI. Estado previsível > mágica.
