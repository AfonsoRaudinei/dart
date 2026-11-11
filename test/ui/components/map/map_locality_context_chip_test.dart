import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_locality_context_chip.dart';

class _MockDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}

  @override
  Future<void> deleteFeature(String id) async {}
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

  testWidgets('chip visível quando divisas UF ativas', (tester) async {
    final drawingController =
        DrawingController(repository: _MockDrawingRepository());
    addTearDown(drawingController.dispose);
    SharedPreferences.setMockInitialValues({'map_state_boundaries_v1': true});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    const center = LatLng(-10.2, -48.3);
    final bounds = LatLngBounds(
      LatLng(center.latitude - 0.01, center.longitude - 0.01),
      LatLng(center.latitude + 0.01, center.longitude + 0.01),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => drawingController),
          preferencesServiceProvider.overrideWithValue(preferencesService),
          mapCameraSnapshotProvider.overrideWith(
            (ref) => MapCameraSnapshot(
              center: center,
              zoom: 12,
              visibleBounds: bounds,
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapLocalityContextChip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('map_locality_context_chip')), findsOneWidget);

    final chipFinder = find.byType(MapLocalityContextChip);
    final safeTop = MediaQuery.paddingOf(tester.element(chipFinder)).top;
    final positioned = tester.widget<Positioned>(find.byType(Positioned));
    expect(positioned.top, safeTop + kMapLocalityChipTopBelowSafeArea);
    expect(positioned.right, kMapTopControlsRightInset);
    expect(positioned.left, isNull);
    expect(kMapTopControlsReservedRightWidth, 188.0);

    final chipBox = tester.renderObject<RenderBox>(
      find.byKey(const Key('map_locality_context_chip')),
    );
    final chipRect = chipBox.localToGlobal(Offset.zero) & chipBox.size;
    final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final toggleRect = Rect.fromLTWH(
      screenWidth - kMapTopControlsReservedRightWidth,
      safeTop + kMapTopControlsTopInset,
      kMapTopControlsReservedRightWidth,
      kMapTopControlsRowHeight,
    );
    expect(chipRect.overlaps(toggleRect), isFalse);
    expect(
      chipRect.right,
      closeTo(screenWidth - kMapTopControlsRightInset, 0.5),
    );
  });

  testWidgets('chip oculto quando divisas UF desativadas', (tester) async {
    SharedPreferences.setMockInitialValues({'map_state_boundaries_v1': false});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );
    final drawingController =
        DrawingController(repository: _MockDrawingRepository());
    addTearDown(drawingController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => drawingController),
          preferencesServiceProvider.overrideWithValue(preferencesService),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                MapLocalityContextChip(),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('map_locality_context_chip')), findsNothing);
  });
}
