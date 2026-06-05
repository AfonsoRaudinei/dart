import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/infra/clients/i_clients_repository_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_client_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';

class _ClientsRepository implements IClientsRepository {
  static const client = Client(id: 'cli-1', name: 'José Augusto Miranda');
  static const farm = Farm(
    id: 'farm-1',
    clientId: 'cli-1',
    name: 'Retiro',
    city: 'Palmas',
    state: 'TO',
  );

  @override
  Future<List<Client>> getClients() async => [client];

  @override
  Future<List<Farm>> getFarms(String clientId) async => [farm];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
}

class _DrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];
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

  test('carrega fazendas e mantém nome do cliente contextual', () async {
    final container = ProviderContainer(
      overrides: [
        drawingClientsRepositoryProvider.overrideWithValue(
          _ClientsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(drawingClientProvider.notifier)
        .setClienteAtivo('cli-1', clientName: 'José Augusto Miranda');
    await Future<void>.delayed(Duration.zero);

    final state = container.read(drawingClientProvider);
    expect(state.preSelectedClientId, 'cli-1');
    expect(state.preSelectedClientName, 'José Augusto Miranda');
    expect(state.farms.single.id, 'farm-1');
  });

  testWidgets('revisão contextual não pede cliente novamente', (tester) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        drawingClientsRepositoryProvider.overrideWithValue(
          _ClientsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(drawingClientProvider.notifier)
        .setClienteAtivo('cli-1', clientName: 'José Augusto Miranda');

    final controller = DrawingController(repository: _DrawingRepository());
    addTearDown(controller.dispose);
    controller.selectTool('polygon');
    controller.appendDrawingPoint(const LatLng(-10.57, -48.80));
    controller.appendDrawingPoint(const LatLng(-10.57, -48.79));
    controller.appendDrawingPoint(const LatLng(-10.56, -48.79));
    controller.completeDrawing();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
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

    expect(find.text('José Augusto Miranda'), findsOneWidget);
    expect(find.text('Selecione o cliente...'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });
}
