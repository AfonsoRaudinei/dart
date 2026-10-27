import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_compact_ui_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';

class _MockDrawingRepository extends DrawingRepository {
  final List<DrawingFeature> features;

  _MockDrawingRepository(this.features);

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => features;

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}

  @override
  Future<void> deleteFeature(String id) async {}
}

DrawingFeature _selectedTalhao() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-1',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [-48.0, -10.0],
          [-47.99, -10.0],
          [-47.99, -9.99],
          [-48.0, -10.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão A',
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

  group('drawingCompactOpenMetadataProvider', () {
    testWidgets('pedido sticky no mount abre edição de metadados', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final feature = _selectedTalhao();
      final repository = _MockDrawingRepository([feature]);
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            drawingCompactOpenMetadataProvider.overrideWith((ref) => true),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DrawingSheet(controller: controller),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar Informações'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DrawingSheet)),
      );
      expect(container.read(drawingCompactOpenMetadataProvider), isFalse);
    });

    testWidgets('pedido após mount também abre edição de metadados', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final feature = _selectedTalhao();
      final repository = _MockDrawingRepository([feature]);
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);

      late ProviderContainer container;
      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return MaterialApp(
                home: Scaffold(
                  body: SingleChildScrollView(
                    child: DrawingSheet(controller: controller),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Editar Informações'), findsNothing);

      container.read(drawingCompactOpenMetadataProvider.notifier).state = true;
      await tester.pumpAndSettle();

      expect(find.text('Editar Informações'), findsOneWidget);
      expect(container.read(drawingCompactOpenMetadataProvider), isFalse);
    });
  });
}
