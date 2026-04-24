# SoloForte — Architectural Baseline v1.1
## Score Estrutural 90/100

---

## 1. Identificação

| Campo | Valor |
|---|---|
| **Projeto** | SoloForte App |
| **Tecnologia** | Flutter (Dart) |
| **Arquitetura** | Modular, Clean Architecture, Map-First |
| **Versão arquitetural** | v1.2 |
| **Última atualização** | 28/02/2026 |
| **Módulos registrados** | core, map, drawing, agenda, operacao, consultoria, settings, auth, marketing, planos |
| **Score estrutural estimado** | 90–91/100 |
| **Data de congelamento** | 22 de fevereiro de 2026 |
| **Branch** | `release/v1.1` |
| **Commit hash** | `0eb0975c06b4331e937947ef921067c11d42bbaa` |
| **Tag oficial** | `ARCH_BASELINE_v1.1_SCORE_90` |

---

## 2. Métricas Estruturais Reais

| Métrica | Valor |
|---|---|
| Arquivos Dart em `lib/` | **436** |
| Providers keepAlive | **21** |
| TODOs em produção | **45** |
| Interfaces formais (DIP) | **26** |
| Testes verdes | **612** (2 falhas pré-existentes em drawing — não relacionadas à Sessão 3) |
| Violação `core → modules` | 0 |
| Módulos zumbi | 0 |
| Erros `flutter analyze` | **0** |
| Enforcement CI ativo | SIM |
| Arquivos >900 linhas | **5** legados (WARN controlado — inclui `database_helper.dart`) |
| Schema DB | `soloforte.db` v29 (banco único) |
| ADRs confirmados no código | 12 (ADR-007 a ADR-022) |

---

## 3. Fronteiras Arquiteturais Oficiais

Automaticamente validadas por `tool/arch_check.sh` (CI: `.github/workflows/architecture.yml`).

### Regra 1 — Core isolado
`lib/core/**` **NÃO** pode importar `lib/modules/**`.

**Exceção documentada:**
- `app_router.dart` — permitido por design (composição de rotas)

### Regra 2 — Bloqueio de acoplamento lateral

| Direção | Status |
|---|---|
| `drawing → consultoria` | ❌ PROIBIDO |
| `agenda → consultoria` | ❌ PROIBIDO |
| `consultoria → drawing` | ❌ PROIBIDO |
| `operacao → consultoria` | ✅ Permitido (dependência semântica válida) |

**Solução aplicada para `drawing × consultoria`:**
`ClientsRepositoryAdapter` vive em `drawing/infra/` e serve como única ponte autorizada, sem violar nenhuma direção proibida.

### Regra 3 — Limite de crescimento estrutural

- Arquivos novos não podem exceder **900 linhas**
- 4 arquivos legados marcados como `WARN` e monitorados
- Nenhum novo monólito é permitido

---

## 4. Bounded Context Oficial

### Core
Infraestrutura horizontal pura. Não conhece módulos de domínio.
- `database/`, `network/`, `logger/`, `router/` (exceção de composição)

### Map
Projeção agregadora. Pode depender de: `Agenda`, `Operacao`, `Drawing`, `Consultoria`.

### Drawing
Domínio geométrico isolado.
- I/O abstraído via `IFilePicker` / `FilePickerAdapter`
- DIP aplicado: `IDrawingRepository`, `IClientsRepository`
- 5 serviços de domínio extraídos
- Controller como fachada fina (827 linhas, era 1.344)
- 36 testes estruturais

### Agenda
Domínio de planejamento.
- 6 use cases formais
- `IAgendaNotificationService` aplicado
- 74 testes estruturais
- DIP em notificações

### Operacao
Execução de visitas. Pode depender de `Agenda`.

### Consultoria
Conteúdo técnico e ocorrências. Não depende de `Drawing`.

