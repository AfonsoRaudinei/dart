# SoloForte — Architectural Baseline v1.1
## Score Estrutural 90/100

---

## 1. Identificação

| Campo | Valor |
|---|---|
| **Projeto** | SoloForte App |
| **Tecnologia** | Flutter (Dart) |
| **Arquitetura** | Modular, Clean Architecture, Map-First |
| **Versão arquitetural** | v1.1 |
| **Score estrutural estimado** | 90–91/100 |
| **Data de congelamento** | 22 de fevereiro de 2026 |
| **Branch** | `release/v1.1` |
| **Commit hash** | `0eb0975c06b4331e937947ef921067c11d42bbaa` |
| **Tag oficial** | `ARCH_BASELINE_v1.1_SCORE_90` |

---

## 2. Métricas Estruturais Reais

| Métrica | Valor |
|---|---|
| Arquivos Dart em `lib/` | 233 |
| Providers | 82 |
| TODOs em produção | 36 |
| Interfaces formais (DIP) | ≥ 5 |
| Use cases Agenda | 6 |
| Testes Agenda | 74 |
| Testes Drawing | 36 |
| Violação `core → modules` | 0 |
| Módulos zumbi | 0 |
| Erros `flutter analyze` | 0 |
| Enforcement CI ativo | SIM |
| Arquivos >900 linhas | 4 legados (WARN controlado) |

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

### Settings / Auth
Módulos satélite sem dependências cruzadas.

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
| 4 arquivos legados >900 linhas | Média | Monitorados em `WARN` pelo `arch_check.sh` |
| Coverage global sem gate automático | Média | Testes por módulo crítico (Drawing + Agenda) |
| Complexidade ciclomática sem CI | Baixa | Revisão manual por PR |
| Acoplamento aferido manualmente | Baixa | `arch_check.sh` cobre fronteiras principais |
| 36 TODOs em produção | Baixa | Nenhum em caminho crítico |

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

*Gerado em: 22/02/2026 | Branch: `release/v1.1` | Commit: `0eb0975` | Score: 90/100*
