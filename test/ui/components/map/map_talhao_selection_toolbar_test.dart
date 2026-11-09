import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/drawing_compact_selection_actions.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/ui/components/map/map_talhao_selection_toolbar.dart';

DrawingFeature _squareFeature({String id = 'f1'}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: id,
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
      nome: 'T1',
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

class _DrawingRepo extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];
}

class _NdviLookup implements INdviLatestLookup {
  @override
  Future<NdviLatestSummary?> getLatest(
    String fieldId, {
    String? imageDate,
  }) async => null;
}

class _Writer implements IDrawingFieldWriter {
  final calls = <({String fieldId, TalhaoCondicao condicao})>[];

  @override
  Future<void> updateFieldAvaliacao({
    required String fieldId,
    required TalhaoCondicao condicao,
  }) async {
    calls.add((fieldId: fieldId, condicao: condicao));
  }

  @override
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  }) => Future<void>.error(UnimplementedError());

  @override
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  }) => Future<void>.error(UnimplementedError());

  @override
  Future<void> updateFieldName({
    required String fieldId,
    required String name,
  }) => Future<void>.error(UnimplementedError());

  @override
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? material,
    String? safra,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) => Future<void>.error(UnimplementedError());

  @override
  Future<void> unionDrawingFields({
    required String primaryFieldId,
    required String secondaryFieldId,
    required String clientId,
  }) => Future<void>.error(UnimplementedError());
}