### `ndvi/`
Módulo NDVI — análise espectral de satélite.
- `NdviPanelWidget` — 444 linhas, consome provider real, 0 TODOs internos
- Sem ADR formal ainda
- **Status:** ✅ IMPLEMENTADO (confirmado auditoria 23/03/2026)

### `drawing/` — GPS Walk
Gravação de rota por GPS integrada ao módulo drawing.
- `gps_walk_session.dart`, `gps_walk_controller.dart` (184 linhas)
- `gps_walk_providers.dart`, `gps_walk_metrics_bar.dart`
- `gps_walk_bottom_bar.dart`, `gps_walk_controls_overlay.dart`
- Sem ADR formal ainda
- **Status:** ✅ IMPLEMENTADO (confirmado auditoria 23/03/2026)

### `marketing/`
Casos de marketing com visualização no mapa.
- PASSO 6: long press → `NovoCaseSheet` (em `private_map_screen.dart` + `private_map_sheets.dart`) ✅
- PASSO 7: pins no mapa via `isolated_marker_layers.dart` + `marketingCasesProvider` ✅

### `consultoria/occurrences/` — vínculo opcional de cliente
- Schema v28: coluna nullable `client_id` em `occurrences`
- Modelo `Occurrence` atualizado com `clientId` (`toMap`/`fromMap`/`copyWith`)
- Sync Supabase atualizado (`client_id` no upsert/pull)
- UI de criação com seletor opcional via `IClientLookup`
- Novo arquivo: `lib/modules/consultoria/occurrences/presentation/widgets/occurrence_client_selector.dart`

### `carteira/` — atualização de schema v29
- Schema v29: coluna nullable `closed_percent` em `carteira_lancamentos`

### Settings / Auth
Módulos satélite sem dependências cruzadas.

### `planos/`
**Natureza:** Módulo de monetização — folha na árvore de dependências  
**Responsabilidade:** Planos pagos (Bronze/Prata/Ouro), pagamentos via Mercado Pago (PIX + Cartão), sistema de indicações com upgrade automático e controle de visibilidade de marketing cases no mapa  
**Stack:** Supabase (fonte da verdade remota) + Edge Functions Deno/TS  
**Acoplamentos de entrada:** `marketing/` (verifica plano), `map/` (badge SideMenu)  
**Acoplamentos de saída:** nenhum — não depende de outros módulos  
**ADR:** ADR-012-MODULO-PLANOS  
**Status:** IMPLEMENTADO — v1.2  

---

## 5. Garantias Arquiteturais

| Garantia | Status |
|---|---|
| Enforcement CI ativo bloqueando regressão estrutural | ✅ |
| DIP aplicado em Drawing (repo + file picker + clients) | ✅ |
| DIP aplicado em Agenda (notificações) | ✅ |
| I/O abstraído via interfaces | ✅ |
| God Object DrawingController decomposto | ✅ |
| Agenda coberta por testes de domínio | ✅ |
| Nenhuma violação de dependência lateral | ✅ |
| Nenhuma dependência circular detectada | ✅ |
| Zero erros de compilação | ✅ |
| repairOrphanUserIds implementado | ✅ |
| Logout seguro (clear→invalidate→signOut) | ✅ |
| .baseline_marker criado | ✅ |
| Isolamento user_id em 6 repositórios | ✅ |
| GPS Walk implementado | ✅ |
| NDVI Panel implementado | ✅ |
| Marketing PASSO 6+7 implementados | ✅ |

---

## 6. Estado do Módulo Drawing

### Antes da FASE C
- 1.344 linhas no `DrawingController`
- 7 responsabilidades acopladas
- ~15% coberto por testes
- Dependências concretas hardcoded (`FilePicker.platform`, `DrawingRepository()`, `ClientsRepository`)

### Após FASE C

