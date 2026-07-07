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

    test('pivô: centro + raio gera círculo e metadados', () {
      controller.selectTool('pivot');
      controller.handlePivotTap(const LatLng(-15.0, -47.0));
      expect(controller.pivotCenter, isNotNull);
      expect(controller.currentState, DrawingState.drawing);

      controller.finalizePivotEdge(const LatLng(-15.001, -47.0));

      expect(controller.currentState, DrawingState.reviewing);
      expect(controller.liveGeometry, isNotNull);
      expect(controller.pendingDrawingSubtipo, 'pivo');
      expect(controller.pendingDrawingRaioMetros, greaterThan(0));
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

    test('instructionText diferencia ferramentas', () {
      controller.selectTool('freehand');
      expect(controller.instructionText, contains('arraste'));

      controller.selectTool('pivot');
      expect(controller.instructionText, contains('centro'));
    });
  });
}
