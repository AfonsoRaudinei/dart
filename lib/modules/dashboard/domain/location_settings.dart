import 'package:geolocator/geolocator.dart';

/// Configuração GNSS unificada do SoloForte.
/// Multi-constelação (GPS+GLONASS+BeiDou+Galileo) é delegada ao OS/chipset.
const LocationAccuracy soloforteGnssAccuracy = LocationAccuracy.bestForNavigation;
const int soloforteGnssDistanceFilter = 10;

const LocationSettings soloforteGnssLocationSettings = LocationSettings(
  accuracy: soloforteGnssAccuracy,
  distanceFilter: soloforteGnssDistanceFilter,
);

/// Settings para requisições pontuais com timeout (ex.: geofence).
LocationSettings soloforteGnssLocationSettingsWithTimeout(Duration timeLimit) {
  return LocationSettings(
    accuracy: soloforteGnssAccuracy,
    distanceFilter: soloforteGnssDistanceFilter,
    timeLimit: timeLimit,
  );
}
