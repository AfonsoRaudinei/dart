/// Controle imperativo do overlay de radar de chuva no mapa (ADR-043).
///
/// Implementado por `clima/infra`. Consumidores: `ui/` (chrome do mapa).
abstract interface class IRadarOverlayController {
  bool readEnabled();

  void setEnabled(bool enabled, {bool preferSatelliteLayer = false});
}
