import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_location_handler.dart';

void main() {
  tearDown(() {
    MapLocationHandler.stopFollowing();
  });

  group('MapLocationHandler northLocked', () {
    test('startFollowing com lockNorth=true marca debugLockNorth', () {
      final controller = MapController();

      MapLocationHandler.startFollowing(
        locationStream: const Stream<LatLng>.empty(),
        mapController: controller,
        isMapReady: true,
        lockNorth: true,
      );

      expect(MapLocationHandler.debugLockNorth, isTrue);
      expect(MapLocationHandler.debugIsFollowing, isTrue);
    });

    test('startFollowing com lockNorth=false não trava norte', () {
      final controller = MapController();

      MapLocationHandler.startFollowing(
        locationStream: const Stream<LatLng>.empty(),
        mapController: controller,
        isMapReady: true,
        lockNorth: false,
      );

      expect(MapLocationHandler.debugLockNorth, isFalse);
      expect(MapLocationHandler.debugIsFollowing, isTrue);
    });

    test('stopFollowing limpa lockNorth e subscription', () {
      final controller = MapController();

      MapLocationHandler.startFollowing(
        locationStream: StreamController<LatLng>.broadcast().stream,
        mapController: controller,
        isMapReady: true,
        lockNorth: true,
      );
      MapLocationHandler.stopFollowing();

      expect(MapLocationHandler.debugLockNorth, isFalse);
      expect(MapLocationHandler.debugIsFollowing, isFalse);
    });

    test('isMapReady=false não inicia follow nem trava norte', () {
      final controller = MapController();

      MapLocationHandler.startFollowing(
        locationStream: const Stream<LatLng>.empty(),
        mapController: controller,
        isMapReady: false,
        lockNorth: true,
      );

      expect(MapLocationHandler.debugLockNorth, isFalse);
      expect(MapLocationHandler.debugIsFollowing, isFalse);
    });
  });
}
