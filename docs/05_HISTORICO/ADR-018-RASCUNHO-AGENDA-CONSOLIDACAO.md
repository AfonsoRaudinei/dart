# ADR-018 — Consolidação do Módulo Agenda

**Status:** ✅ EXECUTADO  
**Data rascunho:** 7 de março de 2026  
**Data execução:** 7 de março de 2026  
**Módulos afetados:** `lib/modules/agenda/` · ~~`lib/modules/consultoria/agenda/`~~ (deletado)  
**Risco:** Alto  
**Autor:** Diagnóstico automatizado — Engenheiro Sênior Flutter/Dart

### Resumo da execução

| Passo | Ação | Resultado |
|-------|------|-----------|
| 1 | `getEventBySessionId` adicionado em `IAgendaRepository`, `AgendaRepository` e `FakeAgendaRepository` | ✅ 67/67 testes verdes |
| 2 | `visit_controller.dart` migrado — 3 imports legacy removidos, `getEvent` → `getEventById`, `AgendaStatus` → `EventStatus` | ✅ 0 erros |
| 3 | `lib/modules/consultoria/agenda/` deletado (3 arquivos) | ✅ sem referências órfãs |
| 4 | Validação global | ✅ 0 erros de compilação, 67 testes passando |

---

## 1. Diagnóstico

### `lib/modules/agenda/` — Módulo Principal (48 arquivos)

**Use cases (6):**
- `cancel_event_use_case.dart`
- `complete_event_use_case.dart`
- `create_event_use_case.dart`
- `finalize_event_use_case.dart`
- `start_event_use_case.dart`
- `update_event_use_case.dart`

**Entidades de domínio (4):**
- `Event` — entidade principal com `EventStatus` (PT: agendado/emAndamento/finalizando/concluido/cancelado), `EventType`, campos offline (`syncStatus: String`), `VisitPriority`, coordenadas opcionais
- `EventRecurrence` — recorrência futura
- `Visit` — visita associada ao evento
- `VisitSession` — sessão de visita criada ao iniciar o evento

**Enums:** `AgendaView`, `EventStatus`, `EventType`, `RecurrencePattern`

**Interface DIP:** `IAgendaNotificationService` (em `domain/services/`) — consumida por `create_event_use_case`, `update_event_use_case`, `cancel_event_use_case`

**Repositório:** `IAgendaRepository` (interface) + `AgendaRepository` (impl) — usa tabela `agenda_events` no schema **v10** (colunas novas)

**Providers (2):**
- `agendaProvider` — provider principal (Riverpod)
- `agendaFiltersProvider`

**Páginas (3):** `AgendaDayPage`, `AgendaMonthPage`, `AgendaEventDetailPage`

**Views (4):** `AgendaCalendarioView`, `AgendaClientesView`, `AgendaIndicadoresView`, `AgendaPlanejamentoView`

**Widgets (10+):** create dialog, day card, month grid, status badge, unsaved changes, visit form, etc.

**Testes (67 = 6 arquivos × média 11):**
| Arquivo | Testes |
|---|---|
| `create_event_use_case_test.dart` | 12 |
| `start_event_use_case_test.dart` | 13 |
| `complete_event_use_case_test.dart` | 13 |
| `finalize_event_use_case_test.dart` | 10 |
| `detect_conflicts_use_case_test.dart` | 10 |
| `schedule_notifications_use_case_test.dart` | 9 |
| **Total** | **67** |

Helpers de teste: `FakeAgendaRepository`, `FakeNotificationService`

**Rota registrada:** `AppRoutes.agenda = '/agenda'` — `app_router.dart` importa `AgendaMonthPage`, `AgendaDayPage`, `AgendaEventDetailPage` diretamente deste módulo.

**Consumidores externos do módulo principal:**
- `lib/ui/screens/private_map_screen.dart` (agendaProvider)
- `lib/ui/screens/private_map_sheets.dart` (agendaProvider)
- `lib/modules/operacao/presentation/controllers/geofence_controller.dart` (agendaProvider)
- `lib/modules/map/presentation/providers/visit_completion_observer.dart` (agendaProvider)
- `lib/core/router/app_router.dart` (páginas)

---

### `lib/modules/consultoria/agenda/` — Módulo Legado (3 arquivos)

**Estrutura:**
```
consultoria/agenda/
  data/repositories/agenda_repository.dart     ← AgendaRepository (concreto, sem interface)
  domain/models/agenda_event.dart              ← AgendaEvent (model ≠ entidade)
  presentation/controllers/agenda_controller.dart ← provider + controller
```

