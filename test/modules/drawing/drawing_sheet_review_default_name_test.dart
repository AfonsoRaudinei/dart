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
  Future<List<Farm>> getFarms(String clientId) async => const [
        Farm(
          id: 'f1',
          clientId: 'c1',
          name: 'Fazenda 1',
          city: '',
          state: '',
        ),
      ];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
}

Future<void> _armTestePolygonAndReview(DrawingController controller) async {
  controller.selectTool('teste');
  controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
  controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
  controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
  controller.completeDrawing();
  expect(controller.currentState, DrawingState.reviewing);
}

Widget _sheetHarness(DrawingController controller) {
  return ProviderScope(
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
            onSaved: (_) {},
          ),
        ),
      ),
    ),
  );
}

TextFormField _firstNomeField(WidgetTester tester) {
  return tester.widget<TextFormField>(
    find.byType(TextFormField).first,
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

  group('nome default na revisão', () {
    late DrawingController controller;

    setUp(() {
      controller = DrawingController(repository: _MockDrawingRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('sketch teste abre revisão com nome default Teste', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _armTestePolygonAndReview(controller);

      await tester.pumpWidget(_sheetHarness(controller));
      await tester.pumpAndSettle();

      expect(_firstNomeField(tester).controller?.text, 'Teste');
      expect(find.text('Nome do Talhão'), findsOneWidget);
    });

    testWidgets(
      'sheet montado antes da revisão atualiza placeholder ao entrar em reviewing',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_sheetHarness(controller));
        await tester.pumpAndSettle();

        await _armTestePolygonAndReview(controller);
        await tester.pumpAndSettle();

        expect(_firstNomeField(tester).controller?.text, 'Teste');
      },
    );

    testWidgets('polígono normal mantém Talhão Novo na revisão', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.selectTool('polygon');
      controller.appendDrawingPoint(const LatLng(-15.0, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.0));
      controller.appendDrawingPoint(const LatLng(-15.001, -47.001));
      controller.completeDrawing();

      await tester.pumpWidget(_sheetHarness(controller));
      await tester.pumpAndSettle();

      expect(_firstNomeField(tester).controller?.text, 'Talhão Novo');
    });
  });
}