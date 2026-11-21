import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_bottom_toolbar.dart';

const _pentagon = <List<double>>[
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.915, -15.775],
  [-47.92, -15.77],
  [-47.93, -15.77],
  [-47.93, -15.78],
];

const _triangle = <List<double>>[
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.925, -15.77],
  [-47.93, -15.78],
];

class _Repository extends DrawingRepository {
  _Repository([this.features = const []]);

  final List<DrawingFeature> features;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => features;

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}
}

DrawingFeature _feature(String id, List<List<double>> ring) {
  final now = DateTime(2026, 10, 28);
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(coordinates: [ring]),
    properties: DrawingProperties(
      nome: 'Talhão $id',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 100,
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

  group('removeSketchVertex', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: _Repository());
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.0, -47.01));
      controller.appendDrawingPoint(const LatLng(-15.01, -47.01));
      controller.appendDrawingPoint(const LatLng(-15.01, -47.0));
    });

    tearDown(() => controller.dispose());

    test('remove vértice do meio e limpa a seleção', () {
      controller.selectSketchVertex(1);
      expect(controller.canRemoveSelectedVertex, isTrue);

      expect(controller.removeSketchVertex(1), isTrue);

      expect(controller.currentPoints, hasLength(3));
      expect(controller.currentPoints[1], const LatLng(-15.01, -47.01));
      expect(controller.selectedSketchVertexIndex, isNull);
      expect(controller.canRemoveSelectedVertex, isFalse);
      expect(controller.currentState, DrawingState.drawing);
    });

    test('esvaziar o sketch volta para idle', () {
      for (var i = 0; i < 4; i++) {
        expect(controller.removeSketchVertex(0), isTrue);
      }

      expect(controller.currentPoints, isEmpty);
      expect(controller.currentState, DrawingState.idle);
    });

    test('índice inválido retorna false e mantém os pontos', () {
      expect(controller.removeSketchVertex(-1), isFalse);
      expect(controller.removeSketchVertex(4), isFalse);
      expect(controller.currentPoints, hasLength(4));
    });

    test('removeSelectedVertex exclui o vértice selecionado do sketch', () {
      controller.selectSketchVertex(2);

      controller.removeSelectedVertex();

      expect(controller.currentPoints, hasLength(3));
      expect(controller.selectedSketchVertexIndex, isNull);
    });

    test('removeSelectedVertex sem seleção não altera o sketch', () {
      controller.removeSelectedVertex();

      expect(controller.currentPoints, hasLength(4));
    });

    test('canRemoveSelectedVertex é falso fora do polígono', () {
      final other = DrawingController(repository: _Repository());
      addTearDown(other.dispose);
      other.selectTool('freehand');

      expect(other.canRemoveSelectedVertex, isFalse);
      expect(other.removeSketchVertex(0), isFalse);
    });
  });

  group('removeSelectedVertex na edição', () {
    late DrawingController controller;

    Future<void> startEdit(DrawingFeature feature) async {
      controller = DrawingController(repository: _Repository([feature]));
      await controller.loadFeatures();
      await Future<void>.delayed(Duration.zero);
      controller.selectFeature(controller.features.first);
      controller.startEditMode();
      expect(controller.currentState, DrawingState.editing);
    }

    List<List<double>> outerRing() =>
        (controller.liveGeometry! as DrawingPolygon).coordinates.first;

    tearDown(() => controller.dispose());

    test('remove o vértice selecionado e limpa a seleção', () async {
      await startEdit(_feature('pentagono', _pentagon));
      expect(outerRing(), hasLength(6));

      expect(controller.selectEditVertex(0, 2), isTrue);
      expect(controller.canRemoveSelectedVertex, isTrue);

      controller.removeSelectedVertex();

      final ring = outerRing();
      expect(ring, hasLength(5));
      expect(ring.first, ring.last);
      expect(ring.any((p) => p[0] == -47.915 && p[1] == -15.775), isFalse);
      expect(controller.selectedEditRingIndex, isNull);
      expect(controller.selectedEditPointIndex, isNull);
      expect(controller.canRemoveSelectedVertex, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('remover o primeiro vértice mantém o anel fechado', () async {
      await startEdit(_feature('pentagono', _pentagon));

      controller.selectEditVertex(0, 0);
      controller.removeSelectedVertex();

      final ring = outerRing();
      expect(ring, hasLength(5));
      expect(ring.first, ring.last);
      expect(ring.first, [-47.92, -15.78]);
    });

    test('undoEdit restaura o vértice removido e redoEdit refaz', () async {
      await startEdit(_feature('pentagono', _pentagon));
      final original = outerRing().map((p) => [...p]).toList();

      controller.selectEditVertex(0, 2);
      controller.removeSelectedVertex();
      expect(outerRing(), hasLength(5));
      expect(controller.canUndo, isTrue);

      controller.undoEdit();
      expect(outerRing(), original);

      controller.redoEdit();
      expect(outerRing(), hasLength(5));
    });

    test('duas remoções seguidas desfazem uma por vez', () async {
      await startEdit(_feature('pentagono', _pentagon));

      controller.selectEditVertex(0, 2);
      controller.removeSelectedVertex();
      controller.selectEditVertex(0, 1);
      controller.removeSelectedVertex();
      expect(outerRing(), hasLength(4));

      controller.undoEdit();
      expect(outerRing(), hasLength(5));
      controller.undoEdit();
      expect(outerRing(), hasLength(6));
    });

    test(
      'remover após arrasto e toque em outro vértice não cria passo de undo morto',
      () async {
        await startEdit(_feature('pentagono', _pentagon));
        final initial = outerRing().map((p) => [...p]).toList();

        controller.beginEditVertexDrag(1);
        controller.updateVertexPosition(0, 1, const LatLng(-15.79, -47.91));
        controller.onDragEnd();
        final dragged = outerRing().map((p) => [...p]).toList();
        expect(dragged, isNot(initial));

        controller.beginEditVertexDrag(2);
        controller.onDragEnd();
        controller.selectEditVertex(0, 2);
        controller.removeSelectedVertex();
        expect(outerRing(), hasLength(5));

        controller.undoEdit();
        expect(outerRing(), dragged);

        controller.undoEdit();
        expect(outerRing(), initial);
        expect(controller.canUndo, isFalse);
      },
    );

    test('anel mínimo gera errorMessage e mantém a geometria', () async {
      await startEdit(_feature('triangulo', _triangle));
      final before = outerRing().map((p) => [...p]).toList();

      controller.selectEditVertex(0, 1);
      controller.removeSelectedVertex();

      expect(
        controller.errorMessage,
        'A área precisa ter pelo menos 3 pontos.',
      );
      expect(outerRing(), before);
      expect(controller.canUndo, isFalse);
    });

    test('remover não deixa o arrasto de vértice preso', () async {
      await startEdit(_feature('pentagono', _pentagon));

      controller.selectEditVertex(0, 2);
      controller.removeSelectedVertex();

      expect(controller.isDraggingVertex, isFalse);
    });

    test(
      'removeVertex ignora índice fora do anel ou ponto de fechamento',
      () async {
        await startEdit(_feature('pentagono', _pentagon));

        controller.removeVertex(0, 5);
        controller.removeVertex(0, 99);
        controller.removeVertex(3, 0);
        controller.removeVertex(-1, 0);
        controller.removeVertex(0, -1);

        expect(outerRing(), hasLength(6));
        expect(controller.canUndo, isFalse);
      },
    );

    test('canRemoveSelectedVertex é falso sem seleção', () async {
      await startEdit(_feature('pentagono', _pentagon));

      expect(controller.canRemoveSelectedVertex, isFalse);
      controller.removeSelectedVertex();
      expect(outerRing(), hasLength(6));
    });

    test('canRemoveSelectedVertex é falso em pivô', () async {
      controller = DrawingController(repository: _Repository());
      final saved = await controller.addFeature(
        geometry: DrawingPolygon(coordinates: [_pentagon]),
        nome: 'Pivô Norte',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.desenho_manual,
        autorId: 'tester',
        autorTipo: AuthorType.consultor,
        subtipo: 'pivo',
        raioMetros: 400,
      );
      expect(saved, isNotNull);
      controller.startEditMode();
      expect(controller.isEditingPivot, isTrue);

      controller.selectEditVertex(0, 0);

      expect(controller.canRemoveSelectedVertex, isFalse);
      final before = outerRing().length;
      controller.removeSelectedVertex();
      expect(outerRing(), hasLength(before));
    });
  });

  group('DrawingBottomToolbar — Excluir ponto', () {
    Future<void> pump(
      WidgetTester tester, {
      VoidCallback? onRemoveVertex,
      bool canRemoveVertex = false,
      VoidCallback? onStartHoleCut,
      bool showRemoveHoleRing = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: DrawingBottomToolbar(
                onConfirm: () {},
                onUndo: () {},
                onCancel: () {},
                canUndo: false,
                onRemoveVertex: onRemoveVertex,
                canRemoveVertex: canRemoveVertex,
                onStartHoleCut: onStartHoleCut,
                showRemoveHoleRing: showRemoveHoleRing,
                onRemoveHoleRing: () {},
                canRemoveHoleRing: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('não aparece sem callback', (tester) async {
      await pump(tester);

      expect(find.text('Excluir ponto'), findsNothing);
    });

    testWidgets('fica desabilitado sem seleção e não dispara', (tester) async {
      var calls = 0;
      await pump(tester, onRemoveVertex: () => calls++);

      expect(find.text('Excluir ponto'), findsOneWidget);
      await tester.tap(find.text('Excluir ponto'));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('habilitado com seleção dispara o callback', (tester) async {
      var calls = 0;
      await pump(tester, onRemoveVertex: () => calls++, canRemoveVertex: true);

      await tester.tap(find.text('Excluir ponto'));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('convive com Recortar e Excluir recorte', (tester) async {
      await pump(
        tester,
        onRemoveVertex: () {},
        canRemoveVertex: true,
        onStartHoleCut: () {},
        showRemoveHoleRing: true,
      );

      expect(find.text('Recortar'), findsOneWidget);
      expect(find.text('Excluir ponto'), findsOneWidget);
      expect(find.text('Excluir recorte'), findsOneWidget);
    });
  });
}
