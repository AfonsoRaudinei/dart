import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_model.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_providers.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/components/map/map_bottom_sheet.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';

/// Widget tests — BUG-006 P0/P1: sheet expandido, conteúdo visível, guard ao cancelar.
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

  testWidgets('criação de ocorrência abre expandida com formulário visível', (
    tester,
  ) async {
    final hostKey = GlobalKey<_OccurrenceSheetHostState>();
    final controller = await _createController();
    addTearDown(controller.dispose);

    await _pumpOccurrenceHost(tester, hostKey, controller);
    await tester.pumpAndSettle();

    expect(find.byType(OccurrenceCreationSheet), findsOneWidget);
    expect(find.text('Nova Ocorrência'), findsOneWidget);
    expect(find.text('Categorias da Ocorrência'), findsOneWidget);
    expect(find.text('Cultivar & Plantio'), findsOneWidget);

    final sheetSize = tester.getSize(
      find.descendant(
        of: find.byKey(const Key('map_bottom_sheet_root')),
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(sheetSize.height, greaterThan(500));
  });

  testWidgets('cancelar com dados dirty exibe confirmação antes de fechar', (
    tester,
  ) async {
    final hostKey = GlobalKey<_OccurrenceSheetHostState>();
    final controller = await _createController();
    addTearDown(controller.dispose);

    await _pumpOccurrenceHost(tester, hostKey, controller);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Descreva a ocorrência…',
      ),
      'Lagarta na soja',
    );
    await tester.pump();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Descartar ocorrência?'), findsOneWidget);
    expect(hostKey.currentState!.closeCount, 0);

    await tester.tap(find.text('Continuar preenchendo'));
    await tester.pumpAndSettle();

    expect(find.text('Lagarta na soja'), findsOneWidget);
    expect(hostKey.currentState!.closeCount, 0);
  });

  testWidgets('confirmar descarte fecha sheet e incrementa closeCount', (
    tester,
  ) async {
    final hostKey = GlobalKey<_OccurrenceSheetHostState>();
    final controller = await _createController();
    addTearDown(controller.dispose);

    await _pumpOccurrenceHost(tester, hostKey, controller);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Descreva a ocorrência…',
      ),
      'Perda de dados não deve ocorrer',
    );
    await tester.pump();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
  });
}

Future<void> _pumpOccurrenceHost(
  WidgetTester tester,
  GlobalKey<_OccurrenceSheetHostState> hostKey,
  DrawingController controller,
) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        drawingFlagProvider.overrideWith((ref) async => const FeatureFlag(
          key: 'drawing_v1',
          enabled: true,
          rolloutPercentage: 100,
          version: 1,
        )),
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
      ],
      child: MaterialApp(
        home: _OccurrenceSheetHost(key: hostKey, controller: controller),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<DrawingController> _createController() async {
  final controller = DrawingController(
    repository: _HostDrawingRepository(_feature()),
  );
  await controller.loadFeatures();
  return controller;
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'occ-host-1',
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
      nome: 'Talhão Occ Host',
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

class _OccurrenceSheetHost extends StatefulWidget {
  const _OccurrenceSheetHost({super.key, required this.controller});

  final DrawingController controller;

  @override
  State<_OccurrenceSheetHost> createState() => _OccurrenceSheetHostState();
}

class _OccurrenceSheetHostState extends State<_OccurrenceSheetHost> {
  var closeCount = 0;
  bool _visible = true;
  final _creationLocation = const LatLng(-10.12345, -48.54321);
  final _state = const MapSheetState(
    type: MapSheetType.occurrences,
    isCreatingOccurrence: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_visible)
            Align(
              alignment: Alignment.bottomCenter,
              child: MapBottomSheet(
                drawingController: widget.controller,
                onLocationRequested: () {},
                onClose: () => setState(() {
                  closeCount++;
                  _visible = false;
                }),
                state: _state,
                onStateChange: (_) {},
                creationLocation: _creationLocation,
              ),
            ),
        ],
      ),
    );
  }
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}

class _EmptyVisitLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async => null;
}

class _HostDrawingRepository extends DrawingRepository {
  _HostDrawingRepository(this.initial);

  final DrawingFeature initial;

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [initial];
}