NdviImage _ndviImage(DateTime date) {
  return NdviImage(
    id: 'f1-$date',
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

  group('talhaoSelectionToolbarChipCount', () {
    test('5 chips com NDVI e 2 sem', () {
      expect(talhaoSelectionToolbarChipCount(showNdvi: true), 5);
      expect(talhaoSelectionToolbarChipCount(showNdvi: false), 2);
    });
  });

  group('drawingFeatureAnchorLatLng', () {
    test('retorna centroide para polígono simples', () {
      final feature = _squareFeature();

      final anchor = drawingFeatureAnchorLatLng(feature);
      expect(anchor, isNotNull);
      expect(anchor!.latitude, closeTo(0.8, 0.01));
      expect(anchor.longitude, closeTo(0.8, 0.01));
    });

    test('retorna null sem vértices', () {
      final now = DateTime(2026);
      final feature = DrawingFeature(
        id: 'empty',
        geometry: DrawingPolygon(coordinates: const []),
        properties: DrawingProperties(
          nome: 'Vazio',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-1',
          autorTipo: AuthorType.consultor,
          areaHa: 0,
          versao: 1,
          ativo: true,
          createdAt: now,
          updatedAt: now,
          syncStatus: SyncStatus.synced,
        ),
      );
      expect(drawingFeatureAnchorLatLng(feature), isNull);
    });
  });

  group('clampMapToolbarOffset', () {
    test('feliz: centraliza acima do ponto', () {
      const viewport = Size(400, 800);
      const toolbarWidth = 200.0;
      const toolbarHeight = 52.0;

      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 400),
        viewportSize: viewport,
        toolbarWidth: toolbarWidth,
        toolbarHeight: toolbarHeight,
      );

      expect(offset.dx, 100);
      expect(offset.dy, 400 - toolbarHeight - 12);
    });

    test('borda direita: clamp horizontal', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(390, 200),
        viewportSize: const Size(400, 800),
        toolbarWidth: 200,
        toolbarHeight: 52,
      );

      expect(
        offset.dx,
        400 - 200 - 8 - kMapActionColumnRightInset - kMapActionColumnButtonSize,
      );
    });

    test('borda inferior: reserva FAB + bottomInset', () {
      const viewport = Size(400, 800);
      const toolbarHeight = 52.0;
      const bottomInset = 34.0;

      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 790),
        viewportSize: viewport,
        toolbarWidth: 200,
        toolbarHeight: toolbarHeight,
        bottomInset: bottomInset,
      );

      final maxTop = 800 - bottomInset - kFabSafeArea - toolbarHeight - 8;
      expect(offset.dy, maxTop);
    });

    test('borda superior: clamp vertical com topInset', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(200, 10),
        viewportSize: const Size(400, 800),
        toolbarWidth: 200,
        toolbarHeight: 52,
        topInset: 44,
      );

      expect(offset.dy, greaterThanOrEqualTo(44 + 8));
    });

    test('viewport minúsculo: não lança e mantém margem', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(5, 5),
        viewportSize: const Size(120, 100),
        toolbarWidth: 200,
        toolbarHeight: 52,
      );

      expect(offset.dx, greaterThanOrEqualTo(8));
      expect(offset.dy, greaterThanOrEqualTo(8));
    });

    test('caso geométrico 275px não invade coluna direita', () {
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(350, 200),
        viewportSize: const Size(360, 800),
        toolbarWidth: 275,
        toolbarHeight: 52,
      );

      expect(
        offset.dx + 275,
        lessThanOrEqualTo(
          360 - kMapActionColumnRightInset - kMapActionColumnButtonSize,
        ),
      );
    });

    test('5 chips (344px) em viewport largo não invadem a coluna direita', () {
      const viewportWidth = 480.0;
      const toolbarWidth = 344.0;
      final offset = clampMapToolbarOffset(
        screenPoint: const Offset(470, 200),
        viewportSize: const Size(viewportWidth, 800),
        toolbarWidth: toolbarWidth,
        toolbarHeight: 52,
      );

      expect(
        offset.dx + toolbarWidth,
        lessThanOrEqualTo(
          viewportWidth -
              kMapActionColumnRightInset -
              kMapActionColumnButtonSize,
        ),
      );
    });
  });

  group('estimateMapTalhaoToolbarWidth', () {
    test('retorna largura para 5 chips quando feature tem id', () {
      final feature = _squareFeature();
      expect(estimateMapTalhaoToolbarWidth(feature), 344.0);
    });

    test('retorna largura para 2 chips quando feature tem id vazio', () {
      final feature = _squareFeature(id: '');
      expect(estimateMapTalhaoToolbarWidth(feature), 137.0);
    });
  });

  group('DrawingCompactSelectionActions P&B e NDVI', () {
    testWidgets(
      'showMonochromeMap alterna modo P&B e showNdviMap desativa P&B',
      (tester) async {
        final feature = _squareFeature();
        late WidgetRef capturedRef;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(capturedRef.read(mapNdviOverlayFieldIdProvider), isNull);
        expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);

        DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
        expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
        expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isTrue);

        DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
        expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
        expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);

        DrawingCompactSelectionActions.showMonochromeMap(capturedRef, feature);
        expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isTrue);

        DrawingCompactSelectionActions.showNdviMap(capturedRef, feature);
        expect(capturedRef.read(mapNdviOverlayFieldIdProvider), 'f1');
        expect(capturedRef.read(mapNdviMonochromeEnabledProvider), isFalse);
      },
    );
  });

  group('painel Status', () {
    Future<({ProviderContainer container, _Writer writer})> pumpToolbar(
      WidgetTester tester, {
      required DrawingFeature feature,
      required _Writer writer,
    }) async {
      final controller = DrawingController(repository: _DrawingRepo());
      addTearDown(controller.dispose);
      controller.selectFeature(feature);
      final mapController = MapController();
      addTearDown(mapController.dispose);
      late ProviderContainer container;
      await tester.binding.setSurfaceSize(const Size(800, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            drawingControllerProvider.overrideWith((ref) => controller),
            iDrawingFieldWriterProvider.overrideWithValue(writer),
            ndviLatestLookupProvider.overrideWithValue(_NdviLookup()),
            ndviImagesProvider.overrideWith(
              (ref, fieldId) async => [_ndviImage(DateTime(2026, 10, 28))],
            ),
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
      return (container: container, writer: writer);
    }

    testWidgets('chip Status abre o painel e grava a condição', (tester) async {
      final writer = _Writer();
      final pumped = await pumpToolbar(
        tester,
        feature: _squareFeature(),
        writer: writer,
      );

      expect(
        find.byKey(const Key('map_talhao_toolbar_status')),
        findsOneWidget,
      );
      expect(find.text('Bom'), findsNothing);

      await tester.tap(find.byKey(const Key('map_talhao_toolbar_status')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Bom'), findsOneWidget);
      expect(find.text('Atenção'), findsOneWidget);
      expect(find.text('Alerta'), findsOneWidget);
      expect(find.text('Ruim'), findsOneWidget);

      final bomBorder =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byKey(const Key('map_talhao_condicao_bom')),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      final alertaBorder =
          tester
                  .widget<Container>(
                    find.descendant(
                      of: find.byKey(const Key('map_talhao_condicao_alerta')),
                      matching: find.byType(Container),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(bomBorder.border!.top.width, 2);
      expect(alertaBorder.border!.top.width, 0);

      await tester.tap(find.byKey(const Key('map_talhao_condicao_alerta')));
      await tester.pump();
      await tester.pump();

      expect(writer.calls, [(fieldId: 'f1', condicao: TalhaoCondicao.alerta)]);

      pumped.container
              .read(mapTalhaoStatusPanelFieldIdProvider.notifier)
              .state =
          'outro';
      await tester.pump();
      expect(find.text('Bom'), findsNothing);

      pumped.container
              .read(mapTalhaoStatusPanelFieldIdProvider.notifier)
              .state =
          'f1';
      await tester.pump();
      expect(find.text('Bom'), findsOneWidget);
    });

    testWidgets('painel Status esconde as datas e NDVI fecha o painel', (
      tester,
    ) async {
      final pumped = await pumpToolbar(
        tester,
        feature: _squareFeature(),
        writer: _Writer(),
      );

      await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
      await tester.pump();
      await tester.pump();
      expect(find.text('28/10'), findsOneWidget);

      await tester.tap(find.byKey(const Key('map_talhao_toolbar_status')));
      await tester.pump();
      expect(find.text('28/10'), findsNothing);
      expect(find.text('Bom'), findsOneWidget);

      await tester.tap(find.byKey(const Key('map_talhao_toolbar_ndvi')));
      await tester.pump();
      await tester.pump();
      expect(find.text('Bom'), findsNothing);
      expect(find.text('28/10'), findsOneWidget);
      expect(
        pumped.container.read(mapTalhaoStatusPanelFieldIdProvider),
        isNull,
      );
    });

    testWidgets('talhão sem id não mostra Status', (tester) async {
      await pumpToolbar(
        tester,
        feature: _squareFeature(id: ''),
        writer: _Writer(),
      );

      expect(
        find.byKey(const Key('map_talhao_toolbar_edit_geometry')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('map_talhao_toolbar_status')), findsNothing);
    });
  });
}