| Componente | Descrição |
|---|---|
| `DrawingController` | Fachada fina com 827 linhas |
| `DrawingFeatureCrudService` | Lógica pura de CRUD (`const`, zero I/O) |
| `DrawingVertexEditService` | Operações imutáveis de vértice |
| `DrawingBooleanOpsService` | Union / difference / intersection |
| `DrawingImportService` | KML/KMZ via `IFilePicker` |
| `DrawingClientFarmBridgeService` | Bridge via `IClientsRepository` |
| `ClientsRepositoryAdapter` | Adapter em `drawing/infra/` — única ponte autorizada |
| Testes | 36 casos, 36/36 verdes |
| Cobertura de domínio | ~60–70% |

---

## 7. Estado do Módulo Agenda

| Componente | Descrição |
|---|---|
| `CreateEventUseCase` | Validação, conflito, persist, notificação |
| `StartEventUseCase` | `agendado → emAndamento`, cria `VisitSession` |
| `FinalizeEventUseCase` | `emAndamento → finalizando` |
| `CompleteEventUseCase` | `finalizando → concluido`, fecha sessão |
| `CancelEventUseCase` | Cancela sessão ativa + notificações |
| `UpdateEventUseCase` | Atualiza com re-validação |
| `IAgendaNotificationService` | Contrato de notificação (DIP) |
| `FakeAgendaRepository` | In-memory, verificação de interações |
| `FakeAgendaNotificationService` | Rastreia `scheduledIds` / `cancelledIds` |
| Testes | 74 casos, 74/74 verdes |

**Casos de borda cobertos:**
- Rollback `finalizando → emAndamento` (regra explícita de `EventRules`)
- Conflitos adjacentes — sem falso positivo
- Sessão inexistente em `completeEvent`
- Estados inválidos para todas as transições
- Ciclo `create → cancel` com rastreio de notificação

---

## 8. Riscos Remanescentes (Transparência Técnica)

| Risco | Severidade | Mitigação atual |
|---|---|---|
| 5 arquivos legados >900 linhas | Média | Monitorados em `WARN` pelo `arch_check.sh` |
| Coverage global sem gate automático | Média | Testes por módulo crítico (Drawing + Agenda) |
| Complexidade ciclomática sem CI | Baixa | Revisão manual por PR |
| Acoplamento aferido manualmente | Baixa | `arch_check.sh` cobre fronteiras principais |
| 45 TODOs em produção | Baixa | Nenhum em caminho crítico confirmado |
| 2 falhas em testes drawing (pré-existentes) | Média | Isoladas — não afetam consultoria/core |

---

## 9. Critérios que sustentam Score 90

| Critério | Evidência |
|---|---|
| Arquitetura protegida por mecanismo | CI bloqueia violações de fronteira automaticamente |
| Domínio crítico blindado por testes | 74 testes Agenda + 36 testes Drawing |
| DIP aplicado nos pontos de maior risco | Drawing (3 interfaces) + Agenda (1 interface) |
| Fronteiras documentadas e bloqueadas | `arch_check.sh` + `architecture.yml` |
| Decomposição de God Object concluída | `DrawingController`: 1.344 → 827 linhas + 5 serviços |
| Zero regressão estrutural após enforcement | `arch_check.sh` → APROVADO em todos os commits |
| Zero erros `flutter analyze` | Verificado nesta baseline |
| `planos/` é folha — não depende de módulos de domínio | ✅ |
| Edge Functions Mercado Pago deployadas em supabase/functions/ | ✅ |

---

## 10. Próximos Níveis (Pós-90)

Para evoluir além de 90, as seguintes iniciativas estão identificadas:

| Iniciativa | Impacto estimado |
|---|---|
| Coverage gate no CI (`lcov` threshold ≥ 60%) | +2 pontos |
| Complexity threshold automatizado (`dart_code_metrics`) | +1 ponto |
| Snapshot de contratos públicos (golden files) | +1 ponto |
| Dependency graph automatizado | +0,5 ponto |
| Performance profiling formal | +0,5 ponto |

---

## 11. Conclusão

O projeto SoloForte atinge nesta baseline:

