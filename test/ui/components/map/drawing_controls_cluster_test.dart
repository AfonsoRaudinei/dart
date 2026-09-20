import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_bottom_toolbar.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

void main() {
  testWidgets('renderiza toolbar horizontal com ações principais do desenho', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrawingBottomToolbar(
            onConfirm: _noop,
            onUndo: _noop,
            onCancel: _noop,
            canUndo: true,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('drawing_bottom_toolbar')), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Desfazer'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('MapControlsOverlay monta toolbar inferior no estado editing', (
    tester,
  ) async {
    await _pumpMapControlsOverlay(
      tester,
      drawingState: DrawingState.editing,
      isDrawMode: true,
      measurementAreaHa: 750.718,
      measurementPerimeterKm: 1.2,
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('drawing_bottom_toolbar')), findsOneWidget);
    expect(find.text('750.718 ha'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
    expect(find.byKey(const Key('editing_controls_backplate')), findsNothing);
  });

  testWidgets('MapControlsOverlay monta toolbar inferior no estado drawing', (
    tester,
  ) async {
    await _pumpMapControlsOverlay(
      tester,
      drawingState: DrawingState.drawing,
      isDrawMode: true,
    );

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('drawing_bottom_toolbar')), findsOneWidget);
    expect(find.byKey(const Key('editing_controls_backplate')), findsNothing);
    expect(find.byKey(const Key('drawing_controls_backplate')), findsNothing);
  });

  testWidgets(
    'modo drawing integra medição no card inferior (não no topo)',
    (tester) async {
      await _pumpMapControlsOverlay(
        tester,
        drawingState: DrawingState.drawing,
        isDrawMode: true,
        measurementAreaHa: 1.033,
        measurementPerimeterKm: 0.829,
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1.033 ha'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.byKey(const Key('measurement_area_card')), findsOneWidget);

      final toolbarBox = tester.getRect(
        find.byKey(const Key('drawing_bottom_toolbar')),
      );
      final measurementBox = tester.getRect(
        find.byKey(const Key('measurement_area_card')),
      );
      expect(measurementBox.top, greaterThan(toolbarBox.top));
      expect(measurementBox.bottom, lessThanOrEqualTo(toolbarBox.bottom + 1));

      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(measurementBox.top, greaterThan(screenHeight * 0.4));
    },
  );

  testWidgets(
    'modo editing integra medição no card inferior (não no topo)',
    (tester) async {
      await _pumpMapControlsOverlay(
        tester,
        drawingState: DrawingState.editing,
        isDrawMode: true,
        measurementAreaHa: 446.292,
        measurementPerimeterKm: 2.1,
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('446.292 ha'), findsOneWidget);
      expect(find.byKey(const Key('measurement_area_card')), findsOneWidget);

      final toolbarBox = tester.getRect(
        find.byKey(const Key('drawing_bottom_toolbar')),
      );
      final measurementBox = tester.getRect(
        find.byKey(const Key('measurement_area_card')),
      );
      expect(measurementBox.top, greaterThan(toolbarBox.top));
      expect(measurementBox.bottom, lessThanOrEqualTo(toolbarBox.bottom + 1));

      final screenHeight = tester.getSize(find.byType(Scaffold)).height;
      expect(measurementBox.top, greaterThan(screenHeight * 0.4));
    },
  );

  testWidgets(
    'modo editing dispara callbacks de edição na toolbar inferior',
    (tester) async {
      var saveCalls = 0;
      var cancelCalls = 0;
      var undoCalls = 0;
      var finishCalls = 0;
      var cancelDrawingCalls = 0;

      await _pumpMapControlsOverlay(
        tester,
        drawingState: DrawingState.editing,
        isDrawMode: true,
        measurementAreaHa: 10,
        onFinishDrawing: () => finishCalls++,
        onCancelDrawing: () => cancelDrawingCalls++,
        onSaveEdit: () => saveCalls++,
        onCancelEdit: () => cancelCalls++,
        onUndoEdit: () => undoCalls++,
        canUndo: true,
      );

      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      await tester.tap(find.text('Desfazer'));
      await tester.pump();
      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      expect(saveCalls, 1);
      expect(undoCalls, 1);
      expect(cancelCalls, 1);
      expect(finishCalls, 0);
      expect(cancelDrawingCalls, 0);
    },
  );

  testWidgets('MapControlsOverlay exibe check-in quando ação está habilitada', (
    tester,
  ) async {
    await _pumpMapControlsOverlay(tester, showCheckInAction: true);

    expect(find.byKey(const Key('map_control_check_in')), findsOneWidget);
  });

  testWidgets(
    'MapControlsOverlay oculta check-in quando ação está desabilitada',
    (tester) async {
      await _pumpMapControlsOverlay(tester, showCheckInAction: false);

      expect(find.byKey(const Key('map_control_check_in')), findsNothing);
    },
  );

  testWidgets(
    'MapControlsOverlay renderiza card customizado no topo esquerdo',
    (tester) async {
      await _pumpMapControlsOverlay(
        tester,
        showCheckInAction: false,
        topLeftCard: const Text('Contexto produtor'),
      );

      expect(find.text('Contexto produtor'), findsOneWidget);
      expect(find.byKey(const Key('map_control_check_in')), findsNothing);
    },
  );

  testWidgets('card de medição compacto mostra apenas a área', (tester) async {
    await _pumpMapControlsOverlay(
      tester,
      showCheckInAction: false,
      measurementAreaHa: 17.407,
      measurementPerimeterKm: 1.711,
      measurementAzimuthDeg: 159.3,
      gpsAccuracyM: 4.2,
    );

    expect(find.text('17.407 ha'), findsOneWidget);
    expect(find.text('Medição'), findsNothing);
    expect(find.textContaining('Perímetro:'), findsNothing);
    expect(find.textContaining('Azimute:'), findsNothing);
    expect(find.textContaining('GPS:'), findsNothing);
    expect(find.text('ha'), findsOneWidget);
    expect(find.text('m²'), findsOneWidget);
    expect(find.text('alq GO/MG'), findsOneWidget);
    expect(find.text('km'), findsNothing);
    expect(find.byKey(const Key('measurement_details_card')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('measurement_area_card'))).height,
      lessThan(105),
    );
  });

  testWidgets('detalhes da medição abrem em painel auxiliar', (tester) async {
    await _pumpMapControlsOverlay(
      tester,
      showCheckInAction: false,
      measurementAreaHa: 17.407,
      measurementPerimeterKm: 1.711,
      measurementAzimuthDeg: 159.3,
      gpsAccuracyM: 4.2,
    );

    await tester.tap(find.byKey(const Key('measurement_details_toggle')));
    await tester.pump();

    expect(find.byKey(const Key('measurement_details_card')), findsOneWidget);
    expect(find.text('Perímetro: 1.711 km'), findsOneWidget);
    expect(find.text('Azimute: 159.3°'), findsOneWidget);
    expect(find.text('GPS: ±4.2 m'), findsOneWidget);
    expect(find.text('km'), findsOneWidget);
    expect(find.text('m'), findsOneWidget);
  });
}

