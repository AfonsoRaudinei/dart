/// Controle imperativo do overlay de radar de chuva no mapa (ADR-043).
///
/// Implementado por `clima/infra`. Consumidores: `ui/` (LayersSheet) e
/// `clima/presentation` (ClimaScreen → Ver no mapa).
abstract interface class IRadarOverlayController {
  bool readEnabled();

  void setEnabled(bool enabled, {bool preferSatelliteLayer = false});
}
