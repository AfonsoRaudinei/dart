import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_import_service.dart';
import 'package:soloforte_app/modules/drawing/infra/file_picker/i_file_picker.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';

class _Picker implements IFilePicker {
  const _Picker(this.file);

  final PlatformFile file;

  @override
  Future<PlatformFile?> pickSingleFile({
    required List<String> allowedExtensions,
  }) async => file;
}

class _Repository extends DrawingRepository {
  final features = <DrawingFeature>[];

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => List.of(features);

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    features.add(feature);
  }

  @override
  Future<double> getTotalAreaByClienteId(String clienteId) async => features
      .fold<double>(0.0, (total, feature) => total + feature.properties.areaHa);

  @override
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {}
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

  test(
    'salva KML importado com sobreposição sem bloquear confirmação',
    () async {
      final repository = _Repository()..features.add(_existingFeature());
      final file = await _overlappingKml();
      final controller = DrawingController(
        repository: repository,
        importService: DrawingImportService(_Picker(file)),
      );
      addTearDown(controller.dispose);
      await controller.loadFeatures();

      controller.startImportMode();
      await controller.pickImportFile();
      expect(controller.validationResult.isValid, isFalse);
      expect(controller.validationResult.message, contains('sobreposição'));
      expect(controller.hasPendingImportWarning, isTrue);
      expect(
        controller.pendingImportWarningMessage,
        contains('sobrepõe uma área existente'),
      );

      controller.confirmImport();
      expect(
        controller.intersectionWarningMessage,
        contains('sobrepõe uma área existente'),
      );

      final geometry = controller.liveGeometry;
      expect(geometry, isNotNull);
      await controller.addFeature(
        geometry: geometry!,
        nome: 'Importado Fields',
        tipo: DrawingType.talhao,
        origem: controller.pendingImportOrigin!,
        autorId: 'test',
        autorTipo: AuthorType.sistema,
        clienteId: 'cliente',
      );

      expect(repository.features, hasLength(2));
      expect(controller.features, hasLength(2));
    },
  );

  test(
    'salva KML importado com auto-interseção como warning não bloqueante',
    () async {
      final repository = _Repository();
      final file = await _selfIntersectingKml();
      final controller = DrawingController(
        repository: repository,
        importService: DrawingImportService(_Picker(file)),
      );
      addTearDown(controller.dispose);
      await controller.loadFeatures();

      controller.startImportMode();
      await controller.pickImportFile();
      expect(controller.validationResult.isValid, isFalse);
      expect(controller.validationResult.message, contains('cruz'));
      expect(controller.hasPendingImportWarning, isTrue);
      expect(
        controller.pendingImportWarningMessage,
        contains('geometria importada se cruzam'),
      );

      controller.confirmImport();
      expect(
        controller.intersectionWarningMessage,
        contains('geometria importada se cruzam'),
      );

      final geometry = controller.liveGeometry;
      expect(geometry, isNotNull);
      await controller.addFeature(
        geometry: geometry!,
        nome: 'Importado cruzado',
        tipo: DrawingType.talhao,
        origem: controller.pendingImportOrigin!,
        autorId: 'test',
        autorTipo: AuthorType.sistema,
        clienteId: 'cliente',
      );

      expect(repository.features, hasLength(1));
      expect(controller.features, hasLength(1));
    },
  );

  test('desenho manual com sobreposição continua bloqueado', () async {
    final repository = _Repository()..features.add(_existingFeature());
    final controller = DrawingController(repository: repository);
    addTearDown(controller.dispose);
    await controller.loadFeatures();

    await controller.addFeature(
      geometry: DrawingPolygon(
        coordinates: [
          [
            [1, 1],
            [3, 1],
            [3, 3],
            [1, 3],
            [1, 1],
          ],
        ],
      ),
      nome: 'Manual sobreposto',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      autorId: 'test',
      autorTipo: AuthorType.sistema,
      clienteId: 'cliente',
    );

    expect(controller.errorMessage, contains('sobreposição'));
    expect(repository.features, hasLength(1));
    expect(controller.features, hasLength(1));
  });

  test(
    'desenho manual com auto-interseção continua com warning em revisão',
    () async {
      final controller = DrawingController(repository: _Repository());
      addTearDown(controller.dispose);
      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(0, 0));
      controller.appendDrawingPoint(const LatLng(2, 2));
      controller.appendDrawingPoint(const LatLng(0, 2));
      controller.appendDrawingPoint(const LatLng(2, 0));
      controller.completeDrawing();

      expect(
        controller.intersectionWarningMessage,
        contains('Salve e edite os vértices depois'),
      );
      expect(controller.errorMessage, isNull);
    },
  );
}

Future<PlatformFile> _overlappingKml() async {
  const content = '''<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>
    1,1,0 3,1,0 3,3,0 1,3,0 1,1,0
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
</kml>''';
  final dir = await Directory.systemTemp.createTemp('drawing_overlap_');
  final file = File('${dir.path}/overlap.kml');
  await file.writeAsString(content);
  return PlatformFile(
    name: 'overlap.kml',
    size: content.length,
    path: file.path,
  );
}

Future<PlatformFile> _selfIntersectingKml() async {
  const content = '''<kml xmlns="http://www.opengis.net/kml/2.2">
  <Placemark><Polygon><outerBoundaryIs><LinearRing><coordinates>
    0,0,0 2,2,0 0,2,0 2,0,0 0,0,0
  </coordinates></LinearRing></outerBoundaryIs></Polygon></Placemark>
</kml>''';
  final dir = await Directory.systemTemp.createTemp('drawing_self_intersect_');
  final file = File('${dir.path}/self_intersect.kml');
  await file.writeAsString(content);
  return PlatformFile(
    name: 'self_intersect.kml',
    size: content.length,
    path: file.path,
  );
}

DrawingFeature _existingFeature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'existing',
    geometry: DrawingPolygon(
      coordinates: [
        [
          [0, 0],
          [2, 0],
          [2, 2],
          [0, 2],
          [0, 0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Existente',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'test',
      autorTipo: AuthorType.sistema,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
