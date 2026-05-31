import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_service.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/components/side_menu_overlay.dart';

void main() {
  group('SideMenuOverlay', () {
    testWidgets('preserva funcionalidades e exibe acessos rápidos', (
      tester,
    ) async {
      await _pumpSideMenu(tester);

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Meu Plano'), findsOneWidget);
      expect(find.text('Sincronizar agora'), findsOneWidget);
      expect(find.text('Nova Visita'), findsOneWidget);
      expect(find.text('Novo Cliente'), findsOneWidget);
      expect(find.text('Ver Relatórios'), findsOneWidget);
      expect(find.text('Nova Ocorrência'), findsOneWidget);
    });

    for (final testCase in [
      (
        label: 'Nova Visita',
        expectedUri: '${AppRoutes.agenda}?novoEvento=true',
      ),
      (label: 'Novo Cliente', expectedUri: AppRoutes.clientNew),
      (label: 'Ver Relatórios', expectedUri: AppRoutes.reports),
      (
        label: 'Nova Ocorrência',
        expectedUri: '${AppRoutes.map}?modo=ocorrencia',
      ),
    ]) {
      testWidgets('${testCase.label} navega para ${testCase.expectedUri}', (
        tester,
      ) async {
        final router = await _pumpSideMenu(tester);
        final action = find.text(testCase.label);

        await tester.scrollUntilVisible(
          action,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          testCase.expectedUri,
        );
      });
    }

    testWidgets('não gera overflow em tela estreita', (tester) async {
      await _pumpSideMenu(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Foco no que importa'),
        220,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();

      expect(find.text('Foco no que importa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<GoRouter> _pumpSideMenu(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final settingsRepository = SettingsRepository(preferences);
  final router = GoRouter(
    initialLocation: AppRoutes.map,
    routes: [
      GoRoute(path: AppRoutes.map, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.agenda, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.clientNew, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.reports, builder: (_, __) => const _MenuHost()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sideMenuOpenProvider.overrideWith((ref) => true),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        currentUserProfileProvider.overrideWith((ref) async => null),
        planoAtivoProvider.overrideWith(
          (ref) async => UserPlan.free(userId: 'test-user'),
        ),
        manualSyncProvider.overrideWith((ref) async {}),
        connectivityStateProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();

  return router;
}

class _MenuHost extends StatelessWidget {
  const _MenuHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Stack(children: [SideMenuOverlay()]));
  }
}
