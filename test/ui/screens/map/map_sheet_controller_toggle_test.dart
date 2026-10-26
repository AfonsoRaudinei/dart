import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/ui/components/map/map_sheet_state.dart';
import 'package:soloforte_app/ui/screens/map/controllers/map_sheet_controller.dart';

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

  testWidgets('toggleDrawMode com drawing ativo cancela em vez de reabrir sheet', (
    tester,
  ) async {
    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

    controller.selectTool('freehand');
    controller.beginFreehandStroke(const LatLng(-15.78, -47.92));
    expect(controller.currentState, DrawingState.drawing);

    MapSheetState? sheetState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    MapSheetController.toggleDrawMode(
                      context,
                      ref,
                      (s, _) => sheetState = s,
                    );
                  },
                  child: const Text('toggle'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('toggle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.currentState, DrawingState.idle);
    expect(sheetState, isNull);
    expect(find.text('Desenho cancelado'), findsOneWidget);
  });

  testWidgets('toggleDrawMode com armed abre sheet sem cancelar', (tester) async {
    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

    controller.selectTool('freehand');
    expect(controller.currentState, DrawingState.armed);

    MapSheetState? sheetState;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          drawingControllerProvider.overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    MapSheetController.toggleDrawMode(
                      context,
                      ref,
                      (s, _) => sheetState = s,
                    );
                  },
                  child: const Text('toggle'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('toggle'));
    await tester.pump();

    expect(controller.currentState, DrawingState.armed);
    expect(sheetState?.type, MapSheetType.draw);
    expect(find.text('Desenho cancelado'), findsNothing);
  });
}
