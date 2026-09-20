/// Política de frescor das camadas de satélite (MapTiler base + overlay Cerrado).
class SatelliteFreshnessInfo {
  final String providerLabel;
  final String acquisitionPeriod;
  final String disclaimer;
  final bool isInCerrado;
  final bool cerradoOverlayAvailable;

  const SatelliteFreshnessInfo({
    required this.providerLabel,
    required this.acquisitionPeriod,
    required this.disclaimer,
    required this.isInCerrado,
    required this.cerradoOverlayAvailable,
  });
}

/// Bbox aproximado do bioma Cerrado (INPE).
const double kCerradoSouth = -24.79;
const double kCerradoNorth = -1.78;
const double kCerradoWest = -61.75;
const double kCerradoEast = -40.06;

/// Retorna `true` quando o ponto está dentro do bioma Cerrado.
bool isInCerradoBounds(double lat, double lng) {
  return lat >= kCerradoSouth &&
      lat <= kCerradoNorth &&
      lng >= kCerradoWest &&
      lng <= kCerradoEast;
}

/// Mensagem de frescor para um ponto do mapa.
SatelliteFreshnessInfo freshnessForPoint(double lat, double lng) {
  final inCerrado = isInCerradoBounds(lat, lng);
  return SatelliteFreshnessInfo(
    providerLabel: 'MapTiler Satellite',
    acquisitionPeriod: '2020–2021',
    disclaimer: inCerrado
        ? 'Base MapTiler (Sentinel ~2020–2021). No Cerrado, ative a camada INPE '
              'abaixo para imagens mais recentes (nov/2023–ago/2024).'
        : 'Imagens MapTiler Sentinel ~2020–2021.',
    isInCerrado: inCerrado,
    cerradoOverlayAvailable: inCerrado,
  );
}
