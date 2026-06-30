# PROMPT 02 — ADR-023: Bounded Context Formal de `visitas/`
**Agente:** Engenheiro Sênior Flutter/Dart — Modo Documentação
**Arquivo destino:** `docs/02_ARQUITETURA_ATIVA/ADR-023-MODULO-VISITAS.md`
**Tipo:** ALTERAÇÃO DOCUMENTAL — sem alteração de código Dart
**Pré-requisito:** PROMPT 01 executado — relatório disponível
**Risco:** Nenhum — apenas criação de documento

---

## OBJETIVO

Criar o ADR-023 formalizando o bounded context `visitas/` com base no estado
REAL revelado pelo PROMPT 01. Documentar violações existentes como dívida
técnica rastreável. Atualizar `bounded_contexts.md` e `00_INDEX_OFICIAL.md`.

---

## PROIBIÇÕES ABSOLUTAS

❌ Não editar nenhum arquivo `.dart`
❌ Não corrigir violações agora — apenas documentá-las
❌ Não alterar `arch_check.sh` agora — isso é PROMPT 05
❌ Não inventar campos ou dependências — usar apenas o que o PROMPT 01 revelou

---

## PASSO 0 — VERIFICAÇÃO

```bash
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-02*" | sort
find docs/02_ARQUITETURA_ATIVA/ -name "ADR-023*"
```

Confirmar que ADR-023 ainda NÃO existe antes de criar.

---

## PASSO 1 — CRIAR `ADR-023-MODULO-VISITAS.md`

Criar o arquivo em `docs/02_ARQUITETURA_ATIVA/ADR-023-MODULO-VISITAS.md`
com o conteúdo abaixo. Os campos já estão preenchidos com base no PROMPT 01.

```markdown
# ADR-023 — Módulo `visitas/` — Bounded Context Formal

**Data:** <data de hoje>
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
  final int syncStatus;      // 0=synced, 1=pending (default 1)
  // copyWith: SIM
  // fromMap/toMap SQLite: SIM
  // @immutable: NÃO — dívida técnica (ver seção 8)
  // Interface formal IVisitSession: NÃO — dívida técnica (ver seção 8)
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
| DT-023-1 | `VisitSessionSummary` com apenas 2 campos — insuficiente | Alto | PROMPT 03 |
| DT-023-2 | `IVisitSessionLookup` sem `findById()` | Médio | PROMPT 03 |
| DT-023-3 | `visit_controller.dart` importa 3 arquivos de `consultoria/` diretamente | Alto | PROMPT 04 |
| DT-023-4 | `geofence_controller.dart` importa 3 arquivos de `consultoria/` diretamente | Alto | PROMPT 04 |
| DT-023-5 | `map/` e `ui/` importam `visitas/` diretamente (sem contratos) | Médio | PROMPT 04 |
| DT-023-6 | `arch_check.sh` sem cobertura da camada de dados | Alto | PROMPT 05 |
| DT-023-7 | `VisitSession` não é `@immutable` / `final class` | Baixo | ADR futuro |
| DT-023-8 | Geofence duplicado em `visitas/` e `operacao/` | Médio | ADR futuro |

---

## 10. Plano de Execução

| Prompt | Ação | Impacto em código |
|---|---|---|
| PROMPT 03 | Expandir `VisitSessionSummary` + adicionar `findById` | Somente `core/contracts/` |
| PROMPT 04 | Corrigir violações em `visit_controller` e `geofence_controller` via contratos | `visitas/` apenas |
| PROMPT 05 | Adicionar regras ao `arch_check.sh` cobrindo camada de dados | `tool/arch_check.sh` |
| PROMPT 06 | Auditoria de conformidade total | READ-ONLY |
```

---

## PASSO 2 — ATUALIZAR `bounded_contexts.md`

Adicionar a seção descritiva de `visitas/` e as linhas na tabela de acoplamentos:

**Seção descritiva a adicionar:**
```markdown
### `visitas/`
**Natureza:** Execução de sessão de visita técnica em campo
**Responsabilidade:** Ciclo check-in → check-out, geofencing, estatísticas, sync
**Entidade central:** `VisitSession`
**ADR:** ADR-023
**Contratos em core/contracts/:** `IVisitSessionLookup`, `IVisitClientLookup`
**Regra:** NÃO depende de `consultoria/` nem de `drawing/`
**Ponto cego CI:** violações internas em `visit_controller` e `geofence_controller`
são dívida técnica registrada em ADR-023 seção 8 (DT-023-3, DT-023-4)
```

**Linhas a adicionar na tabela de acoplamentos:**
```markdown
| `agenda/` | `visitas/` | ✅ PERMITIDO (StartEventUseCase) |
| `operacao/` | `visitas/` | ✅ PERMITIDO |
| `map/` | `visitas/` via contratos | ✅ PERMITIDO |
| `map/` | `visitas/` direto | ⚠️ A MIGRAR — DT-023-5 |
| `consultoria/` | `visitas/` via contratos | ✅ PERMITIDO |
| `visitas/` | `consultoria/` | ❌ PROIBIDO — DT-023-3, DT-023-4 ativas |
| `visitas/` | `drawing/` | ❌ PROIBIDO |
```

---

## PASSO 3 — ATUALIZAR `00_INDEX_OFICIAL.md`

Adicionar ADR-023 na lista de ADRs ativos com status e dívidas pendentes.

---

## PASSO 4 — VERIFICAR ARCH_CHECK

```bash
bash tool/arch_check.sh
echo "EXIT CODE: $?"
```

Resultado esperado: **Exit 0** — este prompt não altera código Dart.

---

## VALIDAÇÃO FINAL

- [ ] `ADR-023-MODULO-VISITAS.md` criado com todas as seções?
- [ ] Violações documentadas nas seções 6, 8 e 9?
- [ ] `bounded_contexts.md` atualizado com `visitas/`?
- [ ] `00_INDEX_OFICIAL.md` atualizado?
- [ ] Nenhum arquivo `.dart` foi tocado?
- [ ] `arch_check.sh` Exit 0?

---

## ENCERRAMENTO

O ADR-023 está criado com o estado real do módulo, incluindo violações.
Nenhum código foi alterado.
As dívidas estão rastreadas com ID (DT-023-N) para referência nos próximos prompts.
