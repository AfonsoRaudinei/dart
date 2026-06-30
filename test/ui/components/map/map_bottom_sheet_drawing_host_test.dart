import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_model.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_providers.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/ui/components/map/map_bottom_sheet.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';

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

  testWidgets('selecionar poligono e sair da selecao limpa destaque e fecha', (
    tester,
  ) async {
    final controller = await _createController();
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);

    await _pumpHost(tester, hostKey, controller);

    expect(find.byType(MapBottomSheet), findsOneWidget);
    expect(
      find.byKey(const Key('drawing_selected_exit_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('drawing_selected_exit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
    expect(controller.selectedFeature, isNull);
    expect(controller.currentState, DrawingState.idle);
  });

  testWidgets('selecionar e fechar no X remove destaque ativo', (tester) async {
    final controller = await _createController();
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);

    await _pumpHost(tester, hostKey, controller);

    await tester.tap(find.byKey(const Key('drawing_sheet_close')));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
    expect(controller.selectedFeature, isNull);
    expect(controller.currentState, DrawingState.idle);
  });

  testWidgets('selecionar e fechar por gesto remove destaque ativo', (
    tester,
  ) async {
    final controller = await _createController();
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);

    await _pumpHost(tester, hostKey, controller);

    final rootRect = tester.getRect(
      find.byKey(const Key('map_bottom_sheet_root')),
    );
    final dragStart = Offset(rootRect.center.dx, rootRect.top + 24);

    await tester.flingFrom(dragStart, const Offset(0, 700), 1800);
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
    expect(controller.selectedFeature, isNull);
    expect(controller.currentState, DrawingState.idle);
  });

  testWidgets('editar, salvar e sair persiste geometria e volta para idle', (
    tester,
  ) async {
    final repository = _HostDrawingRepository(_feature());
    final controller = await _createController(repository: repository);
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);

    await _pumpHost(tester, hostKey, controller);

    await tester.tap(find.byKey(const Key('drawing_selected_edit_button')));
    await tester.pumpAndSettle();

    controller.moveVertex(0, 0, const LatLng(-9.995, -47.995));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('drawing_edit_save_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawing_edit_save_button')));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
    expect(controller.currentState, DrawingState.idle);
    expect(controller.selectedFeature, isNull);
    expect(repository.saved, isNotEmpty);

    final saved = repository.saved.last.geometry as DrawingPolygon;
    expect(saved.coordinates.first.first, equals(const [-47.995, -9.995]));
  });

  testWidgets('editar e cancelar preserva geometria original', (tester) async {
    final repository = _HostDrawingRepository(_feature());
    final controller = await _createController(repository: repository);
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);
    final original = (controller.selectedFeature!.geometry as DrawingPolygon)
        .coordinates
        .first
        .first;

    await _pumpHost(tester, hostKey, controller);

    await tester.tap(find.byKey(const Key('drawing_selected_edit_button')));
    await tester.pumpAndSettle();

    controller.moveVertex(0, 0, const LatLng(-9.995, -47.995));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('drawing_edit_cancel_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('drawing_edit_cancel_button')));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsOneWidget);
    expect(hostKey.currentState!.closeCount, 0);
    expect(controller.currentState, DrawingState.selected);
    expect(controller.selectedFeature, isNotNull);
    expect(repository.saved, isEmpty);

    final current = (controller.selectedFeature!.geometry as DrawingPolygon)
        .coordinates
        .first
        .first;
    expect(current, equals(original));
  });

  testWidgets('editar e fechar no X pede confirmacao antes de descartar', (
    tester,
  ) async {
    final controller = await _createController();
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    controller.selectFeature(controller.features.single);

    await _pumpHost(tester, hostKey, controller);

    await tester.tap(find.byKey(const Key('drawing_selected_edit_button')));
    await tester.pumpAndSettle();

    controller.moveVertex(0, 0, const LatLng(-9.995, -47.995));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('drawing_sheet_close')));
    await tester.pumpAndSettle();

    expect(find.text('Descartar alterações?'), findsOneWidget);
    expect(find.byType(MapBottomSheet), findsOneWidget);
    expect(hostKey.currentState!.closeCount, 0);
    expect(controller.currentState, DrawingState.editing);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(find.byType(MapBottomSheet), findsNothing);
    expect(hostKey.currentState!.closeCount, 1);
    expect(controller.selectedFeature, isNull);
    expect(controller.currentState, DrawingState.idle);
  });

  testWidgets('abrir e fechar repetidamente nao deixa selecao residual', (
    tester,
  ) async {
    final controller = await _createController();
    final hostKey = GlobalKey<_MapBottomSheetHostState>();
    addTearDown(controller.dispose);

    await _pumpHost(tester, hostKey, controller);

    for (var i = 0; i < 3; i++) {
      controller.selectFeature(controller.features.single);
      hostKey.currentState!.show();
      await tester.pumpAndSettle();

      expect(find.byType(MapBottomSheet), findsOneWidget);
      expect(controller.selectedFeature, isNotNull);

      await tester.tap(find.byKey(const Key('drawing_sheet_close')));
      await tester.pumpAndSettle();

      expect(find.byType(MapBottomSheet), findsNothing);
      expect(controller.selectedFeature, isNull);
      expect(controller.currentState, DrawingState.idle);
    }

    expect(hostKey.currentState!.closeCount, 3);
  });
}

Future<void> _pumpHost(
  WidgetTester tester,
  GlobalKey<_MapBottomSheetHostState> hostKey,
  DrawingController controller,
) async {
  tester.view.physicalSize = const Size(1179, 2556);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        drawingFlagProvider.overrideWith(
          (ref) async => FeatureFlag.fullyEnabled('drawing_v1'),
        ),
      ],
      child: MaterialApp(
        home: _MapBottomSheetHost(key: hostKey, controller: controller),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<DrawingController> _createController({
  _HostDrawingRepository? repository,
}) async {
  final controller = DrawingController(
    repository: repository ?? _HostDrawingRepository(_feature()),
  );
  await controller.loadFeatures();
  return controller;
}

class _MapBottomSheetHost extends StatefulWidget {
  const _MapBottomSheetHost({super.key, required this.controller});

  final DrawingController controller;

  @override
  State<_MapBottomSheetHost> createState() => _MapBottomSheetHostState();
}

class _MapBottomSheetHostState extends State<_MapBottomSheetHost> {
  bool _isVisible = true;
  var closeCount = 0;
  MapSheetState _state = const MapSheetState(type: MapSheetType.draw);

  void show() {
    setState(() => _isVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.black12)),
          if (_isVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: MapBottomSheet(
                drawingController: widget.controller,
                onLocationRequested: () {},
                onClose: () {
                  setState(() {
                    closeCount++;
                    _isVisible = false;
                  });
                },
                state: _state,
                onStateChange: (newState) {
                  setState(() => _state = newState);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _HostDrawingRepository extends DrawingRepository {
  _HostDrawingRepository(this.initial);

  final DrawingFeature initial;
  final List<DrawingFeature> saved = [];

  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [initial];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {
    saved.add(feature);
  }
}

DrawingFeature _feature() {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'field-host-1',
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
      nome: 'Talhão Host',
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
