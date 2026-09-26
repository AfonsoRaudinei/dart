# AGENTS.md — clima

## Bounded context

`clima/` fornece dados climaticos, radar de chuva (RainViewer) e apoio operacional para o mapa.

## Radar no mapa (ADR-043)

- Providers: `lib/modules/clima/presentation/providers/radar_providers.dart`
- Widget: `ClimaRadarLayerWidget` em `presentation/widgets/radar_layer_widget.dart`
- Contrato imperativo: `IRadarOverlayController` (`core/contracts/`)
- Adapter: `infra/radar_overlay_controller_adapter.dart` (registrado em `main.dart`)
- Toggle: `climaRadarEnabledProvider` — **nao** usar `ArmedMode`

## Chuva, não nuvem

O toggle do mapa mostra **precipitação** (radar RainViewer) e nada mais. O overlay
de nuvens infravermelho (RealEarth `globalir`) foi removido: cobria o mapa de branco
onde não estava chovendo e escondia a informação que interessa. RainViewer
descontinuou `satellite.infrared` em 2026-01-01, então o radar some onde não chove —
isso é o comportamento esperado, não falta de camada.

## Contratos e dependencias

- Pode consumir `core/contracts/IUserLocationLookup` quando precisar de localizacao.
- Pode consumir `core/state/map_state.dart` apenas no adapter de radar (camada satelite).
- Nao deve importar outros modulos diretamente.

## Proibido

- Tratar clima como rota de mapa ou criar sub-rota em `/map`.
- Recriar providers RainViewer em `ui/components/map/`.
- Referenciar `ArmedMode.clima` ou `showRadarProvider`.
- Bloquear UI quando uma fonte remota falhar.
- Expor chaves de API em codigo, logs ou mensagens.

## Qualidade obrigatoria

- Falhas remotas devem ter fallback ou erro sanitizado.
- Cache e dados externos precisam ter validade explicita.
- Toggle de radar persistido (`clima_radar_enabled_v1`).
- Estados UX diferenciados: loading, active, offline, vazio, indisponivel.
- Telemetria via `AppLogger` tag `Radar` (sem URLs completas).
- Testes esperados: `test/modules/clima/radar_*`, `rainviewer_contract_test.dart`, `test/architecture/clima_radar_boundary_test.dart`.
- Rodar `flutter analyze lib/modules/clima/` e `./tool/arch_check.sh`.
