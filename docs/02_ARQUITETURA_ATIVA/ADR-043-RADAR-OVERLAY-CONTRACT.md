# ADR-043 — Contrato de overlay de radar de chuva (RainViewer)

## Status

Ativo — 2026-06-27

## Contexto

O overlay de precipitacao no mapa estava em `ui/components/map/` com providers
locais (`radarEnabledProvider`, `rainviewer_provider.dart`), desconectado do
bounded context `clima/`. Documentacao antiga referenciava `ArmedMode.clima`,
valor que nunca existiu no enum real.

## Decisao

1. **Ownership:** modulo `clima/` passa a donar:
   - `presentation/providers/radar_providers.dart`
   - `presentation/widgets/radar_layer_widget.dart` (`ClimaRadarLayerWidget`)
   - `data/datasources/rainviewer_radar_datasource.dart`
   - `domain/entities/radar_rain_frame.dart`
   - `infra/radar_overlay_controller_adapter.dart`

2. **Contrato:** `IRadarOverlayController` em `core/contracts/` expoe
   `readEnabled()` e `setEnabled(..., preferSatelliteLayer:)`. Composicao em
   `main.dart` via `radarOverlayControllerProvider`.

3. **Estado:** toggle dedicado `climaRadarEnabledProvider` — **nao** usa
   `ArmedMode`. O radar e overlay persistente, independente de ocorrencias/marketing.

4. **Mapa:** `ui/` consome `ClimaRadarLayerWidget` e o contrato; nao mantem
   providers RainViewer locais.

5. **Z-order:** radar apos poligonos/desenho, antes de markers
   (`MapBuildOrchestrator`).

6. **Fonte externa:** RainViewer public API (sem API key). Falhas degradam para
   lista vazia + banner, sem bloquear o mapa.

## Consequencias

- `ui/components/map/providers/rainviewer_provider.dart` removido.
- `LayersSheet` e `ClimaScreen` usam `IRadarOverlayController`.
- Testes de regressao em `test/modules/clima/` e `test/architecture/clima_radar_boundary_test.dart`.
- DT-028 encerrado definitivamente; referencias a `ArmedMode.clima` obsoletas.

## Consumidores

| Consumidor | Uso |
|---|---|
| `ui/.../map_layers_sheet.dart` | toggle via contrato |
| `ui/.../map_build_orchestrator.dart` | render `ClimaRadarLayerWidget` |
| `clima/.../clima_screen.dart` | "Ver chuva no mapa" → `/map` + enable |

## Blindagem Fase 3 (anti-regressao)

- Toggle persistido: `clima_radar_enabled_v1` (SharedPreferences)
- Estados UX: `ClimaRadarOverlayState` + mensagens diferenciadas
- Telemetria: `AppLogger` tag `Radar` (sem URLs completas)
- CI: job `clima-radar-regression` + `REGRA-CLIMA-RADAR-*` em `arch_check.sh`
- Contrato live: `test/modules/clima/rainviewer_contract_test.dart` + fixture v2
