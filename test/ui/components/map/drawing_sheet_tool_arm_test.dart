import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/controllers/drawing_controller.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_sheet.dart';

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

  testWidgets('tap Polígono fecha modal e mantém ferramenta armed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showSoloForteSheet<void>(
                        context: context,
                        showDragHandle: true,
                        useSafeArea: true,
                        maxHeightFraction: 0.78,
                        builder: (_) => DrawingSheet(
                          controller: controller,
                          onClose: () => Navigator.of(context).pop(),
                          onSaved: (_) => Navigator.of(context).pop(),
                        ),
                      );
                    },
                    child: const Text('Abrir Desenho'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Desenho'));
    await tester.pumpAndSettle();

    expect(find.text('Polígono'), findsOneWidget);
    expect(controller.currentState, DrawingState.idle);

    await tester.tap(find.text('Polígono'));
    await tester.pumpAndSettle();

    expect(find.text('Polígono'), findsNothing);
    expect(controller.currentState, DrawingState.armed);
    expect(controller.currentTool, DrawingTool.polygon);
  });

  testWidgets('tap Área Visitada chama callback e fecha sem armar desenho', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = DrawingController(repository: _MockDrawingRepository());
    addTearDown(controller.dispose);
    var areaVisitadaArmed = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showSoloForteSheet<void>(
                        context: context,
                        showDragHandle: true,
                        useSafeArea: true,
                        maxHeightFraction: 0.78,
                        builder: (_) => DrawingSheet(
                          controller: controller,
                          onAreaVisitada: () => areaVisitadaArmed = true,
                          onClose: () => Navigator.of(context).pop(),
                          onSaved: (_) => Navigator.of(context).pop(),
                        ),
                      );
                    },
                    child: const Text('Abrir Desenho'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir Desenho'));
    await tester.pumpAndSettle();

    expect(find.text('Área Visitada'), findsOneWidget);
    expect(controller.currentState, DrawingState.idle);

    await tester.ensureVisible(find.text('Área Visitada'));
    await tester.tap(find.text('Área Visitada'));
    await tester.pumpAndSettle();

    expect(areaVisitadaArmed, isTrue);
    expect(find.text('Área Visitada'), findsNothing);
    expect(controller.currentState, DrawingState.idle);
    expect(controller.currentTool, DrawingTool.none);
  });
}
