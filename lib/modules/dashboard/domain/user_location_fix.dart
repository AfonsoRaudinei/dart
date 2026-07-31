import 'package:latlong2/latlong.dart';

/// Posição GNSS do usuário com precisão horizontal reportada pelo SO (metros).
class UserLocationFix {
  const UserLocationFix({
    required this.position,
    required this.accuracyM,
    this.headingDeg,
  });

  final LatLng position;

  /// Precisão horizontal em metros (`Position.accuracy` do geolocator).
  final double accuracyM;

  /// Rumo GNSS em graus (0° = norte). `null` quando inválido (`Position.heading < 0`).
  final double? headingDeg;

  /// Valor seguro para UX quando o SO retorna 0 ou negativo.
  double get effectiveAccuracyM => accuracyM > 0 ? accuracyM : 12.0;

  bool get hasValidHeading =>
      headingDeg != null && headingDeg! >= 0 && headingDeg! <= 360;
}
