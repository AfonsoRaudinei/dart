import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/components/map/widgets/isolated_marker_layers.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_first_query_handler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapFirstQueryHandler — modo=foco', () {
    testWidgets('com caseId define focusedMarketingCaseIdProvider', (
      tester,
    ) async {
      LatLng? focusedPoint;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _MapFirstQueryHarness(
              uri: Uri.parse(
                '/map?modo=foco&lat=-10.100000&lng=-48.200000&caseId=mkt-focus-1',
              ),
              onFocusCoordinate: (point) => focusedPoint = point,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_MapFirstQueryHarness)),
      );

      expect(
        container.read(focusedMarketingCaseIdProvider),
        'mkt-focus-1',
      );
      expect(focusedPoint, const LatLng(-10.1, -48.2));
    });

    testWidgets('sem caseId limpa focusedMarketingCaseIdProvider', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _MapFirstQueryHarness(
              uri: Uri.parse('/map?modo=foco&lat=-10.100000&lng=-48.200000'),
              onFocusCoordinate: (_) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_MapFirstQueryHarness)),
      );

      expect(container.read(focusedMarketingCaseIdProvider), isNull);
    });
  });

  group('Foco de publicação de marketing no mapa', () {
    testWidgets(
      'com caseId em foco não exibe pin genérico Icons.place',
      (tester) async {
        const point = LatLng(-10.1, -48.2);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              focusedMarketingCaseIdProvider.overrideWith((ref) => 'mkt-focus-1'),
            ],
            child: const MaterialApp(
              home: _DestinationMarkerLayer(),
            ),
          ),
        );

        _applyFocusCoordinateMarkerPolicy(
          ProviderScope.containerOf(
            tester.element(find.byType(_DestinationMarkerLayer)),
          ),
          point,
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.place), findsNothing);
        expect(
          ProviderScope.containerOf(
            tester.element(find.byType(_DestinationMarkerLayer)),
          ).read(destinationCoordinateMarkerProvider),
          isNull,
        );
      },
    );

    testWidgets(
      'sem caseId em foco exibe pin genérico Icons.place na coordenada',
      (tester) async {
        const point = LatLng(-10.1, -48.2);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: _DestinationMarkerLayer(),
            ),
          ),
        );

        _applyFocusCoordinateMarkerPolicy(
          ProviderScope.containerOf(
            tester.element(find.byType(_DestinationMarkerLayer)),
          ),
          point,
        );

        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.place), findsOneWidget);
      },
    );

    testWidgets(
      'IsolatedMarketingMarkersLayer mantém pin rico em zoom baixo quando case está em foco',
      (tester) async {
        final marketingCase = _marketingCase(id: 'mkt-focus-1');
        final preferencesService = await _buildPreferencesService(
          showMarkers: true,
        );

        final container = ProviderContainer(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            currentUserRoleProvider.overrideWithValue(UserRole.consultor),
            marketingCasesProvider.overrideWith(
              (ref) => _marketingCasesNotifier([marketingCase]),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(focusedMarketingCaseIdProvider.notifier).state =
            'mkt-focus-1';

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-10.1, -48.2),
                  // Abaixo do minZoom ouro (10): sem foco o pin sumiria.
                  initialZoom: 8,
                ),
                children: const [
                  IsolatedMarketingMarkersLayer(),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(MarkerLayer), findsOneWidget);
        expect(find.byType(GestureDetector), findsWidgets);
        expect(find.text('Produto X'), findsOneWidget);
        expect(find.byIcon(Icons.place), findsNothing);
      },
    );

    testWidgets(
      'IsolatedMarketingMarkersLayer oculta pin ouro em zoom baixo sem foco',
      (tester) async {
        final marketingCase = _marketingCase(id: 'mkt-focus-1');
        final preferencesService = await _buildPreferencesService(
          showMarkers: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesServiceProvider.overrideWithValue(preferencesService),
              currentUserRoleProvider.overrideWithValue(UserRole.consultor),
              marketingCasesProvider.overrideWith(
                (ref) => _marketingCasesNotifier([marketingCase]),
              ),
            ],
            child: MaterialApp(
              home: FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(-10.1, -48.2),
                  initialZoom: 8,
                ),
                children: const [
                  IsolatedMarketingMarkersLayer(),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(MarkerLayer), findsNothing);
        expect(find.text('Produto X'), findsNothing);
      },
    );
  });
}

/// Espelha a política de `PrivateMapScreen._focusCoordinateFromQuery`.
void _applyFocusCoordinateMarkerPolicy(ProviderContainer container, LatLng point) {
  final focusedCaseId = container.read(focusedMarketingCaseIdProvider);
  if (focusedCaseId == null || focusedCaseId.isEmpty) {
    container.read(destinationCoordinateMarkerProvider.notifier).state = point;
  } else {
    container.read(destinationCoordinateMarkerProvider.notifier).state = null;
  }
}

MarketingCasesNotifier _marketingCasesNotifier(List<MarketingCase> cases) {
  final repo = _FakeMarketingCaseRepository(cases);
  final notifier = MarketingCasesNotifier(repo, MarketingSyncService(repo));
  notifier.state = AsyncData(cases);
  return notifier;
}

class _MapFirstQueryHarness extends ConsumerStatefulWidget {
  final Uri uri;
  final void Function(LatLng point) onFocusCoordinate;

  const _MapFirstQueryHarness({
    required this.uri,
    required this.onFocusCoordinate,
  });

  @override
  ConsumerState<_MapFirstQueryHarness> createState() =>
      _MapFirstQueryHarnessState();
}

class _MapFirstQueryHarnessState extends ConsumerState<_MapFirstQueryHarness> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MapFirstQueryHandler.handle(
        uri: widget.uri,
        ref: ref,
        setSheetState: (_, __) {},
        armOccurrenceMode: () {},
        focusDrawing: (_, {required bool edit}) async {},
        focusCoordinate: widget.onFocusCoordinate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mantém focusedMarketingCaseIdProvider vivo (autoDispose) durante o teste.
    ref.watch(focusedMarketingCaseIdProvider);
    return const SizedBox.shrink();
  }
}

/// Espelha o MarkerLayer efêmero de destino em `map_build_orchestrator.dart`.
class _DestinationMarkerLayer extends ConsumerWidget {
  const _DestinationMarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(destinationCoordinateMarkerProvider);
    if (destination == null) {
      return const SizedBox.shrink();
    }
    return Icon(Icons.place, size: 40, color: Colors.redAccent);
  }
}

class _FakeMarketingCaseRepository implements IMarketingCaseRepository {
  final List<MarketingCase> cases;

  _FakeMarketingCaseRepository(this.cases);

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => cases;

  @override
  Future<List<MarketingCase>> getLocalCases() async => cases;

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async =>
      cases.firstWhere((item) => item.id == id);

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async =>
      cases.firstWhere((item) => item.id == id);
}

Future<PreferencesService> _buildPreferencesService({
  required bool showMarkers,
}) async {
  SharedPreferences.setMockInitialValues({'map_show_markers_v1': showMarkers});
  return PreferencesService(await SharedPreferences.getInstance());
}

MarketingCase _marketingCase({required String id}) {
  return MarketingCase.fromJson({
    'id': id,
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Produtor Teste - Fazenda Marketing',
    'produto_utilizado': 'Produto X',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'descricao': 'Case de resultado para teste.',
    'quantidade_produzida': 1800,
    'status': 'published',
    'ativo': true,
    'criado_em': '2026-06-04T12:00:00.000Z',
    'atualizado_em': '2026-06-04T12:00:00.000Z',
    'sync_status': 'synced',
  });
}
