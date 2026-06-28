import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/public/providers/public_location_provider.dart';

void main() {
  group('PublicLocationState', () {
    test('copyWith preserva campos não informados', () {
      const initial = PublicLocationState(
        status: PublicLocationStatus.initial,
      );

      final loading = initial.copyWith(status: PublicLocationStatus.loading);
      final available = loading.copyWith(
        status: PublicLocationStatus.available,
        position: const LatLng(-15.7, -47.9),
      );

      expect(loading.status, PublicLocationStatus.loading);
      expect(available.position?.latitude, -15.7);
      expect(available.errorMessage, isNull);
    });

    test('estados de erro carregam mensagem', () {
      const denied = PublicLocationState(
        status: PublicLocationStatus.permissionDenied,
        errorMessage: 'Permissão de localização negada',
      );

      expect(denied.status, PublicLocationStatus.permissionDenied);
      expect(denied.errorMessage, isNotEmpty);
    });
  });
}
