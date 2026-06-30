# ADR-045 — Contratos NDVI e visita ativa (Fase 2)

**Status:** ATIVO  
**Data:** Jun/2026

## Decisão

- `IVisitClientLookup.getClientHierarchy()` — DTO `VisitClientHierarchy` para map/visit card
- `INdviFieldPresenter` — abre sheet NDVI sem import de `ndvi/`
- `INdviLatestLookup` + `NdviLatestSummary` — preview em consultoria sem import de `ndvi/`

## Implementadores

| Contrato | Módulo |
|---|---|
| `getClientHierarchy` | `consultoria/clients/infra/visit_client_lookup_adapter.dart` |
| `INdviFieldPresenter` | `ndvi/infra/ndvi_field_presenter_adapter.dart` |
| `INdviLatestLookup` | `ndvi/infra/ndvi_latest_lookup_adapter.dart` |

## Consumidores migrados

- `map/presentation/widgets/visit_active_card.dart`
- `consultoria/clients/presentation/screens/field_detail_screen.dart`
