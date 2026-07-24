import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';

void main() {
  group('Location zoom alinhado ao viewport inicial', () {
    test('MapConfig.defaultZoom é o overview 13.0', () {
      expect(MapConfig.defaultZoom, 13.0);
    });

    test('handler privado não força zoom 16.0 no recenter', () {
      final src = File(
        'lib/ui/screens/map/handlers/map_location_handler.dart',
      ).readAsStringSync();
      expect(src.contains('16.0'), isFalse);
      expect(src.contains('MapViewportController.recenterOnUser'), isTrue);
    });

    test('mapa público não usa _userLocationZoom 16', () {
      final src = File(
        'lib/ui/screens/public_map_screen.dart',
      ).readAsStringSync();
      expect(src.contains('_userLocationZoom'), isFalse);
      expect(src.contains('MapConfig.defaultZoom'), isTrue);
      expect(src.contains('_recenterPublicMap'), isTrue);
    });

    test('viewport GPS inicial usa MapConfig.defaultZoom', () {
      final src = File(
        'lib/ui/screens/map/controllers/map_viewport_controller.dart',
      ).readAsStringSync();
      expect(src.contains('move(position.position, 16.0)'), isFalse);
      expect(src.contains('MapConfig.defaultZoom'), isTrue);
      expect(src.contains('recenterOnUser'), isTrue);
    });
  });
}
