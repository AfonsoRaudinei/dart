import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P0 — Tap/long press no mapa com modo ocorrência armado.
///
/// Garante que o dispatcher respeita [ArmedMode.occurrences] antes de
/// rotear long press para MarketingCase/NovoCaseModalLauncher.
void main() {
  group('map_occurrence_gesture_routing_regression', () {
    late String orchestratorSource;
    late String privateMapSource;

    setUp(() {
      orchestratorSource = File(
        'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
      ).readAsStringSync();
      privateMapSource = File(
        'lib/ui/screens/private_map_screen.dart',
      ).readAsStringSync();
    });

    test('onTap prioriza ArmedMode.occurrences antes do estado de desenho', () {
      final tapBlock = orchestratorSource.substring(
        orchestratorSource.indexOf('onTap: (tapPos, point)'),
        orchestratorSource.indexOf('onLongPress: (tapPos, point)'),
      );

      expect(
        tapBlock.indexOf('ArmedMode.occurrences'),
        lessThan(tapBlock.indexOf('DrawingState.drawing')),
      );
      expect(tapBlock, contains('openOccurrenceSheet(point.latitude'));
    });

    test('onLongPress com ArmedMode.occurrences abre ocorrência, não marketing', () {
      final longPressBlock = orchestratorSource.substring(
        orchestratorSource.indexOf('onLongPress: (tapPos, point)'),
        orchestratorSource.indexOf('onPositionChanged: (pos, hasGesture)'),
      );

      expect(longPressBlock, contains('ArmedMode.occurrences'));
      expect(
        longPressBlock.indexOf('openOccurrenceSheet(point.latitude'),
        lessThan(longPressBlock.indexOf('handleMapLongPress(tapPos, point)')),
      );
    });

    test('_armOccurrenceMode cancela desenho armado para liberar tap no mapa', () {
      expect(privateMapSource, contains('void _armOccurrenceMode()'));
      expect(privateMapSource, contains('drawCtrl.cancelOperation()'));
      expect(privateMapSource, contains('ArmedMode.occurrences'));
    });

    test('provider de contexto armado existe (substituto de MapContext)', () {
      expect(
        File('lib/ui/screens/map/providers/map_armed_mode_provider.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/ui/screens/map/providers/map_armed_mode_provider.dart',
        ).readAsStringSync(),
        contains('enum ArmedMode'),
      );
    });

    test('sheet de criação de ocorrência existe no módulo consultoria', () {
      expect(
        File(
          'lib/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart',
        ).existsSync(),
        isTrue,
      );
    });
  });
}