- **Arquitetura madura** — fronteiras definidas, regras automatizadas
- **Fronteiras protegidas** — enforcement por CI, não por memória humana
- **Domínio crítico testado** — Drawing e Agenda com harness isolado
- **Governança ativa** — qualquer regressão estrutural é bloqueada antes do merge

Este documento define o **ponto de referência estrutural oficial** do sistema.
Qualquer evolução arquitetural deve referenciar esta baseline e justificar o delta.

---

## 12. Registro de ADRs Ativos

| ADR | Nome | Descrição | Status |
|---|---|---|---|
| ADR-007 | — | Referenciado no código | ATIVO |
| ADR-008 | RIVERPOD-PROVIDERS | Padrão de providers Riverpod | ATIVO |
| ADR-009 | RELATORIOS-OFFLINE-FIRST | Relatorios offline-first (SQLite) | ATIVO |
| ADR-010 | — | Referenciado no código | ATIVO |
| ADR-012 | MODULO-PLANOS | Monetização (Bronze/Prata/Ouro) + Mercado Pago | ATIVO |
| ADR-013 | RELATORIOS-DOMAIN | Submódulo relatorios/ dentro de consultoria/ | ATIVO |
| ADR-014 | — | Referenciado no código | ATIVO |
| ADR-015 | CLIENT-STATS-SERVICE | Agregação de stats do Hub do Cliente | ATIVO |
| ADR-016 | — | Referenciado no código | ATIVO |
| ADR-017 | — | Referenciado no código | ATIVO |
| ADR-019 | IVISIT-CLIENT-LOOKUP | Contrato visitas/consultoria via DIP | ATIVO |
| ADR-020 | CONSULTORIA-VISITAS-DECOUPLING | Acoplamento consultoria↔visitas removido | ATIVO |
| ADR-022 | — | Referenciado no código | ATIVO |

---

## 13. Issues Conhecidos (Pós-Auditoria Mar/2026)

### P1 — Alta Prioridade

| Issue | Localização | Ação |
|---|---|---|
| Sub-rota `publicacao/edit` dentro de `/map` — viola Map-First | `app_router.dart:102` | Remover GoRoute, converter para overlay |
| `visit_controller.dart` usa `AgendaRepository` concreto — ADR-018 regredido | `visitas/controllers/visit_controller.dart:38` | Migrar para `IAgendaRepository` |
| `occurrence_list_sheet.dart` importa `visitas/` diretamente — bounded context violado | `occurrence_list_sheet.dart:11` | Usar contrato em `core/contracts/` |

### P2 — Média Prioridade

| Issue | Localização | Ação |
|---|---|---|
| `relatorios/`: sem coluna `user_id` — usa `agronomist_id` como isolamento funcional | `relatorio_table.dart` | ADR futuro + migração de schema |
| `ArmedMode` vs `MapContext`: divergência entre código e contrato documentado | `private_map_screen.dart:65` | Alinhar nome via ADR ou atualizar contrato |
| 3 FABs no `map_controls_overlay` — viola contrato FAB único | `map_controls_overlay.dart` | Refatorar para SmartButton único |
| 2 falhas pré-existentes nos testes do módulo drawing | `drawing_intersection_realtime_test`, `drawing_import_service_test` | Investigar e corrigir |

### P3 — Baixa Prioridade / Backlog

| Issue | Nota |
|---|---|
| Golden de auth (`register_golden_test.dart`) com diff de pixel (fora do escopo de occurrences) | Dívida técnica conhecida — tratar em task dedicada; não atualizar golden em feature não relacionada |
| `DrawingRemoteStore` ainda stub — sync remoto de desenhos não funcional | Depende de infraestrutura de sync |
| 65 issues `flutter analyze` — todos `info`/`deprecated_member_use` | Nenhum é erro; pré-existentes |
| 45 TODOs em produção | Nenhum em caminho crítico |

---

*Atualizado em: 24/04/2026 | Branch: `release/v1.1` | Inclui Occurrence Client Link + schema v29 | Score: 90/100*
