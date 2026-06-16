import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_service.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/settings/domain/entities/user_profile.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/components/side_menu_overlay.dart';

void main() {
  group('SideMenuOverlay', () {
    testWidgets('produtor vê apenas as áreas permitidas', (tester) async {
      await _pumpSideMenu(tester, profile: _profile(role: 'produtor'));

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Clima'), findsOneWidget);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Minha propriedade'), findsOneWidget);
      expect(find.text('Meu Plano'), findsOneWidget);
      expect(find.text('Sincronizar agora'), findsOneWidget);
      expect(find.text('Agenda'), findsNothing);
      expect(find.text('Clientes'), findsNothing);
      expect(find.text('Relatórios'), findsNothing);
      expect(find.text('Carteira'), findsNothing);
      expect(find.text('Acesso rápido'), findsNothing);
    });

    testWidgets('consultor vê o menu completo e atalhos', (tester) async {
      await _pumpSideMenu(
        tester,
        profile: _profile(role: 'consultor'),
        role: UserRole.consultor,
      );

      expect(find.text('Agenda'), findsOneWidget);
      expect(find.text('Clientes'), findsWidgets);
      expect(find.text('Relatórios'), findsWidgets);
      expect(find.text('Carteira'), findsWidgets);
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
        final router = await _pumpSideMenu(
          tester,
          profile: _profile(role: 'consultor'),
          role: UserRole.consultor,
        );
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
      await _pumpSideMenu(
        tester,
        size: const Size(320, 568),
        profile: _profile(role: 'consultor'),
        role: UserRole.consultor,
      );

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
  UserProfile? profile,
  UserRole role = UserRole.produtor,
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
        currentUserProfileProvider.overrideWith((ref) async => profile),
        currentUserRoleProvider.overrideWith((ref) => role),
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

UserProfile _profile({required String role}) {
  return UserProfile(
    id: 'test-user',
    email: 'test@soloforte.app',
    fullName: 'Teste',
    phone: '(63) 99999-9999',
    role: role,
    photoUrl: null,
    creaNumber: role == 'consultor' ? '123456' : null,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

class _MenuHost extends StatelessWidget {
  const _MenuHost();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Stack(children: [SideMenuOverlay()]));
  }
}
