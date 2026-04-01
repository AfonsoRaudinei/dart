# ADR-023 — Módulo `visitas/` — Bounded Context Formal

**Data:** 01/04/2026
**Branch:** release/v1.1
**Status:** APROVADO — com dívidas técnicas registradas
**Autor:** Engenheiro Sênior SoloForte
**Tipo:** FORMALIZAÇÃO DE BOUNDED CONTEXT EXISTENTE
**Altera fronteira entre módulos?** NÃO — documenta o existente e registra violações
**Altera contrato de interface?** NÃO — expansão de contrato é ADR-023-a (PROMPT 03)
**arch_check.sh:** EXIT 0 — mas ponto cego confirmado (ver seção 7)

---

## 1. Contexto

O módulo `visitas/` existe em produção e é responsável pelo ciclo de
check-in/check-out de visitas técnicas em campo. `VisitSession` é consumida
por múltiplos módulos. O ADR-020 cobriu parcialmente os contratos entre
`visitas/` e `consultoria/`, mas nunca houve ADR declarando o bounded context
completo, as violações remanescentes e o ponto cego do CI.

Este ADR corrige essa lacuna sem alterar código existente.

---

## 2. Responsabilidade do Módulo

**Natureza:** Execução de sessão de visita em campo
**Bounded context:** `visitas/`
**Entidade central:** `VisitSession`

Responsabilidades declaradas:
- Iniciar sessão de visita (check-in)
- Encerrar sessão de visita (check-out)
- Rastrear estado da sessão (`active` | `finished`)
- Geofencing associado à sessão
- Estatísticas da sessão
- Sincronização offline-first via `visit_sync_service.dart`

---

## 3. Estrutura Real (confirmada pelo PROMPT 01)

```
lib/modules/visitas/
├── data/
│   └── repositories/
│       ├── visit_repository.dart
│       └── visit_sync_service.dart
├── domain/
│   └── models/
│       ├── geofence_state.dart
│       ├── visit_session.dart
│       └── visit_stats.dart
├── infra/
│   └── visit_session_lookup_adapter.dart   ← ADR-020, parcialmente implementado
└── presentation/
    ├── controllers/
    │   ├── geofence_controller.dart
    │   ├── visit_controller.dart
    │   └── visit_stats_controller.dart
    └── widgets/
        └── visit_sheet.dart
```

---

## 4. Contrato de `VisitSession` (campos reais)

```dart
class VisitSession {
  final String id;           // required
  final String producerId;   // required
  final String? areaId;      // nullable
  final String? activityType; // nullable
  final DateTime startTime;  // required
  final DateTime? endTime;   // nullable
  final double initialLat;   // required
  final double initialLong;  // required
  final String status;       // 'active' | 'finished'
  final DateTime createdAt;  // required
  final DateTime updatedAt;  // required
  final int syncStatus;      // 0 = synced, 1 = pending

  // copyWith: SIM ✅
  // fromMap / toMap para SQLite: SIM ✅
  // Interface formal IVisitSession: NÃO — dívida técnica (ver seção 9)
  // @immutable / final class: NÃO — dívida técnica (ver seção 9)
}
```

---

## 5. Contratos Existentes (via core/contracts/)

| Arquivo | Status | O que expõe |
|---|---|---|
| `i_visit_session_lookup.dart` | ✅ EXISTE — incompleto | DTO com apenas 2 campos (id, status) |
| `i_visit_session_lookup_provider.dart` | ✅ EXISTE | `visitSessionLookupProvider` |
| `i_visit_client_lookup.dart` | ✅ EXISTE | Lookup de clientes para `visit_sheet.dart` |
| `i_visit_client_lookup_provider.dart` | ✅ EXISTE | Provider correspondente |

---

## 6. Consumidores e Acoplamentos

### Consumidores via contrato (✅ correto)
| Módulo | Arquivo | Consome |
|---|---|---|
| `consultoria/` | `occurrence_controller.dart` | `i_visit_session_lookup_provider` ✅ |
| `consultoria/` | `occurrence_list_sheet.dart` | `i_visit_session_lookup_provider` ✅ |

### Consumidores com import direto (⚠️ a migrar)
| Módulo | Arquivo | Importa diretamente |
|---|---|---|
| `map/` | `visit_active_card.dart` | `visit_controller.dart` ⚠️ |
| `ui/` | `map_bottom_sheet.dart` | `visit_controller.dart`, `visit_sheet.dart` ⚠️ |
| `ui/` | `private_map_screen.dart` | `geofence_controller.dart`, `visit_sheet.dart`, `visit_controller.dart` ⚠️ |
| `app/` | `sync_registration.dart` | `visit_sync_service.dart` ⚠️ |
| `main.dart` | `main.dart` | `visit_repository.dart`, `visit_session_lookup_adapter.dart` ⚠️ (bootstrap — autorizado) |

