import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_presenter_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_date_nav_provider.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/ui/components/map/map_talhao_selection_toolbar.dart';

class _DrawingRepo extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];
}

class _Lookup implements INdviLatestLookup {
  String? failKey;

  @override
  Future<NdviLatestSummary?> getLatest(
    String fieldId, {
    String? imageDate,
  }) async {
    if (imageDate != null && imageDate == failKey) {
      throw StateError('ndvi-offline');
    }
    return NdviLatestSummary(
      imageDate: DateTime.parse(imageDate ?? '2026-10-28'),
      ndviMean: 0.4,
      ndviMin: 0,
      ndviMax: 0.8,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      imageUrl: 'https://example.com/ndvi.png',
    );
  }
}

class _Presenter implements INdviFieldPresenter {
  _Presenter(this.onShow);

  final Future<void> Function()? onShow;
  int calls = 0;

  @override
  Future<void> showTalhaoSheet(
    BuildContext context, {
    required String fieldId,
    required String fieldName,
    double? areaHa,
  }) async {
    calls++;
    await onShow?.call();
  }
}

NdviImage _image(DateTime date) {
  return NdviImage(
    id: 'f1-${ndviImageDateKey(date)}',
    fieldId: 'f1',
    imageDate: date,
    ndviMin: 0,
    ndviMax: 0,
    ndviMean: 0,
    source: 'sentinel',
    fetchedAt: DateTime(2026, 10, 1),
    syncStatus: 0,
    localPath: '/tmp/ndvi.png',
  );
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'f1',
    geometry: DrawingPolygon(
      coordinates: const [
        [
          [0.0, 0.0],
          [2.0, 0.0],
          [2.0, 2.0],
          [0.0, 2.0],
          [0.0, 0.0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'Th 2',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 205.2,
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

  final images = [
    _image(DateTime(2026, 10, 28)),
    _image(DateTime(2026, 10, 16)),
    _image(DateTime(2026, 10, 10)),
    _image(DateTime(2026, 10, 1)),
    _image(DateTime(2026, 9, 20)),
  ];

  Future<ProviderContainer> pumpToolbar(
    WidgetTester tester, {
    required List<NdviImage> dates,
    required _Presenter presenter,
    required DrawingController controller,
    required MapController mapController,
    INdviLatestLookup? lookup,
  }) async {
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => controller),
          ndviImagesProvider.overrideWith((ref, fieldId) async => dates),
          ndviLatestLookupProvider.overrideWithValue(lookup ?? _Lookup()),
          ndviFieldPresenterProvider.overrideWithValue(presenter),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                container = ProviderScope.containerOf(context);
                return FlutterMap(
                  mapController: mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(0.8, 0.8),
                    initialZoom: 16,
                  ),
                  children: [
                    MapTalhaoSelectionToolbar(
                      mapController: mapController,
                      setSheetState: (_, __) {},
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('NDVI ativo mostra 4 datas recentes e troca o chip', (
    tester,
  ) async {
    final controller = DrawingController(repository: _DrawingRepo());
    addTearDown(controller.dispose);
    controller.selectFeature(_feature());
    final mapController = MapController();
    addTearDown(mapController.dispose);
    final presenter = _Presenter(null);

    final container = await pumpToolbar(
      tester,
      dates: images,
      presenter: presenter,
      controller: controller,
      mapController: mapController,
    );

    await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
    await tester.pump();
    await tester.pump();

    expect(find.text('28/10'), findsOneWidget);
    expect(find.text('16/10'), findsOneWidget);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('01/10'), findsOneWidget);
    expect(find.text('20/09'), findsNothing);
    expect(find.text('ver mais'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')),
    );
    await tester.tap(find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')));
    await tester.pump();

    expect(
      container.read(mapNdviSelectedDateProvider),
      const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-16'),
    );
  });

  testWidgets('talhão sem imagem não mostra chips de data', (tester) async {
    final controller = DrawingController(repository: _DrawingRepo());
    addTearDown(controller.dispose);
    controller.selectFeature(_feature());
    final mapController = MapController();
    addTearDown(mapController.dispose);

    await pumpToolbar(
      tester,
      dates: const [],
      presenter: _Presenter(null),
      controller: controller,
      mapController: mapController,
    );

    await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('map_talhao_toolbar_ndvi')), findsOneWidget);
    expect(find.text('ver mais'), findsNothing);
    expect(
      find.byKey(const Key('map_talhao_ndvi_date_2026-10-28')),
      findsNothing,
    );
  });

  testWidgets('falha da data mostra o erro do sheet e mantém a toolbar', (
    tester,
  ) async {
    final controller = DrawingController(repository: _DrawingRepo());
    addTearDown(controller.dispose);
    controller.selectFeature(_feature());
    final mapController = MapController();
    addTearDown(mapController.dispose);
    final lookup = _Lookup();

    await pumpToolbar(
      tester,
      dates: images,
      presenter: _Presenter(null),
      controller: controller,
      mapController: mapController,
      lookup: lookup,
    );

    await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
    await tester.pump();
    await tester.pump();

    lookup.failKey = '2026-10-16';
    await tester.ensureVisible(
      find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')),
    );
    await tester.tap(find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Erro ao carregar imagens NDVI'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.byKey(const Key('map_talhao_toolbar_ndvi')), findsOneWidget);
  });

  testWidgets('ver mais sem troca no sheet mantém a data do mapa', (
    tester,
  ) async {
    final controller = DrawingController(repository: _DrawingRepo());
    addTearDown(controller.dispose);
    controller.selectFeature(_feature());
    final mapController = MapController();
    addTearDown(mapController.dispose);
    final presenter = _Presenter(null);

    final container = await pumpToolbar(
      tester,
      dates: images,
      presenter: presenter,
      controller: controller,
      mapController: mapController,
    );

    await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')),
    );
    await tester.tap(find.byKey(const Key('map_talhao_ndvi_date_2026-10-16')));
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('map_talhao_ndvi_date_more')),
    );
    await tester.tap(find.byKey(const Key('map_talhao_ndvi_date_more')));
    await tester.pump();
    await tester.pump();

    expect(presenter.calls, 1);
    expect(container.read(mapNdviSelectedDateProvider)?.dateKey, '2026-10-16');
  });

  testWidgets('ver mais aplica a data trocada no sheet', (tester) async {
    final controller = DrawingController(repository: _DrawingRepo());
    addTearDown(controller.dispose);
    controller.selectFeature(_feature());
    final mapController = MapController();
    addTearDown(mapController.dispose);
    late ProviderContainer container;
    final presenter = _Presenter(() async {
      container.read(ndviDateIndexProvider('f1').notifier).state = 2;
    });

    container = await pumpToolbar(
      tester,
      dates: images,
      presenter: presenter,
      controller: controller,
      mapController: mapController,
    );

    await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
    await tester.pump();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('map_talhao_ndvi_date_more')),
    );
    await tester.tap(find.byKey(const Key('map_talhao_ndvi_date_more')));
    await tester.pump();
    await tester.pump();

    expect(
      container.read(mapNdviSelectedDateProvider),
      const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-10'),
    );
  });
}
