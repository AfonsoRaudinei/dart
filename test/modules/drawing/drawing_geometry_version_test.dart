import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

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

  test('soltar vértice não cria outra versão ativa', () async {
    final original = _feature(id: 'talhao-a');
    final repository = _MemoryDrawingRepository([original]);
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();

    controller.selectFeature(controller.features.single);
    controller.startEditMode();
    controller.updateVertexPosition(0, 0, const LatLng(0.02, -0.02));

    expect(controller.features, hasLength(1));
    expect(controller.features.single.id, 'talhao-a');
    expect(repository.active.map((feature) => feature.id), ['talhao-a']);
  });

  test('dois saveEdit seguidos deixam uma versão ativa', () async {
    final original = _feature(id: 'talhao-a');
    final repository = _MemoryDrawingRepository([
      original,
    ], delay: const Duration(milliseconds: 30));
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();

    controller.selectFeature(controller.features.single);
    controller.startEditMode();
    controller.updateVertexPosition(0, 1, const LatLng(0.03, -0.01));

    final first = controller.saveEdit();
    final second = controller.saveEdit();
    await Future.wait([first, second]);

    expect(repository.active, hasLength(1));
    expect(repository.active.single.id, isNot('talhao-a'));
    expect(
      repository.rows
          .singleWhere((feature) => feature.id == 'talhao-a')
          .properties
          .ativo,
      isFalse,
    );
    expect(controller.features, hasLength(1));
  });

  test('carga desativa a versão antiga da mesma cadeia', () async {
    final older = _feature(id: 'talhao-antigo', areaHa: 519.627);
    final newer = _feature(
      id: 'talhao-novo',
      areaHa: 236.610,
      versao: 2,
      versaoAnteriorId: 'talhao-antigo',
    );
    final repository = _MemoryDrawingRepository([older, newer]);
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadFeatures();

    expect(controller.features.map((feature) => feature.id), ['talhao-novo']);
    expect(
      repository.rows
          .singleWhere((feature) => feature.id == 'talhao-antigo')
          .properties
          .ativo,
      isFalse,
    );
    expect(repository.active.single.id, 'talhao-novo');
  });
}

class _MemoryDrawingRepository extends DrawingRepository {
  _MemoryDrawingRepository(this.rows, {this.delay = Duration.zero});

  final List<DrawingFeature> rows;
  final Duration delay;

  List<DrawingFeature> get active =>
      rows.where((feature) => feature.properties.ativo).toList();

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => active;

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final index = rows.indexWhere((item) => item.id == feature.id);
    if (index == -1) {
      rows.add(feature);
    } else {
      rows[index] = feature;
    }
  }
}

DrawingFeature _feature({
  required String id,
  double areaHa = 10,
  int versao = 1,
  String? versaoAnteriorId,
}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: id,
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
      nome: 'Talhão Novo',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: areaHa,
      versao: versao,
      versaoAnteriorId: versaoAnteriorId,
      ativo: true,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.local_only,
    ),
  );
}
