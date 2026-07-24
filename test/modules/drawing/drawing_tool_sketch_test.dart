import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
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

    test('polígono: restoreSketchPoints reverte arraste cancelado', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));

      final snapshot = List<LatLng>.of(controller.currentPoints);
      controller.onDragStart(1);
      controller.moveSketchVertex(1, const LatLng(-15.5, -47.5));
      expect(controller.currentPoints[1], const LatLng(-15.5, -47.5));

      controller.restoreSketchPoints(snapshot);
      controller.onDragEnd(persist: false);

      expect(controller.currentPoints, snapshot);
      expect(controller.isDraggingVertex, isFalse);
    });

    test('polígono: moveSketchVertex ajusta ponto durante o desenho', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));

      controller.onDragStart(1);
      controller.moveSketchVertex(1, const LatLng(-15.002, -47.0));
      controller.onDragEnd(persist: false);

      expect(controller.isDraggingVertex, isFalse);
      expect(controller.currentPoints[1], const LatLng(-15.002, -47.0));
      expect(controller.currentPoints.length, 3);
      expect(controller.canFinishDrawing, isTrue);
    });

    test('polígono: não adiciona ponto enquanto arrasta vértice', () {
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));

      controller.onDragStart(0);
      controller.appendDrawingPoint(const LatLng(-15.5, -47.5));
      controller.onDragEnd(persist: false);

      expect(controller.currentPoints.length, 2);
    });

    test('pivô: movePivotCenter reposiciona centro e recalcula raio', () {
      controller.selectTool('pivot');
      controller.handlePivotTap(const LatLng(-15.0, -47.0));
      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));
      final radiusBefore = controller.pivotRadiusMeters!;

      // Desloca o centro em longitude para alterar a distância ao edge.
      controller.movePivotCenter(const LatLng(-15.0, -47.002));

      expect(controller.pivotCenter, const LatLng(-15.0, -47.002));
      expect(controller.pivotRadiusMeters, greaterThan(radiusBefore));
      expect(controller.canFinishDrawing, isTrue);
    });

    test('freehand: moveFreehandVertex ajusta trilha após soltar', () {
      controller.selectTool('freehand');
      controller.beginFreehandStroke(const LatLng(-15.0, -47.0));
      controller.extendFreehandStroke(const LatLng(-15.001, -47.0));
      controller.extendFreehandStroke(const LatLng(-15.001, -47.001));
      controller.extendFreehandStroke(const LatLng(-15.0, -47.001));
      controller.endFreehandStroke();

      final lastIndex = controller.freehandPointCount - 1;
      controller.moveFreehandVertex(lastIndex, const LatLng(-15.0005, -47.0015));

      expect(
        controller.freehandTrail[lastIndex],
        const LatLng(-15.0005, -47.0015),
      );
      expect(controller.canFinishDrawing, isTrue);
    });

    test('instructionText diferencia ferramentas', () {
      controller.selectTool('freehand');
      expect(controller.instructionText, contains('arraste'));

      controller.selectTool('pivot');
      expect(controller.instructionText, contains('centro'));
    });
  });
}
