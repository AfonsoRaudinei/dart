import 'package:latlong2/latlong.dart';

/// Posição GNSS do usuário com precisão horizontal reportada pelo SO (metros).
class UserLocationFix {
  const UserLocationFix({
    required this.position,
    required this.accuracyM,
  });

  final LatLng position;

  /// Precisão horizontal em metros (`Position.accuracy` do geolocator).
  final double accuracyM;

  /// Valor seguro para UX quando o SO retorna 0 ou negativo.
  double get effectiveAccuracyM => accuracyM > 0 ? accuracyM : 12.0;
}
