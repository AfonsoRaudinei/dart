import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_visual_style.dart';
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

  group('ferramenta Teste', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: _MockRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('selectTool teste arma polígono e o tipo fica teste na revisão', () {
      controller.selectTool('teste');

      expect(controller.currentTool, DrawingTool.polygon);
      expect(controller.isSketchingTest, isTrue);
      expect(controller.currentState, DrawingState.armed);
      expect(controller.pendingDrawingType, DrawingType.talhao);

      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));

      expect(controller.currentState, DrawingState.drawing);
      expect(controller.liveGeometry, isNotNull);
      expect(controller.pendingDrawingType, DrawingType.teste);

      controller.completeDrawing();

      expect(controller.currentState, DrawingState.reviewing);
      expect(controller.isSketchingTest, isTrue);
      expect(controller.pendingDrawingType, DrawingType.teste);
    });

    test('selectTool polygon desliga o flag de teste', () {
      controller.selectTool('teste');
      expect(controller.isSketchingTest, isTrue);

      controller.selectTool('polygon');

      expect(controller.currentTool, DrawingTool.polygon);
      expect(controller.isSketchingTest, isFalse);
      expect(controller.pendingDrawingType, DrawingType.talhao);
    });
  });

  group('validateTopology — teste sobre talhão', () {
    final talhao = _feature(
      id: 'talhao',
      tipo: DrawingType.talhao,
      ring: _outer,
    );
    final testeSalvo = _feature(
      id: 'teste-salvo',
      tipo: DrawingType.teste,
      ring: _outer,
    );
    final sobreposto = DrawingPolygon(coordinates: [_inner]);

    test('teste com skip ligado pode cobrir um talhão', () {
      final result = DrawingUtils.validateTopology(
        sobreposto,
        existingFeatures: [talhao],
        skipOverlapChecks: true,
      );

      expect(result.isValid, isTrue);
    });

    test('talhão sobre outro talhão continua inválido', () {
      final result = DrawingUtils.validateTopology(
        sobreposto,
        existingFeatures: [talhao],
      );

      expect(result.isValid, isFalse);
      expect(result.message, contains('sobreposição'));
    });

    test('talhão que só cobre um teste é válido', () {
      final result = DrawingUtils.validateTopology(
        sobreposto,
        existingFeatures: [testeSalvo],
      );

      expect(result.isValid, isTrue);
    });
  });

  group('estilo do teste', () {
    test('preenchimento é azul Samsung e não o verde de Bom', () {
      final teste = _feature(
        id: 'teste',
        tipo: DrawingType.teste,
        ring: _outer,
        cor: TalhaoCondicao.bom.argb,
      );

      expect(teste.style.fillColor, const Color(0xFF1428A0));
      expect(teste.style.fillColor, isNot(Color(TalhaoCondicao.bom.argb)));
      expect(teste.style.fillOpacity, 0.45);

      final sincronizando = _feature(
        id: 'teste-sync',
        tipo: DrawingType.teste,
        ring: _outer,
        cor: TalhaoCondicao.ruim.argb,
        syncStatus: SyncStatus.pending_sync,
      );

      expect(sincronizando.style.fillColor, const Color(0xFF1428A0));
      expect(
        sincronizando.style.fillColor,
        isNot(Color(TalhaoCondicao.ruim.argb)),
      );
      expect(sincronizando.style.isDashed, isTrue);
    });
  });
}

const _outer = <List<double>>[
  [0.0, 0.0],
  [2.0, 0.0],
  [2.0, 2.0],
  [0.0, 2.0],
  [0.0, 0.0],
];

const _inner = <List<double>>[
  [0.4, 0.4],
  [1.2, 0.4],
  [1.2, 1.2],
  [0.4, 1.2],
  [0.4, 0.4],
];

DrawingFeature _feature({
  required String id,
  required DrawingType tipo,
  required List<List<double>> ring,
  int? cor,
  SyncStatus syncStatus = SyncStatus.synced,
}) {
  final now = DateTime.utc(2026, 11, 12);
  return DrawingFeature(
    id: id,
    geometry: DrawingPolygon(coordinates: [ring]),
    properties: DrawingProperties(
      nome: id,
      tipo: tipo,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.aprovado,
      autorId: 'user',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: syncStatus,
      cor: cor,
    ),
  );
}
