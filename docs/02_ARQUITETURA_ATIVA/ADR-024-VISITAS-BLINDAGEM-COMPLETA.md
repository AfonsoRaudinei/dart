# ADR-024 — `visitas/` — Blindagem completa: resolução DT-023-3 e DT-023-4

**Data:** 01/04/2026
**Branch:** release/v1.1
**Commit:** 74d301e
**Status:** FECHADO — ciclo completo executado e auditado
**Autor:** Engenheiro Sênior SoloForte
**Tipo:** MIGRAÇÃO DE CONTRATOS — resolução de dívidas técnicas registradas em ADR-023
**Altera fronteira entre módulos?** NÃO — reforça as fronteiras existentes
**Altera contrato de interface?** SIM — expansão de `IFieldLookup` (geometry + listAll())
**arch_check.sh:** EXIT 0 — sem exceções autorizadas (DT-023-3 e DT-023-4 pagas)

---

## 1. Contexto

ADR-023 registrou 8 dívidas técnicas no módulo `visitas/`. DT-023-3 e DT-023-4
eram as únicas com exceções autorizadas no CI (`arch_check.sh`) e bloqueavam
a blindagem completa do bounded context:

- **DT-023-3:** `visit_controller.dart` importava 3 arquivos de `consultoria/`
  e 3 de `agenda/presentation/` diretamente.
- **DT-023-4:** `geofence_controller.dart` importava 3 arquivos de `consultoria/`
  diretamente (incluindo `TalhaoMapAdapter` e `agronomic_models.dart`).

Este ADR descreve o ciclo de 7 prompts que resolveu ambas as dívidas.

---

## 2. Decisão

Substituir todos os imports ilegais por contratos neutros em `core/contracts/`,
com adaptadores isolados em cada módulo de origem. O padrão DIP já adotado em
ADR-020 foi estendido para cobrir os casos restantes.

**Princípio:** `visitas/` NUNCA importa `consultoria/`, `agenda/` ou `drawing/`
diretamente. Todo acesso externo ocorre via interface declarada em `core/contracts/`.

---

## 3. Artefatos Criados

### 3.1 Contratos neutros — `lib/core/contracts/`

| Arquivo | Contrato | DTO |
|---|---|---|
| `i_occurrence_read.dart` | `IOccurrenceRead.getBySessionId()` | `OccurrenceSummary` |
| `i_occurrence_read_provider.dart` | Provider neutro | — |
| `i_visit_report_repository.dart` | `IVisitReportRepository.saveVisitReport()` | `VisitReportData` |
| `i_visit_report_provider.dart` | Provider neutro | — |
| `i_agenda_session_bridge.dart` | `IAgendaSessionBridge.linkSessionToEvent() + markEventAsDone()` | — |
| `i_agenda_session_bridge_provider.dart` | Provider neutro | — |
| `i_field_lookup_geofence_provider.dart` | Provider neutro separado de `iFieldLookupProvider` | — |
| `i_field_lookup.dart` (expandido) | + `geometry: String?` + `listAll()` | `FieldSummary` |

### 3.2 Adaptadores — módulos de origem

| Arquivo | Localização | Implementa |
|---|---|---|
| `occurrence_read_adapter.dart` | `consultoria/occurrences/infra/` | `IOccurrenceRead` |
| `visit_report_adapter.dart` | `consultoria/reports/infra/` | `IVisitReportRepository` |
| `agenda_session_bridge_adapter.dart` | `agenda/infra/` | `IAgendaSessionBridge` |
| `field_lookup_geofence_adapter.dart` | `consultoria/fields/infra/` | `IFieldLookup` (geofence) |

### 3.3 Migrações — `visitas/`

| Arquivo | Antes | Depois |
|---|---|---|
| `visit_controller.dart` | 6 imports ilegais (3× consultoria/, 3× agenda/) | 0 imports ilegais |
| `geofence_controller.dart` | 3 imports ilegais (consultoria/) + `TalhaoMapAdapter` | 0 imports ilegais; adapter inlinado como funções puras |