**Entidade/Model:**
- `AgendaEvent` — model simples com `AgendaStatus` (EN: planned/in_progress/realized/cancelled), campo `syncStatus: int` (legado), colunas da tabela **v5** (`producer_id`, `area_id`, `activity_type`, `scheduled_date`)
- `AgendaStatus` — enum inglês com `in_progress` (snake_case explícito por compatibilidade)

**Repositório:** `AgendaRepository` (sem interface, concreto direto) — usa tabela `agenda_events` com **schema v5** (colunas antigas: `producer_id`, `area_id`, `activity_type`, `scheduled_date`)

**Providers (2, sem `@riverpod`):**
- `agendaRepositoryProvider` — `Provider<AgendaRepository>`
- `plannedEventsProvider` — `FutureProvider.family.autoDispose<List<AgendaEvent>, ({String producerId, String areaId})>`
- `agendaControllerProvider` — `Provider<AgendaController>`

**Use cases formais:** Nenhum. Toda lógica está em `AgendaController.createFollowUpEvent()`.

**IAgendaNotificationService:** Não existe neste módulo.

**Testes:** Nenhum.

**Consumidor externo único:**
- `lib/modules/visitas/presentation/controllers/visit_controller.dart` — usa:
  - `AgendaRepository.getEvent(id)` (linha 106)
  - `AgendaRepository.saveEvent(event)` (linhas 108, 193)
  - `AgendaRepository.getEventBySessionId(sessionId)` (linha 189)
  - `AgendaStatus.in_progress` (linha 111)
  - `AgendaStatus.realized` (linha 194)
  - `agendaRepositoryProvider` (linha 27)

**Rota:** Nenhuma. Nenhuma tela registrada no `app_router.dart`.

---

## 2. Sobreposições Identificadas

| Elemento | `modules/agenda/` | `consultoria/agenda/` | Tipo de Conflito |
|---|---|---|---|
| Classe `AgendaRepository` | ✅ Impl completa, schema v10 | ✅ Impl simples, schema v5 | **MESMO NOME, schemas divergentes** |
| Tabela SQLite `agenda_events` | ✅ Schema v10 (9 colunas novas) | ⚠️ Schema v5 (colunas antigas) | **ESQUEMA INCOMPATÍVEL** — ambos escrevem na mesma tabela |
| Entidade de evento | `Event` (Equatable, offline-first) | `AgendaEvent` (model simples, syncStatus: int) | Semântica distinta — não são equivalentes |
| Status do evento | `EventStatus` (PT, enum rico) | `AgendaStatus` (EN, enum simples) | **DUPLICADO**, mapeamento necessário |
| Providers | `agendaProvider` (@riverpod) | `agendaRepositoryProvider`, `plannedEventsProvider` (Provider legado) | Padrão divergente (ADR-008) |

### ⚠️ Risco Crítico Identificado — Corrupção de Dados

O **`consultoria/agenda/AgendaRepository`** usa as colunas antigas (`producer_id`, `area_id`, `activity_type`, `scheduled_date`) que foram **destruídas e substituídas** pela migração `_migrateToV10`. Qualquer `saveEvent` pelo módulo legado falhará em runtime com `DatabaseException: table agenda_events has no column named producer_id` em dispositivos com schema ≥ v10.

Isso confirma que o módulo legado está **efetivamente quebrado em produção** (DB v12), sendo mantido apenas por continuidade de código sem execução real.

---

## 3. Decisão Recomendada

### ✅ OPÇÃO A — Manter apenas `modules/agenda/` + migrar o único consumidor

**Justificativa:**
1. `modules/agenda/` tem 6 use cases formais, DIP completo (`IAgendaNotificationService`, `IAgendaRepository`), 67 testes cobrindo casos de negócio, 48 arquivos com arquitetura Clean, schema correto (v10) e é a fonte de verdade do `app_router.dart`.
2. `consultoria/agenda/` tem **zero testes**, **zero use cases formais**, **schema incompatível com DB v10–v12**, e apenas **1 consumidor externo** (`visit_controller.dart`).
3. O único trabalho real de migração é substituir 3 chamadas no `visit_controller.dart` de `AgendaRepository` (legado) para o repositório do módulo principal.
4. `AgendaStatus.in_progress` e `AgendaStatus.realized` precisam ser mapeados para `EventStatus.emAndamento` e `EventStatus.concluido` do módulo principal.

