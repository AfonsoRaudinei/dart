import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_vertex_handle_overlay.dart';

const _kIntersectionWarning =
    'Linhas se cruzam. Ajuste os vértices e confirme de novo.';

class _EmptyDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}
}

class _UpsertDrawingRepository extends DrawingRepository {
  _UpsertDrawingRepository(DrawingFeature initial) : features = [initial];

  final List<DrawingFeature> features;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => List.of(features);

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    final index = features.indexWhere((item) => item.id == feature.id);
    if (index == -1) {
      features.add(feature);
    } else {
      features[index] = feature;
    }
  }
}

DrawingFeature _squareFeature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-unified',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [-0.01, -0.01],
          [0.01, -0.01],
          [0.01, 0.01],
          [-0.01, 0.01],
          [-0.01, -0.01],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão unificado',
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
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  testWidgets(
    'desenho unificado: laço, bico, linha, vértice e gota sem congelar o mapa',
    (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // --- Laço: permanece em desenho com mensagem nova (#173) ---
      final loop = DrawingController(repository: _EmptyDrawingRepository());
      loop.selectTool('polygon');
      loop.appendDrawingPoint(const LatLng(0, 0));
      loop.appendDrawingPoint(const LatLng(10, 10));
      loop.appendDrawingPoint(const LatLng(0, 10));
      loop.appendDrawingPoint(const LatLng(10, 0));
      loop.completeDrawing();
      expect(loop.currentState, DrawingState.drawing);
      expect(loop.intersectionWarningMessage, _kIntersectionWarning);
      loop.dispose();

      // --- Bico côncavo sem cruzamento real entra em revisão (#173) ---
      final beak = DrawingController(repository: _EmptyDrawingRepository());
      beak.selectTool('polygon');
      beak.appendDrawingPoint(const LatLng(0, 0));
      beak.appendDrawingPoint(const LatLng(5, 0));
      beak.appendDrawingPoint(const LatLng(5, 5));
      beak.appendDrawingPoint(const LatLng(3, 5));
      beak.appendDrawingPoint(const LatLng(3, 2));
      beak.appendDrawingPoint(const LatLng(4, 2));
      beak.appendDrawingPoint(const LatLng(4, 4));
      expect(beak.hasSelfIntersection, isFalse);
      beak.completeDrawing();
      expect(beak.currentState, DrawingState.drawing);
      beak.appendDrawingPoint(const LatLng(4, 5));
      beak.appendDrawingPoint(const LatLng(0, 5));
      beak.completeDrawing();
      expect(beak.currentState, DrawingState.reviewing);
      expect(beak.intersectionWarningMessage, isNull);
      beak.dispose();

      // --- Toque na linha insere/seleciona; vértice não insere (#176) ---
      final edit = DrawingController(
        repository: _UpsertDrawingRepository(_squareFeature()),
      );
      await edit.loadFeatures();
      edit.selectFeature(edit.features.single);
      edit.startEditMode();
      final beforeLen =
          (edit.liveGeometry! as DrawingPolygon).coordinates.first.length;

      final edge = edit.findEditEdgeNear(const LatLng(-0.01, 0), 50);
      expect(edge, isNotNull);
      edit.insertVertex(edge!.ring, edge.segment, edge.point);
      expect(
        (edit.liveGeometry! as DrawingPolygon).coordinates.first.length,
        beforeLen + 1,
      );
      expect(edit.selectedEditRingIndex, edge.ring);
      expect(edit.selectedEditPointIndex, edge.segment + 1);
      expect(edit.isDraggingVertex, isFalse);

      final afterInsert =
          (edit.liveGeometry! as DrawingPolygon).coordinates.first.length;
      final vertexHit = edit.findEditVertexNear(const LatLng(-0.01, -0.01), 50);
      expect(vertexHit, isNotNull);
      expect(
        (edit.liveGeometry! as DrawingPolygon).coordinates.first.length,
        afterInsert,
      );

      // --- Host do mapa: gota por overlay, sem congelar gestos (#172) ---
      final orchestrator = File(
        'lib/ui/screens/map/widgets/map_build_orchestrator.dart',
      ).readAsStringSync();
      expect(orchestrator.contains('freezeMapGestures'), isFalse);
      expect(orchestrator.contains('InteractiveFlag.none'), isFalse);
      expect(orchestrator, contains('DrawingVertexHandleOverlay'));
      expect(orchestrator, contains('applyEditMapTap'));
      expect(orchestrator, contains('editVertexHitPx'));
      expect(orchestrator, contains('editEdgeHitPx'));

      final editLayer = File(
        'lib/modules/drawing/presentation/widgets/drawing_edit_layer.dart',
      ).readAsStringSync();
      expect(editLayer.contains('_MidpointHandle'), isFalse);

      // --- Arraste da gota com mapa interativo (pan não desligado) ---
      final mapController = MapController();
      var mapFlags = InteractiveFlag.all;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: edit,
              builder: (context, _) {
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: const LatLng(0, 0),
                        initialZoom: 13,
                        interactionOptions: InteractionOptions(flags: mapFlags),
                      ),
                      children: [
                        DrawingEditLayer(
                          controller: edit,
                          mapController: mapController,
                        ),
                      ],
                    ),
                    DrawingVertexHandleOverlay(
                      controller: edit,
                      mapController: mapController,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      edit.selectEditVertex(0, 0);
      await tester.pumpAndSettle();
      expect(mapFlags, InteractiveFlag.all);

      final beforeDrag =
          (edit.liveGeometry! as DrawingPolygon).coordinates.first.first;
      final handle = find.byKey(const Key('drawing_vertex_hit_0_0'));
      await tester.timedDrag(
        handle,
        const Offset(64, 48),
        const Duration(milliseconds: 300),
      );
      await tester.pumpAndSettle();

      expect(mapFlags, InteractiveFlag.all);
      final afterDrag =
          (edit.liveGeometry! as DrawingPolygon).coordinates.first.first;
      expect(afterDrag, isNot(equals(beforeDrag)));

      edit.dispose();
    },
  );
}