### 3.4 Correção de efeito colateral

| Arquivo | Problema | Solução |
|---|---|---|
| `kpi_controller.dart` | Reexportava `sqliteReportRepositoryProvider` de `visitas/` via `show` | Provider relocalizado para `consultoria/reports/presentation/controllers/` |

### 3.5 Testes

| Arquivo | Cobertura |
|---|---|
| `test/modules/visitas/visit_controller_test.dart` | 3 cenários com 4 fakes — startSession, startSession com sessão ativa, endSession |
| `test/modules/ndvi/ndvi_repository_fetch_test.dart` | `FakeFieldLookup.listAll()` adicionado — 12/12 ✅ |

---

## 4. Registro de Overrides — `lib/main.dart`

Todos os providers neutros recebem implementação concreta via `ProviderScope.overrides`:

```dart
occurrenceReadProvider.overrideWithValue(OccurrenceReadAdapter(OccurrenceRepository()))
visitReportProvider.overrideWithValue(VisitReportAdapter(SQLiteReportRepository()))
agendaSessionBridgeProvider.overrideWithValue(AgendaSessionBridgeAdapter(AgendaRepository()))
iFieldLookupGeofenceProvider.overrideWithValue(FieldLookupGeofenceAdapter(FieldRepository()))
```

---

## 5. Resultado dos Gates de Qualidade

| Gate | Resultado |
|---|---|
| `flutter analyze lib/` | 0 `error •`, 0 `warning •` (66 `info` pré-existentes) |
| `bash tool/arch_check.sh` | ✅ APROVADO — Exit 0 — REGRA-VISITAS-1/2/3 sem exceções |
| `flutter test test/modules/visitas/` | 3/3 ✅ |
| `flutter test test/modules/consultoria/` | 69/69 ✅ |
| `flutter test test/modules/ndvi/` | 12/12 ✅ |
| `flutter test test/modules/drawing/` | 254/257 — 3 falhas em `async_geometry_service_test.dart` pré-existentes (commit `eafe0f1`) |

---

## 6. Dívidas Técnicas — Situação Final (ADR-023 §9)

| Dívida | Status |
|---|---|
| DT-023-1: DTO com 2 campos | ✅ Resolvido — ADR-023 ciclo `visitas/` PROMPT 03 |
| DT-023-2: sem `findById()` | ✅ Resolvido — ADR-023 ciclo `visitas/` PROMPT 03 |
| DT-023-3: `visit_controller.dart` imports `consultoria/` | ✅ **Resolvido — ADR-024 PROMPT 06** |
| DT-023-4: `geofence_controller.dart` imports `consultoria/` | ✅ **Resolvido — ADR-024 PROMPT 06** |
| DT-023-5: `map/` e `ui/` importam `visitas/` diretamente | ⏳ Pendente — próximo ciclo ADR |
| DT-023-6: ponto cego CI | ✅ Resolvido — ADR-023 ciclo `visitas/` PROMPT 05 |
| DT-023-7: `VisitSession` não `@immutable` | ⏳ Pendente — ADR futuro |
| DT-023-8: Geofence duplicado `operacao/` vs `visitas/` | ✅ Resolvido — legado `operacao/` removido |

---

## 7. O que NÃO foi alterado

- Nenhuma fronteira de domínio nova foi criada
- `VisitSession` (entidade central) inalterada
- Comportamento de runtime idêntico — apenas a camada de injeção mudou
- `arch_check.sh` mantém todas as REGRAS 1/2/3; apenas as exceções DT-023-3/4 foram removidas

---

## 8. Próximo ciclo recomendado

**Módulo alvo:** `map/` — maior superfície de acoplamento do projeto.

`map/` referencia `visitas/`, `consultoria/`, `drawing/` e `agenda/` sem contratos
formais. É o God Module de apresentação da v1.1 e o maior risco arquitetural aberto.

Ação recomendada: ADR-025 declarando o bounded context de `map/` e iniciando
ciclo de blindagem equivalente ao ADR-023/024.
