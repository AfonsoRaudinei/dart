import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/drawing_compact_selection_actions.dart';
import 'package:soloforte_app/ui/components/map/map_talhao_selection_toolbar.dart';

DrawingFeature _squareFeature({String id = 'f1'}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [0.0, 0.0],
          [2.0, 0.0],
          [2.0, 2.0],
          [0.0, 2.0],
          [0.0, 0.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'T1',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.synced,
    ),
  );
}

void main() {
  group('talhaoSelectionToolbarChipCount', () {
    test('4 chips com NDVI e 3 sem', () {
      expect(talhaoSelectionToolbarChipCount(showNdvi: true), 4);
      expect(talhaoSelectionToolbarChipCount(showNdvi: false), 3);
    });
  });

  group('drawingFeatureAnchorLatLng', () {
    test('retorna centroide para polígono simples', () {
      final feature = _squareFeature();

      final anchor = drawingFeatureAnchorLatLng(feature);
      expect(anchor, isNotNull);
      expect(anchor!.latitude, closeTo(0.8, 0.01));
      expect(anchor.longitude, closeTo(0.8, 0.01));
    });

    test('retorna null sem vértices', () {
      final now = DateTime(2026);
      final feature = DrawingFeature(
        id: 'empty',
        geometry: DrawingPolygon(coordinates: const []),
        properties: DrawingProperties(
          nome: 'Vazio',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-1',
          autorTipo: AuthorType.consultor,
          areaHa: 0,
          versao: 1,
          ativo: true,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.synced,
        ),
      );
      expect(drawingFeatureAnchorLatLng(feature), isNull);
    });
  });

  group('clampMapToolbarOffset', () {
    test('feliz: centraliza acima do ponto', () {
      const viewport = Size(400, 800);
      const toolbarWidth = 200.0;
      const toolbarHeight = 52.0;

      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 400),
        viewportSize: viewport,
        toolbarWidth: toolbarWidth,
        toolbarHeight: toolbarHeight,
      );

      expect(offset.dx, 100);
      expect(offset.dy, 400 - toolbarHeight - 12);
    });

    test('borda direita: clamp horizontal', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(390, 200),
        viewportSize: const Size(400, 800),
        toolbarWidth: 200,
        toolbarHeight: 52,
      );

      expect(
        offset.dx,
        400 - 200 - 8 - kMapActionColumnRightInset - kMapActionColumnButtonSize,
      );
    });

    test('borda inferior: reserva FAB + bottomInset', () {
      const viewport = Size(400, 800);
      const toolbarHeight = 52.0;
      const bottomInset = 34.0;

      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 790),
        viewportSize: viewport,
        toolbarWidth: 200,
        toolbarHeight: toolbarHeight,
        bottomInset: bottomInset,
      );

      final maxTop =
          800 - bottomInset - kFabSafeArea - toolbarHeight - 8;
      expect(offset.dy, maxTop);
    });

    test('borda superior: clamp vertical com topInset', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 10),
        viewportSize: const Size(400, 800),
        toolbarWidth: 200,
        toolbarHeight: 52,
        topInset: 44,
      );

      expect(offset.dy, greaterThanOrEqualTo(44 + 8));
    });

    test('viewport minúsculo: não lança e mantém margem', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(5, 5),
        viewportSize: const Size(120, 100),
        toolbarWidth: 200,
        toolbarHeight: 52,
      );

      expect(offset.dx, greaterThanOrEqualTo(8));
      expect(offset.dy, greaterThanOrEqualTo(8));
    });

    test('viewport 360dp com 4 chips (275px) não invade coluna direita', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(350, 200),
        viewportSize: const Size(360, 800),
        toolbarWidth: 275,
        toolbarHeight: 52,
      );

      expect(
        offset.dx + 275,
        lessThanOrEqualTo(
          360 - kMapActionColumnRightInset - kMapActionColumnButtonSize,
        ),
      );
    });
  });

  group('estimateMapTalhaoToolbarWidth', () {
    test('retorna largura para 4 chips quando feature tem id', () {
      final feature = _squareFeature();
      expect(estimateMapTalhaoToolbarWidth(feature), 275.0);
    });

    test('retorna largura para 2 chips quando feature tem id vazio', () {
      final feature = _squareFeature(id: '');
      expect(estimateMapTalhaoToolbarWidth(feature), 137.0);
    });
  });

  group('DrawingCompactSelectionActions P&B e NDVI', () {
    testWidgets('showMonochromeMap alterna modo P&B e showNdviMap desativa P&B', (
      tester,
    ) async {
      final feature = _squareFeature();
      late WidgetRef capturedRef;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(capturedRef.read(mapNdviOverlayFieldIdProvider), isNull);
      expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);

      DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
      expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
      expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isTrue);

      DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
      expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
      expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);

      DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
      expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isTrue);

      DrawingCompactSelectionActions.showNdviMap(capturedRef, feature);
      expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
      expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);
    });
  });
}
