import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/ui/components/map/widgets/editing_controls_overlay.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

void main() {
  testWidgets('renderiza backplate sólido e ações principais do desenho', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DrawingControlsCluster(
            primaryColor: Colors.green,
            hasSelfIntersection: false,
            onFinishDrawing: _noop,
            onUndoDrawing: _noop,
            onCancelDrawing: _noop,
            canUndo: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('drawing_controls_backplate')), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.byType(InkWell), findsNWidgets(3));
  });

  testWidgets(
    'modo editing usa cluster lateral e não renderiza overlay branco legado',
    (tester) async {
      var saveCalls = 0;
      var cancelCalls = 0;
      var undoCalls = 0;
      var redoCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditingControlsCluster(
              onSave: () => saveCalls++,
              onCancel: () => cancelCalls++,
              onUndo: () => undoCalls++,
              onRedo: () => redoCalls++,
              canUndo: true,
              canRedo: true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('editing_controls_backplate')),
        findsOneWidget,
      );
      expect(find.byType(EditingControlsOverlay), findsNothing);

      await tester.tap(find.byKey(const Key('editing_control_save')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('editing_control_undo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('editing_control_redo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('editing_control_cancel')));
      await tester.pump();

      expect(saveCalls, 1);
      expect(undoCalls, 1);
      expect(redoCalls, 1);
      expect(cancelCalls, 1);
    },
  );

  testWidgets('MapControlsOverlay monta cluster lateral no estado editing', (
    tester,
  ) async {
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
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MapControlsOverlay(
              onCenterUser: _noop,
              onLocationModeChanged: (_) {},
              onToggleDrawMode: _noop,
              onOpenMapTools: _noop,
              onTabSelected: (_, _) {},
              isDrawMode: true,
              currentCenter: const LatLng(0, 0),
              currentZoom: 13,
              drawingState: DrawingState.editing,
              onFinishDrawing: _noop,
              onCancelDrawing: _noop,
              onSaveEdit: _noop,
              onCancelEdit: _noop,
              onUndoEdit: _noop,
              onRedoEdit: _noop,
              canUndo: true,
              canRedo: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('editing_controls_backplate')), findsOneWidget);
    expect(find.byType(EditingControlsOverlay), findsNothing);
    expect(find.byKey(const Key('drawing_controls_backplate')), findsNothing);
  });

  testWidgets('MapControlsOverlay exibe check-in quando ação está habilitada', (
    tester,
  ) async {
    await _pumpMapControlsOverlay(tester, showCheckInAction: true);

    expect(find.byTooltip('Check-in'), findsOneWidget);
  });

  testWidgets(
    'MapControlsOverlay oculta check-in quando ação está desabilitada',
    (tester) async {
      await _pumpMapControlsOverlay(tester, showCheckInAction: false);

      expect(find.byTooltip('Check-in'), findsNothing);
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
      expect(find.byTooltip('Check-in'), findsNothing);
    },
  );
}

void _noop() {}

Future<void> _pumpMapControlsOverlay(
  WidgetTester tester, {
  required bool showCheckInAction,
  Widget? topLeftCard,
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
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MapControlsOverlay(
            onCenterUser: _noop,
            onLocationModeChanged: (_) {},
            onToggleDrawMode: _noop,
            onOpenMapTools: _noop,
            onTabSelected: (_, _) {},
            isDrawMode: false,
            showCheckInAction: showCheckInAction,
            topLeftCard: topLeftCard,
            currentCenter: const LatLng(0, 0),
            currentZoom: 13,
            drawingState: DrawingState.idle,
            onFinishDrawing: _noop,
            onCancelDrawing: _noop,
            onSaveEdit: _noop,
            onCancelEdit: _noop,
            onUndoEdit: _noop,
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
