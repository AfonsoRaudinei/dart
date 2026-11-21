import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/infra/clients/i_clients_repository_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';

class _MockDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];
}

class _ClientsRepository implements IClientsRepository {
  @override
  Future<List<Client>> getClients() async => const [
        Client(id: 'c1', name: 'Cliente Teste'),
      ];

  @override
  Future<List<Farm>> getFarms(String clientId) async => const [];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
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

  testWidgets('revisão de campo teste mostra seção de foto e título Salvar teste', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

    controller.selectTool('teste');
    controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
    controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
    controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
    controller.completeDrawing();
    expect(controller.currentState, DrawingState.reviewing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingClientsRepositoryProvider.overrideWithValue(_ClientsRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 2000,
              child: DrawingSheet(
                controller: controller,
                onClose: () {},
                onSaved: (_, {campoTestPhoto}) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salvar teste'), findsOneWidget);
    expect(find.text('Nome do teste'), findsOneWidget);
    // Foto do teste migrou para TesteExecucaoSheet após o primeiro save.
    expect(find.byKey(const Key('drawing_campo_test_photo_section')), findsNothing);
  });

  testWidgets('revisão de talhão não mostra seção de foto', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
    controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
    controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
    controller.completeDrawing();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingClientsRepositoryProvider.overrideWithValue(_ClientsRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DrawingSheet(
              controller: controller,
              onClose: () {},
              onSaved: (_, {campoTestPhoto}) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Salvar talhão'), findsOneWidget);
    expect(find.byKey(const Key('drawing_campo_test_photo_section')), findsNothing);
  });
}