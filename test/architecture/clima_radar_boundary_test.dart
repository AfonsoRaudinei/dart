import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('radar de chuva vive em clima/ e não em ui/components/map/providers', () {
    expect(
      File('lib/ui/components/map/providers/rainviewer_provider.dart').existsSync(),
      isFalse,
      reason: 'rainviewer_provider.dart legado deve ser removido',
    );
    expect(
      File('lib/modules/clima/presentation/providers/radar_providers.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/modules/clima/presentation/widgets/radar_layer_widget.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/core/contracts/i_radar_overlay_controller.dart').existsSync(),
      isTrue,
    );
  });
}
