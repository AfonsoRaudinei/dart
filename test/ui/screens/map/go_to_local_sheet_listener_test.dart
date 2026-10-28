import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/ui/screens/map/widgets/go_to_local_sheet_listener.dart';

class _MockDrawingRepository extends DrawingRepository {
  @override
  Future<List<DrawingFeature>> getAllFeatures() async => [];

  @override
  Future<void> saveFeature(DrawingFeature feature) async {}

  @override
  Future<void> deleteFeature(String id) async {}
}

class _IdleDrawingController extends DrawingController {
  _IdleDrawingController() : super(repository: _MockDrawingRepository());
}

class _EditingDrawingController extends DrawingController {
  _EditingDrawingController() : super(repository: _MockDrawingRepository());

  @override
  DrawingState get currentState => DrawingState.editing;
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

  group('GoToLocalSheetListener', () {
    testWidgets('consome pedido sticky no mount e abre sheet', (tester) async {
      final controller = _IdleDrawingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingGoToLocalSheetProvider.overrideWith((ref) => true),
            drawingControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: GoToLocalSheetListener(
              onMunicipalitySearch: () async {},
              onCoordinateSearch: () async {},
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ir para local'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GoToLocalSheetListener)),
      );
      expect(container.read(pendingGoToLocalSheetProvider), isFalse);
    });

    testWidgets('em editing bloqueia sheet, limpa pending e mostra snackbar', (
      tester,
    ) async {
      final controller = _EditingDrawingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pendingGoToLocalSheetProvider.overrideWith((ref) => true),
            drawingControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            home: GoToLocalSheetListener(
              onMunicipalitySearch: () async {},
              onCoordinateSearch: () async {},
              child: const Scaffold(body: SizedBox()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ir para local'), findsNothing);
      expect(
        find.text('Finalize a edição do talhão para ir para outro local'),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(GoToLocalSheetListener)),
      );
      expect(container.read(pendingGoToLocalSheetProvider), isFalse);
    });
  });
}
