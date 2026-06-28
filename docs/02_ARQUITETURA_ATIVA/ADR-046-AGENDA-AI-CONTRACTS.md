# ADR-046 — Contratos agenda_ai ↔ agenda/carteira (Fase 2)

**Status:** ATIVO  
**Data:** Jun/2026

## Decisão

- `IAgendaAiRecommendationContextLookup` — monta contexto de recomendação sem imports laterais
- `IAgendaAiVisitWriter` — cria visita sugerida via `CreateEventUseCase`

## Implementadores

| Contrato | Local |
|---|---|
| `IAgendaAiRecommendationContextLookup` | `app/adapters/agenda_ai_recommendation_context_adapter.dart` |
| `IAgendaAiVisitWriter` | `agenda/infra/agenda_ai_visit_writer_adapter.dart` |

## Consumidor migrado

- `agenda_ai/presentation/widgets/agenda_ai_sheet.dart`

## CI

REGRA-CROSS-MODULE-2 promovida de warning-only para **FAIL** após migração.
