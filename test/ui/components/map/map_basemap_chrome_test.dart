import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

void main() {
  test('SFIcons.satellite não reutiliza ícone de bússola/nearMe', () {
    final source =
        File('lib/core/design/sf_icons.dart').readAsStringSync();
    expect(source.contains('location_north_fill'), isTrue);
    expect(
      source.contains('satellite =\n      CupertinoIcons.location_north_fill'),
      isFalse,
    );
    expect(source.contains('Icons.satellite_alt_outlined'), isTrue);
  });

  testWidgets('toggle basemap no chrome alterna activeLayerProvider', (
    tester,
  ) async {
    await _pumpOverlay(tester, themeId: 'green');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapControlsOverlay)),
    );
    expect(container.read(activeLayerProvider), LayerType.satellite);

    await tester.tap(find.byKey(const Key('map_control_basemap_toggle_btn')));
    await tester.pump();

    expect(container.read(activeLayerProvider), LayerType.standard);

    await tester.tap(find.byKey(const Key('map_control_basemap_toggle_btn')));
    await tester.pump();

    expect(container.read(activeLayerProvider), LayerType.satellite);
  });

  testWidgets('toggle pinos no chrome alterna showMarkersProvider', (
    tester,
  ) async {
    await _pumpOverlay(tester, themeId: 'green');

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MapControlsOverlay)),
    );
    expect(container.read(showMarkersProvider), isTrue);

    await tester.tap(find.byKey(const Key('map_control_pins_toggle_btn')));
    await tester.pump();

    expect(container.read(showMarkersProvider), isFalse);

    await tester.tap(find.byKey(const Key('map_control_pins_toggle_btn')));
    await tester.pump();

    expect(container.read(showMarkersProvider), isTrue);
  });

  for (final themeId in ['green', 'blue', 'black']) {
    testWidgets('botão basemap renderiza com tema $themeId', (tester) async {
      await _pumpOverlay(tester, themeId: themeId);
      expect(
        find.byKey(const Key('map_control_basemap_toggle_btn')),
        findsOneWidget,
      );
    });
  }
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required String themeId,
}) async {
  SharedPreferences.setMockInitialValues({'app_theme_mode': themeId});
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
            onCenterUser: () {},
            onLocationModeChanged: (_) {},
            onOpenMapTools: () {},
            onTabSelected: (_, _) {},
            isDrawMode: false,
            showCheckInAction: false,
            currentCenter: const LatLng(-10.2, -48.3),
            currentZoom: 13,
            drawingState: DrawingState.idle,
            onFinishDrawing: () {},
            onCancelDrawing: () {},
            onSaveEdit: () {},
            onCancelEdit: () {},
            onUndoEdit: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _NoActiveVisitRepository implements VisitRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopAgendaBridge implements IAgendaSessionBridge {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PublicSessionController extends SessionController {
  @override
  SessionState build() => const SessionPublic();
}
