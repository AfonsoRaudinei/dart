import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<double> getTotalAreaByClienteId(String clienteId) async => 0;

  @override
  Future<void> updateClientAreaTotal(String clientId, double areaTotal) async {}
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

  testWidgets('armCampoTeste arma teste e fecha sheet de desenho', (tester) async {
    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

  MapSheetState? sheet;

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
                    ref.read(mapSheetStateProvider.notifier).state =
                        const MapSheetState(type: MapSheetType.draw);
                    MapSheetController.armCampoTeste(
                      context,
                      ref,
                      (s, _) => sheet = s,
                    );
                  },
                  child: const Text('Armar teste'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Armar teste'));
    await tester.pumpAndSettle();

    expect(controller.currentState, DrawingState.armed);
    expect(controller.isSketchingTest, isTrue);
    expect(sheet, isNull);
  });
}