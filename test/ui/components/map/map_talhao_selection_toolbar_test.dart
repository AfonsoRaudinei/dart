import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/ui/components/map/map_talhao_selection_toolbar.dart';

DrawingFeature _squareFeature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'f1',
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

      expect(offset.dx, 400 - 200 - 8);
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
  });
}