**Opção B** é descartada: `consultoria/agenda/` não tem use cases, testes nem DIP.  
**Opção C** é desnecessária: `modules/agenda/` já tem a estrutura limpa desejada.

---

## 4. Plano de Execução (para PROMPT 02b — não executar agora)

**Pré-requisito:** Aprovação formal deste ADR.

**Passo 1 — Ampliar `IAgendaRepository` se necessário**  
Verificar se `getEventBySessionId(String sessionId)` existe na interface `IAgendaRepository`. Se não, adicionar na interface e na implementação concreta.

**Passo 2 — Migrar `visit_controller.dart`**  
- Substituir imports de `consultoria/agenda/` pelos equivalentes de `modules/agenda/`
- Trocar `AgendaRepository` → repositório via `IAgendaRepository` / provider do módulo principal
- Trocar `AgendaStatus.in_progress` → `EventStatus.emAndamento`
- Trocar `AgendaStatus.realized` → `EventStatus.concluido`
- Adaptar campos do `Event` vs `AgendaEvent` (ex: `producerId`/`areaId` → `clienteId`/`fazendaId`)

**Passo 3 — Verificar `flutter analyze` + testes**  
Garantir 0 erros antes de deletar.

**Passo 4 — Deletar `lib/modules/consultoria/agenda/`**  
Remover os 3 arquivos: `agenda_event.dart`, `agenda_repository.dart`, `agenda_controller.dart`.

**Passo 5 — Verificar referências residuais**  
```bash
grep -r "consultoria/agenda" lib/ --include="*.dart"
```
Deve retornar vazio.

**Passo 6 — Rodar testes de regressão**  
```bash
flutter test test/modules/agenda/
```
Todos os 67 testes devem passar.

---

## 5. Riscos

| Risco | Probabilidade | Impacto | Mitigação |
|---|---|---|---|
| `Event` não tem `producerId`/`areaId` — campos diferentes de `AgendaEvent` | Alta | Alto | Mapear para `clienteId`/`fazendaId` no passo 2; avaliar se `visit_controller` precisa de adaptação semântica |
| `getEventBySessionId` ausente em `IAgendaRepository` | Média | Alto | Verificar e adicionar no passo 1 antes de qualquer remoção |
| `AgendaStatus.in_progress` (snake_case explícito) sem equivalente exato | Média | Médio | `EventStatus.emAndamento` é semanticamente equivalente |
| Schema v5 ainda lido em dispositivos antigos (sem migração v10) | Baixa | Alto | DB v10 faz DROP e recria — qualquer device que atualizou já tem schema novo |
| `plannedEventsProvider` (FutureProvider legado) usado em algum widget não detectado | Baixa | Médio | Re-executar grep completo no passo 2b antes de deletar |

---

## 6. Impacto em Testes

| Conjunto | Arquivos afetados | Ação necessária |
|---|---|---|
| `test/modules/agenda/use_cases/` (67 testes) | Nenhum — módulo principal não muda | Rodar como validação de regressão |
| Testes de `visitas/` | Depende da refatoração do `visit_controller` | Atualizar mocks se necessário |
| Testes de `consultoria/agenda/` | Não existem | Nada a fazer |

---

## 7. Critério de Rollback

Se qualquer etapa do PROMPT 02b falhar:
1. Reverter `visit_controller.dart` ao estado anterior via `git checkout`
2. Restaurar arquivos de `consultoria/agenda/` se já deletados via `git checkout`
3. Rodar `flutter analyze` para confirmar estado limpo
4. Reportar qual passo falhou antes de tentar novamente

O rollback é seguro porque `modules/agenda/` (módulo principal) **não é modificado estruturalmente** — apenas o `visit_controller.dart` e a deleção do legado.

---

## 8. Checklist de Aprovação (preencher antes de executar PROMPT 02b)

```
[ ] ADR-018 revisado por responsável técnico
[ ] Passo 1 viável: IAgendaRepository.getEventBySessionId confirmado ou adicionado
[ ] Mapeamento de campos AgendaEvent → Event validado semanticamente
[ ] Janela de deploy definida (evitar horário de pico)
[ ] Branch de execução criada: feature/adr-018-agenda-consolidacao
```

---

*SoloForte Baseline v1.2 — DB Schema v12 — ADR-018 RASCUNHO — 07/03/2026*
