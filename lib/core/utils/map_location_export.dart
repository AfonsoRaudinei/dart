/// Formatação e URLs para exportar coordenadas a apps de mapa/rotas.
class MapLocationExport {
  const MapLocationExport._();

  static const int decimalPlaces = 6;

  /// Coordenadas válidas para exportação (rejeita NaN/∞/(0,0)).
  static bool isValidCoordinate(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return latitude != 0 || longitude != 0;
  }

  static String formatDecimalLatLng(double latitude, double longitude) {
    if (!isValidCoordinate(latitude, longitude)) {
      throw ArgumentError('Coordenadas inválidas para exportação');
    }
    final lat = latitude.toStringAsFixed(decimalPlaces);
    final lng = longitude.toStringAsFixed(decimalPlaces);
    return '$lat, $lng';
  }

  static String googleMapsUrl(double latitude, double longitude) {
    _assertValid(latitude, longitude);
    final lat = latitude.toStringAsFixed(decimalPlaces);
    final lng = longitude.toStringAsFixed(decimalPlaces);
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  static String appleMapsUrl(double latitude, double longitude) {
    _assertValid(latitude, longitude);
    final lat = latitude.toStringAsFixed(decimalPlaces);
    final lng = longitude.toStringAsFixed(decimalPlaces);
    return 'https://maps.apple.com/?ll=$lat,$lng';
  }

  static String wazeUrl(double latitude, double longitude) {
    _assertValid(latitude, longitude);
    final lat = latitude.toStringAsFixed(decimalPlaces);
    final lng = longitude.toStringAsFixed(decimalPlaces);
    return 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
  }

  static String shareText(
    double latitude,
    double longitude, {
    String label = 'Localização',
  }) {
    _assertValid(latitude, longitude);
    final coords = formatDecimalLatLng(latitude, longitude);
    final mapsUrl = googleMapsUrl(latitude, longitude);
    return '$label\n$coords\n$mapsUrl';
  }

  static void _assertValid(double latitude, double longitude) {
    if (!isValidCoordinate(latitude, longitude)) {
      throw ArgumentError('Coordenadas inválidas para exportação');
    }
  }
}
