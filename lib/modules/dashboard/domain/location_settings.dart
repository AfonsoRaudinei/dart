import 'package:geolocator/geolocator.dart';

/// Configuração GNSS unificada do SoloForte.
/// Multi-constelação (GPS+GLONASS+BeiDou+Galileo) é delegada ao OS/chipset.
const LocationAccuracy soloforteGnssAccuracy = LocationAccuracy.bestForNavigation;
const int soloforteGnssDistanceFilter = 5;

const LocationSettings soloforteGnssLocationSettings = LocationSettings(
  accuracy: soloforteGnssAccuracy,
  distanceFilter: soloforteGnssDistanceFilter,
);

/// Precisão máxima (metros) aceita para check-in de visita em campo.
const double soloforteGnssMaxCheckInAccuracyMeters = 30;

/// Precisão máxima (metros) aceita para atualizar o ponto azul ao vivo no mapa.
/// Leituras piores que isso só são aceitas se melhorarem a precisão do último
/// fix mostrado (evita que o marcador fique travado em sinal ruim prolongado).
const double soloforteGnssMaxLiveMarkerAccuracyMeters = 25;

/// Retorna true se a precisão GNSS é suficiente para check-in.
bool isGnssAccuracyAcceptableForCheckIn(double? accuracyMeters) {
  if (accuracyMeters == null) return false;
  return accuracyMeters <= soloforteGnssMaxCheckInAccuracyMeters;
}

/// Decide se [nextAccuracyM] deve substituir [lastAcceptedAccuracyM] no ponto azul.
/// `lastAcceptedAccuracyM == null` sempre aceita (primeiro fix).
bool shouldAcceptLiveLocationFix({
  required double? lastAcceptedAccuracyM,
  required double nextAccuracyM,
}) {
  if (lastAcceptedAccuracyM == null) return true;
  if (nextAccuracyM <= soloforteGnssMaxLiveMarkerAccuracyMeters) return true;
  return nextAccuracyM <= lastAcceptedAccuracyM;
}

/// Settings para requisições pontuais com timeout (ex.: geofence).
LocationSettings soloforteGnssLocationSettingsWithTimeout(Duration timeLimit) {
  return LocationSettings(
    accuracy: soloforteGnssAccuracy,
    distanceFilter: soloforteGnssDistanceFilter,
    timeLimit: timeLimit,
  );
}
