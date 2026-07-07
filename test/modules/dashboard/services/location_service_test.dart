import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/dashboard/domain/user_location_fix.dart';
import 'package:soloforte_app/modules/dashboard/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(LocationService.debugReset);
  tearDown(LocationService.debugReset);

  group('LocationService - Estrutura', () {
    test('deve ser singleton', () {
      final instance1 = LocationService();
      final instance2 = LocationService();

      expect(instance1, equals(instance2));
    });

    test('deve expor stream de localização com precisão GNSS', () {
      final locationService = LocationService();

      expect(locationService.locationStream, isA<Stream<UserLocationFix>>());
    });

    test('stream deve ser broadcast (múltiplos listeners)', () {
      final locationService = LocationService();
      final stream = locationService.locationStream;

      expect(stream.isBroadcast, isTrue);
    });

    test('propaga accuracyM do Position no stream', () async {
      final positions = StreamController<Position>();
      LocationService.debugSetPositionStreamFactory((_) => positions.stream);

      final locationService = LocationService();
      final fixes = <UserLocationFix>[];
      final sub = locationService.locationStream.listen(fixes.add);

      positions.add(
        Position(
          latitude: -10,
          longitude: -48,
          timestamp: DateTime.utc(2026, 7, 6),
          accuracy: 4.2,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(fixes, hasLength(1));
      expect(fixes.single.position, const LatLng(-10, -48));
      expect(fixes.single.accuracyM, 4.2);
      expect(fixes.single.effectiveAccuracyM, 4.2);

      await sub.cancel();
      await positions.close();
    });

    test('cancela assinatura nativa quando último listener sai', () async {
      var cancelCount = 0;
      final positions = StreamController<Position>(
        onCancel: () {
          cancelCount++;
        },
      );
      LocationService.debugSetPositionStreamFactory((_) => positions.stream);

      final locationService = LocationService();
      final stream = locationService.locationStream;
      final first = stream.listen((_) {});
      final second = stream.listen((_) {});

      expect(locationService.hasActiveNativeStream, isTrue);

      await first.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(locationService.hasActiveNativeStream, isTrue);
      expect(cancelCount, 0);

      await second.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(locationService.hasActiveNativeStream, isFalse);
      expect(cancelCount, 1);

      await positions.close();
    });

    test('não deve criar múltiplos streams', () {
      final locationService = LocationService();

      final stream1 = locationService.locationStream;
      final stream2 = locationService.locationStream;

      expect(stream1, isA<Stream<UserLocationFix>>());
      expect(stream2, isA<Stream<UserLocationFix>>());
    });

    test('dispose deve executar sem erro', () {
      final locationService = LocationService();
      locationService.locationStream;
      expect(() => locationService.dispose(), returnsNormally);
    });
  });

  group('UserLocationFix', () {
    test('effectiveAccuracyM usa fallback 12m quando accuracy inválida', () {
      const fix = UserLocationFix(
        position: LatLng(-10, -48),
        accuracyM: 0,
      );
      expect(fix.effectiveAccuracyM, 12.0);
    });
  });
}
