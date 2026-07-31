import 'dart:io';

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
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_action_fab_menu.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';

/// BUG-002 / BUG-005 — Map: botões errados na coluna direita / publicações removidas.
void main() {
  group('BUG-002 controls_overlay_regression', () {
    test('map_controls_overlay.dart não referencia botões legados de coordenada/offline', () {
      final source = File(
        'lib/ui/components/map/widgets/map_controls_overlay.dart',
      ).readAsStringSync();

      expect(source.contains('coordinateButton'), isFalse);
      expect(source.contains('offlineDownloadButton'), isFalse);
      expect(source.contains('ValueKey(\'coordinateButton\')'), isFalse);
      expect(source.contains('ValueKey(\'offlineDownloadButton\')'), isFalse);
    });

    testWidgets('coluna direita não contém keys legadas de coordenada/offline', (
      tester,
    ) async {
      await _pumpMapControlsOverlay(tester);

      expect(find.byKey(const ValueKey('coordinateButton')), findsNothing);
      expect(find.byKey(const ValueKey('offlineDownloadButton')), findsNothing);
    });

    testWidgets(
      'coluna direita mantém ferramentas essenciais do mapa (layers, ações, check-in)',
      (tester) async {
        await _pumpMapControlsOverlay(tester);

        expect(find.byTooltip('Ferramentas do mapa'), findsOneWidget);
        expect(find.byType(MapActionFabMenu), findsOneWidget);
        expect(find.byTooltip('Check-in'), findsOneWidget);
      },
    );
  });

  group('BUG-005 controls_overlay_publicacoes_regression', () {
    test('map_controls_overlay.dart não referencia publicações no mapa', () {
      final source = File(
        'lib/ui/components/map/widgets/map_controls_overlay.dart',
      ).readAsStringSync();

      expect(source.contains('publicacoesButton'), isFalse);
      expect(source.contains('/consultoria/publicacoes'), isFalse);
      expect(source.toLowerCase().contains('publicacoes'), isFalse);
    });

    testWidgets('widget tree do overlay não exibe botão de publicações', (
      tester,
    ) async {
      await _pumpMapControlsOverlay(tester);

      expect(find.text('Publicações'), findsNothing);
      expect(find.text('Publicacoes'), findsNothing);
      expect(find.textContaining('publica', findRichText: true), findsNothing);
    });
  });

  group('map status indicator', () {
    testWidgets('vermelho quando offline', (tester) async {
      await _pumpMapControlsOverlay(tester, isOnline: false, radarEnabled: false);

      final indicator = tester.widget<Container>(
        find.byKey(const Key('map_status_indicator')),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFFF3B30));
    });

    testWidgets('verde quando online sem chuva no mapa', (tester) async {
      await _pumpMapControlsOverlay(tester, isOnline: true, radarEnabled: false);

      final indicator = tester.widget<Container>(
        find.byKey(const Key('map_status_indicator')),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF34C759));
    });

    testWidgets('azul Samsung quando online com chuva no mapa', (tester) async {
      await _pumpMapControlsOverlay(tester, isOnline: true, radarEnabled: true);

      final indicator = tester.widget<Container>(
        find.byKey(const Key('map_status_indicator')),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF1428A0));
    });
  });
}

Future<void> _pumpMapControlsOverlay(
  WidgetTester tester, {
  bool isOnline = true,
  bool radarEnabled = false,
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
        isOnlineProvider.overrideWith((ref) => Stream.value(isOnline)),
        climaRadarEnabledProvider.overrideWith(
          () => _PresetClimaRadarEnabled(radarEnabled),
        ),
        visitRepositoryProvider.overrideWithValue(_NoActiveVisitRepository()),
        agendaSessionBridgeProvider.overrideWithValue(_NoopAgendaBridge()),
        sessionControllerProvider.overrideWith(_PublicSessionController.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: MapControlsOverlay(
            onCenterUser: () {},
            onLocationModeChanged: (_) {},
            onToggleDrawMode: () {},
            onOpenMapTools: () {},
            onTabSelected: (_, _) {},
            isDrawMode: false,
            showCheckInAction: true,
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

class _PresetClimaRadarEnabled extends ClimaRadarEnabled {
  _PresetClimaRadarEnabled(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}
