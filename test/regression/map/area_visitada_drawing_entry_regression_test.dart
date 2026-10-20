import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Área Visitada sai do long-press (MapMarkSheet) e entra em Ferramentas de Desenho.
/// Tap/long-press armado grava o pin sem formulário.
void main() {
  group('area_visitada_drawing_entry_regression', () {
    test('DrawingToolSelector contém Área Visitada depois de GPS', () {
      final source = File(
        'lib/modules/drawing/presentation/widgets/components/drawing_tool_selector.dart',
      ).readAsStringSync();

      expect(source, contains("label: 'Área Visitada'"));
      expect(source, contains("onTap: () => onToolSelected('area_visitada')"));
      expect(source, contains('SFIcons.pinFill'));
      expect(source, contains('isSelected: false'));
      expect(
        source.indexOf("label: 'GPS (caminhar)'"),
        lessThan(source.indexOf("label: 'Área Visitada'")),
      );
    });

    test(
      'DrawingSheet trata area_visitada como ação (callback + fecha sheet)',
      () {
        final source = File(
          'lib/modules/drawing/presentation/widgets/drawing_sheet.dart',
        ).readAsStringSync();

        expect(source, contains('final VoidCallback? onAreaVisitada'));
        expect(source, contains("if (key == 'area_visitada')"));
        expect(source, contains('widget.onAreaVisitada?.call()'));
        expect(
          source,
          contains('_requestClose(DrawingCloseIntent.dismissSheet)'),
        );
        expect(source, isNot(contains('modules/consultoria')));
      },
    );

    test('_MapToolsFab usa SFIcons.edit e mantém a key de layers', () {
      final source = File(
        'lib/ui/components/map/widgets/map_controls_overlay.dart',
      ).readAsStringSync();
      final start = source.indexOf('class _MapToolsFab');
      final end = source.indexOf('class _MapButtonLabel', start);
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      final tools = source.substring(start, end);

      expect(tools, contains('SFIcons.edit'));
      expect(tools, isNot(contains('SFIcons.layers')));
      expect(tools, contains("key: const Key('map_control_layers_btn')"));
    });

    test('ArmedMode.areaVisitada existe e o orchestrator trata tap', () {
      final armedSource = File(
        'lib/ui/screens/map/providers/map_armed_mode_provider.dart',
      ).readAsStringSync();
      final orchestratorSource = File(
        'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
      ).readAsStringSync();
      final bannerSource = File(
        'lib/ui/screens/map/widgets/armed_mode_banner.dart',
      ).readAsStringSync();

      expect(
        armedSource,
        contains('enum ArmedMode { none, occurrences, areaVisitada }'),
      );

      final tapBlock = orchestratorSource.substring(
        orchestratorSource.indexOf('onTap: (tapPos, point)'),
        orchestratorSource.indexOf('onLongPress: (tapPos, point)'),
      );
      expect(tapBlock, contains('ArmedMode.areaVisitada'));
      expect(tapBlock, contains('dropAreaVisitadaPin(point.latitude'));
      expect(
        tapBlock.indexOf('ArmedMode.areaVisitada'),
        lessThan(tapBlock.indexOf('DrawingState.drawing')),
      );

      expect(
        bannerSource,
        contains('Toque no mapa para marcar o ponto visitado'),
      );
    });
  });
}