### Acoplamentos internos proibidos (❌ violação — a corrigir)
| Arquivo em visitas/ | Importa de | Tipo |
|---|---|---|
| `visit_controller.dart` | `consultoria/occurrences/data/occurrence_repository.dart` | ❌ PROIBIDO |
| `visit_controller.dart` | `consultoria/reports/data/sqlite_report_repository.dart` | ❌ PROIBIDO |
| `visit_controller.dart` | `consultoria/reports/domain/report_model.dart` | ❌ PROIBIDO |
| `visit_controller.dart` | `agenda/domain/repositories/i_agenda_repository.dart` | ⚠️ via interface |
| `visit_controller.dart` | `agenda/domain/enums/event_status.dart` | ⚠️ a avaliar |
| `visit_controller.dart` | `agenda/presentation/providers/agenda_provider.dart` | ❌ PROIBIDO |
| `geofence_controller.dart` | `consultoria/clients/presentation/providers/field_providers.dart` | ❌ PROIBIDO |
| `geofence_controller.dart` | `consultoria/services/talhao_map_adapter.dart` | ❌ PROIBIDO |
| `geofence_controller.dart` | `consultoria/clients/domain/agronomic_models.dart` | ❌ PROIBIDO |

---

## 7. Ponto Cego do CI — CRÍTICO

`arch_check.sh` verifica apenas a camada de `presentation/`.
As violações em `visit_controller.dart` (que importa `consultoria/`) e
`geofence_controller.dart` (que importa `consultoria/`) NÃO são detectadas
pelo CI atual. O PROMPT 05 adiciona regras ao `arch_check.sh` para cobrir
este ponto cego.

---

## 8. Fronteiras Declaradas

| Direção | Status |
|---|---|
| `visitas/` → `consultoria/` | ❌ PROIBIDO — violações ativas (ver seção 6) |
| `visitas/` → `drawing/` | ❌ PROIBIDO |
| `visitas/` → `agenda/` (direto) | ❌ PROIBIDO — usar contratos |
| `agenda/` → `visitas/` | ✅ PERMITIDO (`StartEventUseCase` cria `VisitSession`) |
| `operacao/` → `visitas/` | ✅ PERMITIDO |
| `map/` → `visitas/` via contratos | ✅ PERMITIDO |
| `map/` → `visitas/` direto | ⚠️ A MIGRAR — ver seção 6 |
| `consultoria/` → `visitas/` via `core/contracts/` | ✅ PERMITIDO |

---

## 9. Dívidas Técnicas Registradas

| # | Item | Risco | Prompt responsável |
|---|---|---|---|
| DT-023-1 | `VisitSessionSummary` com apenas 2 campos — insuficiente | Alto | ✅ RESOLVIDO — PROMPT 03 |
| DT-023-2 | `IVisitSessionLookup` sem `findById()` | Médio | ✅ RESOLVIDO — PROMPT 03 |
| DT-023-3 | `visit_controller.dart` importa 3 arquivos de `consultoria/` diretamente | Alto | ⏳ PENDENTE → ADR-024 (exceção CI autorizada) |
| DT-023-4 | `geofence_controller.dart` importa 3 arquivos de `consultoria/` diretamente | Alto | ⏳ PENDENTE → ADR-024 (exceção CI autorizada) |
| DT-023-5 | `map/` e `ui/` importam `visitas/` diretamente (sem contratos) | Médio | PROMPT 04 |
| DT-023-6 | `arch_check.sh` sem cobertura da camada de dados | Alto | ✅ RESOLVIDO — PROMPT 05 |
| DT-023-7 | `VisitSession` não é `@immutable` / `final class` | Baixo | ADR futuro |
| DT-023-8 | Geofence duplicado em `visitas/` e `operacao/` | Médio | ADR futuro |

---

## 10. Plano de Execução

| Prompt | Ação | Impacto em código |
|---|---|---|
| PROMPT 03 | Expandir `VisitSessionSummary` + adicionar `findById` | Somente `core/contracts/` + `visitas/infra/` |
| PROMPT 04 | Corrigir violações em `visit_controller` e `geofence_controller` via contratos | `visitas/` apenas |
| PROMPT 05 | Adicionar regras ao `arch_check.sh` cobrindo camada de dados | `tool/arch_check.sh` |
| PROMPT 06 | Auditoria de conformidade total | READ-ONLY |

---

## 11. O que NÃO muda neste ADR

- Nenhum arquivo `.dart` foi alterado
- Nenhuma fronteira nova foi criada
- Contratos de outros módulos não foram alterados

> **Nota (PROMPT 05):** `tool/arch_check.sh` foi alterado para adicionar REGRA-VISITAS-1/2/3.
> DT-023-3 e DT-023-4 permanecem como dívidas ativas com exceção CI autorizada — aguardam ADR-024.
