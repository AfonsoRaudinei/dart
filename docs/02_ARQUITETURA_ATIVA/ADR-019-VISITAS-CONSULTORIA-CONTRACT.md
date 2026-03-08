# ADR-019 — Contrato `IVisitSessionLookup` entre `visitas` e `consultoria`

**Data:** 08/03/2026  
**Status:** Aprovado  
**Contexto:** estabilização pós-auditoria (Sessão 3)

---

## Contexto

A auditoria identificou acoplamento cruzado em camada de presentation:

- `consultoria/occurrences/presentation/controllers/occurrence_controller.dart`
  importava `visitas/presentation/controllers/visit_controller.dart`.
- `visitas/presentation/controllers/visit_controller.dart`
  importava `consultoria/occurrences/presentation/controllers/occurrence_controller.dart`.

Esse ciclo aumentava risco de regressão e violava isolamento entre bounded contexts.

---

## Decisão

Criar contrato neutro em `core/contracts/`:

- `IVisitSessionLookup` (interface)
- `VisitSessionSummary` (DTO mínimo)
- `visitSessionLookupProvider` (provider de interface)

Implementação concreta no módulo dono (`visitas`):

- `VisitSessionLookupAdapter` em `modules/visitas/infra/`
- registro via `ProviderScope.overrides` em `main.dart`

`consultoria` passa a depender apenas do contrato em `core/contracts/`.

---

## Implementação

1. Novo contrato:
- `lib/core/contracts/i_visit_session_lookup.dart`
- `lib/core/contracts/i_visit_session_lookup_provider.dart`

2. Adapter concreto:
- `lib/modules/visitas/infra/visit_session_lookup_adapter.dart`

3. Registro no bootstrap:
- `lib/main.dart` (`visitSessionLookupProvider.overrideWithValue(...)`)

4. Remoção de dependência presentation cruzada:
- `occurrence_controller.dart` usa `visitSessionLookupProvider`
- `visit_controller.dart` remove import de `occurrence_controller.dart`
  e usa provider local de `OccurrenceRepository`

---

## Consequências

- Remove o ciclo de import entre controllers de presentation.
- Mantém fronteira clara: `consultoria` conhece apenas contrato neutro.
- Facilita teste e evolução independente dos módulos.

---

## Checklist

- [x] Sem import direto `consultoria -> visitas` em presentation
- [x] Sem import direto `visitas -> consultoria` de provider/controller de presentation
- [x] Contrato formal em `core/contracts/`
- [x] Implementação concreta no módulo proprietário (`visitas`)
