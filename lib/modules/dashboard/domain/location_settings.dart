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

/// Retorna true se a precisão GNSS é suficiente para check-in.
bool isGnssAccuracyAcceptableForCheckIn(double? accuracyMeters) {
  if (accuracyMeters == null) return false;
  return accuracyMeters <= soloforteGnssMaxCheckInAccuracyMeters;
}

/// Settings para requisições pontuais com timeout (ex.: geofence).
LocationSettings soloforteGnssLocationSettingsWithTimeout(Duration timeLimit) {
  return LocationSettings(
    accuracy: soloforteGnssAccuracy,
    distanceFilter: soloforteGnssDistanceFilter,
    timeLimit: timeLimit,
  );
}