void _noop() {}

Future<void> _pumpMapControlsOverlay(
  WidgetTester tester, {
  bool showCheckInAction = true,
  Widget? topLeftCard,
  DrawingState drawingState = DrawingState.idle,
  bool isDrawMode = false,
  double measurementAreaHa = 0,
  double measurementPerimeterKm = 0,
  double? measurementAzimuthDeg,
  double gpsAccuracyM = 0,
  VoidCallback onFinishDrawing = _noop,
  VoidCallback onCancelDrawing = _noop,
  VoidCallback onSaveEdit = _noop,
  VoidCallback onCancelEdit = _noop,
  VoidCallback onUndoEdit = _noop,
  VoidCallback? onUndoDrawing,
  bool canUndo = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final settingsRepository = SettingsRepository(
    await SharedPreferences.getInstance(),
  );
  final preferencesService = PreferencesService(
    await SharedPreferences.getInstance(),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        visitRepositoryProvider.overrideWithValue(_NoActiveVisitRepository()),
        agendaSessionBridgeProvider.overrideWithValue(_NoopAgendaBridge()),
        sessionControllerProvider.overrideWith(_PublicSessionController.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MapControlsOverlay(
            onCenterUser: _noop,
            onLocationModeChanged: (_) {},
            onToggleDrawMode: _noop,
            onOpenMapTools: _noop,
            onTabSelected: (_, _) {},
            isDrawMode: isDrawMode,
            showCheckInAction: showCheckInAction,
            topLeftCard: topLeftCard,
            currentCenter: const LatLng(0, 0),
            currentZoom: 13,
            measurementAreaHa: measurementAreaHa,
            measurementPerimeterKm: measurementPerimeterKm,
            measurementAzimuthDeg: measurementAzimuthDeg,
            gpsAccuracyM: gpsAccuracyM,
            drawingState: drawingState,
            onFinishDrawing: onFinishDrawing,
            onCancelDrawing: onCancelDrawing,
            onSaveEdit: onSaveEdit,
            onCancelEdit: onCancelEdit,
            onUndoEdit: onUndoEdit,
            onUndoDrawing: onUndoDrawing,
            canUndo: canUndo,
          ),
        ),
      ),
    ),
  );
}

class _NoActiveVisitRepository extends VisitRepository {
  @override
  Future<VisitSession?> getActiveSession() async => null;
}

class _NoopAgendaBridge implements IAgendaSessionBridge {
  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {}

  @override
  Future<void> markEventAsDone(String sessionId) async {}
}

class _PublicSessionController extends SessionController {
  @override
  SessionState build() => const SessionPublic();
}
