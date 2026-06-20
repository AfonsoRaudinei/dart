import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/infra/clients/i_clients_repository_provider.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';

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

  testWidgets(
    'fecha explicitamente e salva vínculo no painel sem sheet aninhado',
    (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _DrawingRepository(_feature());
      final controller = DrawingController(repository: repository);
      addTearDown(controller.dispose);
      await controller.loadFeatures();
      controller.selectFeature(controller.features.single);
      var closeCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            drawingClientsRepositoryProvider.overrideWithValue(
              _ClientsRepository(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 1000,
                child: DrawingSheet(
                  controller: controller,
                  onClose: () => closeCount++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('drawing_sheet_close')));
      expect(closeCount, 1);

      await tester.tap(find.text('Vincular / editar dados'));
      await tester.pumpAndSettle();
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Fazenda'), findsOneWidget);
      expect(find.text('Salvar'), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      final clientField = find.byType(DropdownButtonFormField<Client>).first;
      await tester.ensureVisible(clientField);
      await tester.tap(clientField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cliente Real').last);
      await tester.pumpAndSettle();

      final farmField = find.byType(DropdownButtonFormField<Farm>).first;
      await tester.ensureVisible(farmField);
      await tester.tap(farmField);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fazenda Real').last);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(controller.selectedFeature!.properties.clienteId, 'client-1');
      expect(controller.selectedFeature!.properties.fazendaId, 'farm-1');
      expect(find.text('Dados do talhão salvos'), findsOneWidget);
      expect(repository.saved.last.properties.clienteId, 'client-1');
      expect(repository.saved.last.properties.fazendaId, 'farm-1');
    },
  );
}

class _DrawingRepository extends DrawingRepository {
  final DrawingFeature initial;
  final List<DrawingFeature> saved = [];

  _DrawingRepository(this.initial);

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [initial];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    saved.add(feature);
  }
}

class _ClientsRepository implements IClientsRepository {
  @override
  Future<List<Client>> getClients() async => const [
    Client(id: 'client-1', name: 'Cliente Real'),
  ];

  @override
  Future<List<Farm>> getFarms(String clientId) async => const [
    Farm(
      id: 'farm-1',
      clientId: 'client-1',
      name: 'Fazenda Real',
      city: 'Araguaína',
      state: 'TO',
    ),
  ];

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {}
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-1',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [-48, -10],
          [-47.99, -10],
          [-47.99, -9.99],
          [-48, -10],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Talhão Norte',
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
