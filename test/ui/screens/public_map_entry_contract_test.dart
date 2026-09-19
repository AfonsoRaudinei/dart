import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/public_map/public_map_entry_constants.dart';

/// Contrato da vitrine pública: zoom de entrada ≠ zoom do toque manual;
/// watermark removido do topo.
void main() {
  group('contrato entrada public-map', () {
    test('zoom de entrada é regional e menor que o toque de localização', () {
      expect(
        PublicMapEntryConstants.kPublicMapEntryZoom,
        lessThan(PublicMapEntryConstants.kPublicMapLocationTapZoom),
      );
      expect(PublicMapEntryConstants.kPublicMapEntryZoom, 11.5);
      expect(PublicMapEntryConstants.kPublicMapLocationTapZoom, 16.0);
    });

    test('public_map_screen não expõe watermark SoloForte no topo', () {
      final source = File('lib/ui/screens/public_map_screen.dart').readAsStringSync();
      expect(source.contains('_SoloForteWatermark'), isFalse);
      expect(source.contains("Text(\n            'SoloForte'"), isFalse);
    });

    test('public_map_screen separa zoom de entrada e toque manual', () {
      final source = File('lib/ui/screens/public_map_screen.dart').readAsStringSync();
      expect(source.contains('_centerOnUserAtEntryZoom'), isTrue);
      expect(source.contains('kPublicMapEntryZoom'), isTrue);
      expect(source.contains('kPublicMapLocationTapZoom'), isTrue);
    });

    test('toque de localização não delega para zoom de entrada', () {
      final source = File('lib/ui/screens/public_map_screen.dart').readAsStringSync();
      final tapBlock = source.split('Future<void> _onLocationTap()')[1]
          .split('Future<LatLng?> _resolveUserPosition()')[0];
      expect(tapBlock.contains('_handlePermissionResult'), isFalse);
      expect(tapBlock.contains('_centerOnUserAtEntryZoom'), isFalse);
      expect(tapBlock.contains('kPublicMapLocationTapZoom'), isTrue);
    });
  });
}
