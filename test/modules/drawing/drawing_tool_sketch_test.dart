import 'dart:math' show Point;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

class _MockRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}
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

  group('Drawing tools — freehand e pivô', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: _MockRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('freehand: traço contínuo gera polígono fechado após soltar', () {
      controller.selectTool('freehand');
      controller.beginFreehandStroke(const LatLng(-15.0, -47.0));
      controller.extendFreehandStroke(const LatLng(-15.001, -47.0));
      controller.extendFreehandStroke(const LatLng(-15.001, -47.001));
      controller.extendFreehandStroke(const LatLng(-15.0, -47.001));
      controller.endFreehandStroke();

      expect(controller.currentState, DrawingState.drawing);
      expect(controller.isFreehandStrokeActive, isFalse);
      expect(controller.liveGeometry, isNotNull);
      expect(controller.canFinishDrawing, isTrue);
    });

    test('freehand: traço curto é rejeitado', () {
      controller.selectTool('freehand');
      controller.beginFreehandStroke(const LatLng(-15.0, -47.0));
      controller.extendFreehandStroke(const LatLng(-15.0001, -47.0001));
      controller.endFreehandStroke();

      expect(controller.freehandPointCount, 0);
      expect(controller.errorMessage, isNotNull);
    });

    test('pivô: centro + raio gera círculo ajustável antes da revisão', () {
      controller.selectTool('pivot');
      controller.handlePivotTap(const LatLng(-15.0, -47.0));
      expect(controller.pivotCenter, isNotNull);
      expect(controller.currentState, DrawingState.drawing);

      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));

      final firstRadius = controller.pivotRadiusMeters;
      expect(controller.currentState, DrawingState.drawing);
      expect(controller.liveGeometry, isNotNull);
      expect(controller.canFinishDrawing, isTrue);
      expect(firstRadius, greaterThan(0));

      controller.updatePivotEdge(const LatLng(-15.002, -47.0));

      expect(controller.currentState, DrawingState.drawing);
      expect(controller.pivotRadiusMeters, greaterThan(firstRadius!));

      controller.completeDrawing();

      expect(controller.currentState, DrawingState.reviewing);
      expect(controller.pendingDrawingSubtipo, 'pivo');
      expect(controller.pendingDrawingRaioMetros, greaterThan(0));
    });

    test('pivô: mover o centro preserva o raio e desloca a borda', () {
      controller.selectTool('pivot');
      const oldCenter = LatLng(-15.0, -47.0);
      controller.handlePivotTap(oldCenter);
      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));

      final radius = controller.pivotRadiusMeters;
      final oldEdge = controller.pivotEdgePoint!;
      const newCenter = LatLng(-15.01, -47.02);
      final distance = const Distance();
      final expectedEdge = distance.offset(
        newCenter,
        radius!,
        distance.bearing(oldCenter, oldEdge),
      );

      controller.movePivotCenter(newCenter);

      expect(controller.pivotRadiusMeters, radius);
      expect(controller.pivotCenter, newCenter);
      expect(controller.pivotCenter, isNot(oldCenter));
      expect(controller.pivotEdgePoint, isNot(oldEdge));
      expect(
        controller.pivotEdgePoint!.latitude,
        closeTo(expectedEdge.latitude, 1e-8),
      );
      expect(
        controller.pivotEdgePoint!.longitude,
        closeTo(expectedEdge.longitude, 1e-8),
      );

      expect(controller.pivotAdjustUiVisible, isFalse);
      controller.handlePivotTap(newCenter);
      expect(controller.pivotAdjustUiVisible, isTrue);
      expect(
        controller.instructionText,
        'Arraste a cruz para mover o centro ou o ponto na borda para o raio',
      );
      expect(
        controller.finishDrawingHint,
        'Arraste a cruz para mover o centro ou o ponto na borda para o raio',
      );

      final ring =
          (controller.liveGeometry as DrawingPolygon).coordinates.first;
      final sample = LatLng(ring.first[1], ring.first[0]);
      final fromNew = distance.as(LengthUnit.Meter, newCenter, sample);
      final fromOld = distance.as(LengthUnit.Meter, oldCenter, sample);
      expect(fromNew, lessThan(fromOld));
    });

    test('pivô: mover a borda mantém o centro e altera o raio', () {
      controller.selectTool('pivot');
      controller.handlePivotTap(const LatLng(-15.0, -47.0));
      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));

      final center = controller.pivotCenter;
      final radius = controller.pivotRadiusMeters!;
      controller.updatePivotEdge(const LatLng(-15.003, -47.0));

      expect(controller.pivotCenter, center);
      expect(controller.pivotRadiusMeters, greaterThan(radius));
      expect(controller.currentState, DrawingState.drawing);
    });

    test('pivô salvo: edição regenera o círculo e grava o raio novo', () async {
      const storedRadius = 400.0;
      final saved = await controller.addFeature(
        geometry: DrawingPolygon(
          coordinates: [
            [
              [-47.0, -15.0],
              [-47.01, -15.0],
              [-47.01, -15.01],
              [-47.0, -15.01],
              [-47.0, -15.0],
            ],
          ],
        ),
        nome: 'Pivô Norte',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'tester',
        autorTipo: AuthorType.consultor,
        subtipo: 'pivo',
        raioMetros: storedRadius,
      );
      expect(saved, isNotNull);

      controller.startEditMode();

      expect(controller.currentState, DrawingState.editing);
      expect(controller.isEditingPivot, isTrue);
      expect(controller.pivotRadiusMeters, closeTo(storedRadius, 0.001));
      final center = controller.pivotCenter!;
      final regenerated = controller.liveGeometry as DrawingPolygon;
      final expected = DrawingUtils.createPivotPolygon(center, storedRadius);
      expect(
        regenerated.coordinates.first.length,
        expected.coordinates.first.length,
      );
      expect(regenerated.coordinates.first.length, greaterThan(16));
      for (var i = 0; i < expected.coordinates.first.length; i++) {
        expect(
          regenerated.coordinates.first[i][0],
          closeTo(expected.coordinates.first[i][0], 1e-9),
        );
        expect(
          regenerated.coordinates.first[i][1],
          closeTo(expected.coordinates.first[i][1], 1e-9),
        );
      }

      final areaBefore = controller.liveAreaHa;
      const movedCenter = LatLng(-15.2, -47.2);
      final edgeBefore = controller.pivotEdgePoint!;
      controller.moveEditPivotCenter(movedCenter);

      expect(controller.pivotRadiusMeters, closeTo(storedRadius, 0.001));
      expect(controller.pivotCenter, movedCenter);
      expect(controller.pivotCenter, isNot(center));
      expect(controller.pivotEdgePoint, isNot(edgeBefore));

      final radiusBeforeEdge = controller.pivotRadiusMeters!;
      final centerBeforeEdge = controller.pivotCenter!;
      controller.updateEditPivotEdge(
        LatLng(centerBeforeEdge.latitude + 0.02, centerBeforeEdge.longitude),
      );

      expect(controller.pivotCenter!.latitude, centerBeforeEdge.latitude);
      expect(controller.pivotCenter!.longitude, centerBeforeEdge.longitude);
      expect(controller.pivotRadiusMeters, greaterThan(radiusBeforeEdge));
      expect(controller.liveAreaHa, greaterThan(areaBefore));

      final newRadius = controller.pivotRadiusMeters!;
      final areaAfter = controller.liveAreaHa;
      final savedOk = await controller.saveEdit();

      expect(savedOk, isTrue);
      final persisted = controller.selectedFeature!;
      expect(persisted.isPivot, isTrue);
      expect(persisted.properties.subtipo, 'pivo');
      expect(persisted.properties.raioMetros, closeTo(newRadius, 1e-6));
      expect(persisted.properties.areaHa, closeTo(areaAfter, 0.01));
      expect(persisted.properties.areaHa, greaterThan(areaBefore));
      expect(
        (persisted.geometry as DrawingPolygon).coordinates.first.length,
        greaterThan(16),
      );
    });

    test('pivô salvo: undo e redo acompanham centro e raio', () async {
      final saved = await controller.addFeature(
        geometry: DrawingUtils.createPivotPolygon(
          const LatLng(-15.0, -47.0),
          400,
        ),
        nome: 'Pivô Undo',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'tester',
        autorTipo: AuthorType.consultor,
        subtipo: 'pivo',
        raioMetros: 400,
      );
      expect(saved, isNotNull);
      controller.startEditMode();

      final initialCenter = controller.pivotCenter!;
      final initialRadius = controller.pivotRadiusMeters!;
      const moved = LatLng(-15.2, -47.2);
      controller.moveEditPivotCenter(moved);
      controller.finishEditPivotGesture();

      expect(controller.canUndo, isTrue);
      controller.undoEdit();

      expect(
        controller.pivotCenter!.latitude,
        closeTo(initialCenter.latitude, 1e-5),
      );
      expect(
        controller.pivotCenter!.longitude,
        closeTo(initialCenter.longitude, 1e-5),
      );
      expect(controller.pivotRadiusMeters, closeTo(initialRadius, 2));
      expect(controller.pivotEdgePoint, isNotNull);

      controller.redoEdit();
      expect(controller.pivotCenter!.latitude, closeTo(moved.latitude, 1e-5));
      expect(controller.pivotCenter!.longitude, closeTo(moved.longitude, 1e-5));
      expect(controller.pivotRadiusMeters, closeTo(initialRadius, 2));
    });

    test('pivô: desfaz raio e centro sem entrar em edição', () {
      controller.selectTool('pivot');
      controller.handlePivotTap(const LatLng(-15.0, -47.0));
      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));

      expect(controller.currentState, DrawingState.drawing);
      expect(controller.pivotRadiusFinalized, isTrue);

      controller.undoDrawingPoint();

      expect(controller.currentState, DrawingState.drawing);
      expect(controller.pivotCenter, isNotNull);
      expect(controller.pivotEdgePoint, isNull);
      expect(controller.pivotRadiusFinalized, isFalse);

      controller.undoDrawingPoint();

      expect(controller.pivotCenter, isNull);
      expect(controller.pivotEdgePoint, isNull);
      expect(controller.canFinishDrawing, isFalse);
    });

    test('polígono: continua exigindo vértices discretos', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));

      expect(controller.currentTool, DrawingTool.polygon);
      expect(controller.canFinishDrawing, isFalse);

      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
      expect(controller.canFinishDrawing, isTrue);
    });

    test('polígono: seleciona e move vértice mid-draw sem sair de drawing', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));

      expect(controller.selectSketchVertex(1), isTrue);
      expect(controller.selectedSketchVertexIndex, 1);
      expect(controller.currentState, DrawingState.drawing);

      const moved = LatLng(-15.002, -47.0005);
      expect(controller.moveSketchVertex(1, moved), isTrue);
      expect(controller.currentPoints[1], moved);
      expect(controller.currentState, DrawingState.drawing);
      expect(controller.selectedSketchVertexIndex, 1);
    });

    test('polígono: novo ponto limpa seleção de vértice', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.selectSketchVertex(0);

      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));

      expect(controller.selectedSketchVertexIndex, isNull);
      expect(controller.currentState, DrawingState.drawing);
    });

    test('polígono: clearSketchVertexSelection libera novo ponto', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.selectSketchVertex(0);
      expect(controller.selectedSketchVertexIndex, 0);

      controller.clearSketchVertexSelection();
      expect(controller.selectedSketchVertexIndex, isNull);

      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
      expect(controller.currentPoints.length, 3);
      expect(controller.selectedSketchVertexIndex, isNull);
    });

    test('polígono: findSketchVertexIndexNear respeita tolerância', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));

      expect(
        controller.findSketchVertexIndexNear(const LatLng(-15.0, -47.0), 5.0),
        0,
      );
      expect(
        controller.findSketchVertexIndexNear(const LatLng(-15.001, -47.0), 5.0),
        1,
      );
      expect(
        controller.findSketchVertexIndexNear(const LatLng(-20.0, -50.0), 5.0),
        isNull,
      );
    });

    test(
      'polígono: toque na aresta oposta insere vértice mesmo com o último selecionado',
      () {
        controller.selectTool('polygon');
        const nw = LatLng(-15.002, -47.002);
        const ne = LatLng(-15.002, -46.998);
        const se = LatLng(-15.000, -46.998);
        const sw = LatLng(-15.000, -47.002);
        controller.appendDrawingPoint(nw);
        controller.appendDrawingPoint(ne);
        controller.appendDrawingPoint(se);
        controller.appendDrawingPoint(sw);
        expect(controller.selectSketchVertex(3), isTrue);

        final camera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(-15.001, -47.000),
          zoom: 16,
          rotation: 0,
          nonRotatedSize: const Point(1000, 1000),
        );
        const northMid = LatLng(-15.002, -47.000);

        expect(controller.applySketchMapTap(northMid, camera), isTrue);
        expect(controller.currentPoints.length, 5);
        expect(controller.currentPoints.last, sw);
        expect(controller.selectedSketchVertexIndex, 1);
        expect(
          controller.currentPoints[1].latitude,
          closeTo(nw.latitude, 0.0003),
        );
        expect(controller.currentState, DrawingState.drawing);
      },
    );

    test(
      'polígono: toque na aresta de fechamento insere antes de voltar ao início',
      () {
        controller.selectTool('polygon');
        const nw = LatLng(-15.002, -47.002);
        const ne = LatLng(-15.002, -46.998);
        const se = LatLng(-15.000, -46.998);
        controller.appendDrawingPoint(nw);
        controller.appendDrawingPoint(ne);
        controller.appendDrawingPoint(se);
        expect(controller.selectSketchVertex(2), isTrue);

        final camera = MapCamera(
          crs: const Epsg3857(),
          center: const LatLng(-15.001, -47.000),
          zoom: 16,
          rotation: 0,
          nonRotatedSize: const Point(1000, 1000),
        );
        final closeMid = LatLng(
          (se.latitude + nw.latitude) / 2,
          (se.longitude + nw.longitude) / 2,
        );

        expect(controller.applySketchMapTap(closeMid, camera), isTrue);
        expect(controller.currentPoints.length, 4);
        expect(controller.currentPoints[2], se);
        expect(controller.selectedSketchVertexIndex, 3);
        expect(
          controller.currentPoints[3].longitude,
          closeTo(closeMid.longitude, 0.0004),
        );
      },
    );

    test('polígono: beginSketchVertexDrag marca dragging sem notify', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.selectSketchVertex(1);

      var notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.beginSketchVertexDrag(1);
      expect(controller.isDraggingSketchVertex, isTrue);
      expect(controller.selectedSketchVertexIndex, 1);
      expect(notifyCount, 0);

      controller.endSketchVertexDrag();
      expect(controller.isDraggingSketchVertex, isFalse);
      expect(notifyCount, 1);
    });

    test('instructionText diferencia ferramentas', () {
      controller.selectTool('freehand');
      expect(controller.instructionText, contains('arraste'));

      controller.selectTool('pivot');
      expect(controller.instructionText, contains('centro'));
    });
  });
}
