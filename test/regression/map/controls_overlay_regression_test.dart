import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_state.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/radar_providers.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/state/map_ui_providers.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_controls_overlay.dart';
import 'package:soloforte_app/ui/components/smart_button.dart';

const _kViewport = Size(400, 800);
const _kSafeBottom = 34.0;

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

    test('map_controls_overlay.dart não referencia mapSheetChromeInsetProvider', () {
      final source = File(
        'lib/ui/components/map/widgets/map_controls_overlay.dart',
      ).readAsStringSync();

      expect(source.contains('mapSheetChromeInsetProvider'), isFalse);
      expect(source.contains('kMapActionColumnBottomInset'), isTrue);
      expect(source.contains('kMapActionColumnSpacingAboveCheckIn'), isTrue);
      expect(source.contains('kMapActionColumnButtonSize'), isTrue);
      expect(source.contains('MapActionFabMenu'), isFalse);
      expect(source.contains('map_control_actions_btn'), isFalse);
    });

    testWidgets('coluna direita não contém keys legadas de coordenada/offline', (
      tester,
    ) async {
      await _pumpMapControlsOverlay(tester);

      expect(find.byKey(const ValueKey('coordinateButton')), findsNothing);
      expect(find.byKey(const ValueKey('offlineDownloadButton')), findsNothing);
    });

    testWidgets(
      'coluna direita mantém ferramentas essenciais do mapa (layers, check-in)',
      (tester) async {
        await _pumpMapControlsOverlay(tester);

        expect(find.byTooltip('Ferramentas do mapa'), findsOneWidget);
        expect(find.byKey(const Key('map_control_actions_btn')), findsNothing);
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

  group('coluna direita alinhamento', () {
    testWidgets(
      'gap canônico 16dp layers↔check-in e bottom absoluto (REGRA-MAP-CHROME-1)',
      (tester) async {
        await _pumpMapControlsOverlay(
          tester,
          safePadding: const EdgeInsets.only(bottom: _kSafeBottom),
        );

        final layers = _buttonBounds(tester, 'map_control_layers_btn');
        final checkIn = _buttonBounds(tester, 'map_control_check_in');

        expect(layers.width, closeTo(kMapActionColumnButtonSize, 0.1));
        expect(checkIn.width, closeTo(kMapActionColumnButtonSize, 0.1));
        expect(layers.right, closeTo(checkIn.right, 0.1));

        expect(
          layers.bottom,
          closeTo(checkIn.top - kMapActionColumnSpacingAboveCheckIn, 0.1),
        );
        expect(
          checkIn.bottom - layers.bottom,
          closeTo(
            kMapActionColumnButtonSize + kMapActionColumnSpacingAboveCheckIn,
            0.1,
          ),
        );
        expect(
          checkIn.bottom,
          closeTo(
            _kViewport.height - _kSafeBottom - kMapActionColumnBottomInset,
            0.1,
          ),
        );
      },
    );

    testWidgets(
      'integração overlay + âncora FAB: clearance 4dp com safeBottom real',
      (tester) async {
        await _pumpOverlayWithFabHarness(
          tester,
          safePadding: const EdgeInsets.only(bottom: _kSafeBottom),
        );

        final checkIn = _buttonBounds(tester, 'map_control_check_in');
        final fab = _buttonBounds(tester, 'map_chrome_fab_harness');

        expect(
          checkIn.bottom,
          closeTo(
            _kViewport.height - _kSafeBottom - kMapActionColumnBottomInset,
            0.1,
          ),
        );
        expect(
          fab.bottom,
          closeTo(
            _kViewport.height - (_kSafeBottom + kFabShellBottomInset),
            0.1,
          ),
        );
        expect(
          fab.top - checkIn.bottom,
          closeTo(kFabContentClearance, 0.1),
        );
      },
    );

    testWidgets(
      'modo produtor: sem check-in e layers ancorado no bottom inset',
      (tester) async {
        const safe = EdgeInsets.only(bottom: _kSafeBottom);

        await _pumpMapControlsOverlay(
          tester,
          showCheckInAction: true,
          safePadding: safe,
        );
        final consultorLayers = _buttonBounds(tester, 'map_control_layers_btn');

        await _pumpMapControlsOverlay(
          tester,
          showCheckInAction: false,
          safePadding: safe,
        );

        expect(find.byKey(const Key('map_control_check_in')), findsNothing);
        final produtorLayers = _buttonBounds(tester, 'map_control_layers_btn');

        expect(
          produtorLayers.bottom,
          closeTo(
            _kViewport.height - _kSafeBottom - kMapActionColumnBottomInset,
            0.1,
          ),
        );
        // Sem check-in a coluna encolhe: layers desce exatamente gap+button.
        expect(
          produtorLayers.bottom - consultorLayers.bottom,
          closeTo(
            kMapActionColumnSpacingAboveCheckIn + kMapActionColumnButtonSize,
            0.1,
          ),
        );
      },
    );

    testWidgets('coluna permanece fixa quando sheet inset muda (REGRA-MAP-CHROME-1)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final settingsRepository = SettingsRepository(
        await SharedPreferences.getInstance(),
      );
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );

      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          isOnlineProvider.overrideWith((ref) => Stream.value(true)),
          climaRadarEnabledProvider.overrideWith(
            () => _PresetClimaRadarEnabled(false),
          ),
          visitRepositoryProvider.overrideWithValue(_NoActiveVisitRepository()),
          agendaSessionBridgeProvider.overrideWithValue(_NoopAgendaBridge()),
          sessionControllerProvider.overrideWith(_PublicSessionController.new),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      final baselineCheckIn = _buttonBounds(tester, 'map_control_check_in');
      final baselineLayers = _buttonBounds(tester, 'map_control_layers_btn');

      container.read(mapSheetChromeInsetProvider.notifier).state = 200;
      await tester.pumpAndSettle();

      final insetCheckIn = _buttonBounds(tester, 'map_control_check_in');
      final insetLayers = _buttonBounds(tester, 'map_control_layers_btn');

      expect(insetCheckIn.bottom, closeTo(baselineCheckIn.bottom, 0.1));
      expect(insetLayers.bottom, closeTo(baselineLayers.bottom, 0.1));
    });

    testWidgets('modo desenho mantém camadas na posição superior da coluna', (
      tester,
    ) async {
      await _pumpMapControlsOverlay(tester, isDrawMode: false);
      final fullModeLayers = _buttonBounds(tester, 'map_control_layers_btn');

      await _pumpMapControlsOverlay(tester, isDrawMode: true);
      final drawModeLayers = _buttonBounds(tester, 'map_control_layers_btn');

      expect(drawModeLayers.bottom, closeTo(fullModeLayers.bottom, 0.1));
      expect(drawModeLayers.right, closeTo(fullModeLayers.right, 0.1));
      expect(find.byKey(const Key('map_control_actions_btn')), findsNothing);
      expect(find.byKey(const Key('map_control_check_in')), findsNothing);
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

  /// BUG-009 — Flash ao tocar ícones/abrir sheets (fix 868cbea).
  group('BUG-009 map_flash_regression', () {
    test('map _MapActionButton label só em long-press, não no onTap', () {
      final source = File(
        'lib/ui/components/map/widgets/map_controls_overlay.dart',
      ).readAsStringSync();

      final classStart = source.indexOf('class _MapActionButton extends');
      final classEnd = source.indexOf('class _MapToolsFab extends', classStart);
      final mapButtonSource = source.substring(classStart, classEnd);

      expect(mapButtonSource.contains('onLongPress: _showTemporaryLabel'), isTrue);
      final onTapStart = mapButtonSource.indexOf('onTap: () {');
      final onTapEnd = mapButtonSource.indexOf('onLongPress:', onTapStart);
      final onTapBlock = mapButtonSource.substring(onTapStart, onTapEnd);
      expect(onTapBlock.contains('_showTemporaryLabel'), isFalse);
    });

    test('app_shell mantém SmartButton estável (wrapper const, sem key por rota)', () {
      final source = File('lib/ui/components/app_shell.dart').readAsStringSync();

      expect(source.contains('const _SmartButtonWrapper()'), isTrue);
      expect(source.contains('const SmartButton()'), isTrue);
      expect(source.contains('remonta o FAB a cada'), isTrue);
      expect(source.contains('key: ValueKey'), isFalse);
      expect(source.contains('ValueKey(GoRouter'), isFalse);
    });

    test('private_map_screen evita reabrir modal do mesmo tipo (sameModalAlreadyOpen)', () {
      final source = File(
        'lib/ui/screens/private_map_screen.dart',
      ).readAsStringSync();

      expect(source.contains('sameModalAlreadyOpen'), isTrue);
      expect(
        source.contains('Já há modal do mesmo tipo — só atualiza estado'),
        isTrue,
      );
    });

    testWidgets('tap no check-in não mostra label; longPress mostra', (tester) async {
      await _pumpMapControlsOverlay(tester);

      await tester.tap(find.byKey(const Key('map_control_check_in')));
      await tester.pump();
      expect(find.text('Check-in'), findsNothing);

      await tester.longPress(find.byKey(const Key('map_control_check_in')));
      await tester.pump();
      expect(find.text('Check-in'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1700));
      expect(find.text('Check-in'), findsNothing);
    });

    testWidgets(
      'SmartButton const mantém Element idêntico ao trocar de rota',
      (tester) async {
        final router = GoRouter(
          initialLocation: AppRoutes.map,
          routes: [
            ShellRoute(
              builder: (context, state, child) {
                return MediaQuery(
                  data: const MediaQueryData(size: _kViewport),
                  child: Scaffold(
                    body: Stack(
                      children: [
                        child,
                        const Positioned(
                          bottom: 16,
                          right: 16,
                          child: SmartButton(),
                        ),
                      ],
                    ),
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: AppRoutes.map,
                  builder: (_, _) => const ColoredBox(color: Colors.green),
                ),
                GoRoute(
                  path: AppRoutes.settings,
                  builder: (_, _) => const ColoredBox(color: Colors.blue),
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        await tester.pumpAndSettle();

        final before = tester.element(find.byType(SmartButton));
        router.go(AppRoutes.settings);
        await tester.pumpAndSettle();

        expect(find.byType(SmartButton), findsOneWidget);
        final after = tester.element(find.byType(SmartButton));
        expect(identical(before, after), isTrue);

        router.go(AppRoutes.map);
        await tester.pumpAndSettle();
        expect(
          identical(before, tester.element(find.byType(SmartButton))),
          isTrue,
        );
      },
    );
  });
}

void _setViewport(WidgetTester tester, EdgeInsets safePadding) {
  tester.view.physicalSize = _kViewport;
  tester.view.devicePixelRatio = 1.0;
  tester.view.padding = FakeViewPadding(
    bottom: safePadding.bottom,
    top: safePadding.top,
    left: safePadding.left,
    right: safePadding.right,
  );
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _pumpMapControlsOverlay(
  WidgetTester tester, {
  bool isOnline = true,
  bool radarEnabled = false,
  bool isDrawMode = false,
  bool showCheckInAction = true,
  EdgeInsets safePadding = EdgeInsets.zero,
}) async {
  _setViewport(tester, safePadding);
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
            isDrawMode: isDrawMode,
            showCheckInAction: showCheckInAction,
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

/// Espelha o contrato AppShell: overlay + FAB em `safeBottom + kFabShellBottomInset`.
Future<void> _pumpOverlayWithFabHarness(
  WidgetTester tester, {
  required EdgeInsets safePadding,
}) async {
  _setViewport(tester, safePadding);
  SharedPreferences.setMockInitialValues({});
  final settingsRepository = SettingsRepository(
    await SharedPreferences.getInstance(),
  );
  final preferencesService = PreferencesService(
    await SharedPreferences.getInstance(),
  );
  final safeBottom = safePadding.bottom;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesServiceProvider.overrideWithValue(preferencesService),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        isOnlineProvider.overrideWith((ref) => Stream.value(true)),
        climaRadarEnabledProvider.overrideWith(
          () => _PresetClimaRadarEnabled(false),
        ),
        visitRepositoryProvider.overrideWithValue(_NoActiveVisitRepository()),
        agendaSessionBridgeProvider.overrideWithValue(_NoopAgendaBridge()),
        sessionControllerProvider.overrideWith(_PublicSessionController.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              MapControlsOverlay(
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
              Positioned(
                bottom: safeBottom + kFabShellBottomInset,
                right: 16,
                child: SizedBox(
                  key: const Key('map_chrome_fab_harness'),
                  width: kFabHeight,
                  height: kFabHeight,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _buttonBounds(WidgetTester tester, String keyName) {
  final finder = find.byKey(Key(keyName));
  expect(finder, findsOneWidget);
  return Rect.fromPoints(
    tester.getTopLeft(finder),
    tester.getBottomRight(finder),
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

class _PresetClimaRadarEnabled extends ClimaRadarEnabled {
  _PresetClimaRadarEnabled(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}
