import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
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
import 'package:soloforte_app/modules/agenda/presentation/providers/agenda_provider.dart';
import 'package:soloforte_app/modules/agenda/presentation/providers/agenda_state.dart';
import 'package:soloforte_app/ui/components/side_menu_overlay.dart';
import 'package:soloforte_app/ui/components/side_menu_quick_access.dart';

void main() {
  group('SideMenuOverlay', () {
    testWidgets('produtor vê apenas as áreas permitidas', (tester) async {
      await _pumpSideMenu(tester, profile: _profile(role: 'produtor'));

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Clima'), findsNothing);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Minha propriedade'), findsOneWidget);
      expect(find.text('Meu Plano'), findsOneWidget);
      expect(find.text('Sincronizar agora'), findsOneWidget);
      expect(find.text('Agenda'), findsNothing);
      expect(find.text('Clientes'), findsNothing);
      expect(find.text('Receber código'), findsNothing);
      expect(find.text('Relatórios'), findsOneWidget);
      expect(find.text('Carteira'), findsNothing);
      expect(find.text('ACESSO RÁPIDO'), findsNothing);
      expect(find.text('Ir para local'), findsNothing);
    });

    testWidgets('consultor vê um único acesso rápido, sem atalhos fixos', (
      tester,
    ) async {
      await _pumpSideMenu(
        tester,
        profile: _profile(role: 'consultor'),
        role: UserRole.consultor,
      );

      expect(find.text('Agenda'), findsOneWidget);
      expect(find.byKey(const Key('side_menu_greeting')), findsOneWidget);
      expect(find.text('Nenhuma visita pendente hoje'), findsOneWidget);
      expect(find.text('Clientes'), findsWidgets);
      expect(find.text('Receber código'), findsNothing);
      expect(find.text('Relatórios'), findsWidgets);
      expect(find.text('Carteira'), findsWidgets);
      expect(find.text('Nova Visita'), findsOneWidget);
      expect(find.text('Novo Cliente'), findsOneWidget);
      expect(find.text('ACESSO RÁPIDO'), findsOneWidget);
      expect(find.text('Atalhos'), findsNothing);
      expect(find.text('Foco no que importa'), findsNothing);
      expect(find.text('Ir para local'), findsNothing);
      expect(
        find.byKey(const Key('side_menu_quick_access_edit')),
        findsOneWidget,
      );
    });

    for (final testCase in [
      (
        key: const Key('side_menu_quick_visitas'),
        expectedUri: AppRoutes.agenda,
      ),
      (
        key: const Key('side_menu_quick_clientes'),
        expectedUri: AppRoutes.clients,
      ),
      (
        key: const Key('side_menu_quick_carteira'),
        expectedUri: AppRoutes.carteira,
      ),
      (
        key: const Key('side_menu_quick_relatorios'),
        expectedUri: AppRoutes.reports,
      ),
      (
        key: const Key('side_menu_quick_nova_visita'),
        expectedUri: '${AppRoutes.agenda}?novoEvento=true',
      ),
      (
        key: const Key('side_menu_quick_novo_cliente'),
        expectedUri: AppRoutes.clientNew,
      ),
    ]) {
      testWidgets('${testCase.key} navega para ${testCase.expectedUri}', (
        tester,
      ) async {
        final router = await _pumpSideMenu(
          tester,
          profile: _profile(role: 'consultor'),
          role: UserRole.consultor,
        );

        await _tapQuickAction(tester, find.byKey(testCase.key));

        expect(
          router.routerDelegate.currentConfiguration.uri.toString(),
          testCase.expectedUri,
        );
      });
    }

    testWidgets('consultor tira um atalho e a escolha fica salva', (
      tester,
    ) async {
      await _pumpSideMenu(
        tester,
        profile: _profile(role: 'consultor'),
        role: UserRole.consultor,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('side_menu_quick_access_edit')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('side_menu_quick_access_edit')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('side_menu_quick_access_toggle_nova_visita')),
      );
      await tester.pumpAndSettle();

      Navigator.of(
        tester.element(find.byType(SideMenuQuickAccessEditor)),
      ).pop();
      await tester.pumpAndSettle();

      expect(find.text('Nova Visita'), findsNothing);
      expect(find.text('Novo Cliente'), findsOneWidget);

      final saved = (await SharedPreferences.getInstance()).getStringList(
        sideMenuQuickAccessStorageKey('test-user'),
      );
      expect(saved, isNot(contains('nova_visita')));
      expect(saved, contains('novo_cliente'));
    });

    testWidgets('não gera overflow em tela estreita', (tester) async {
      await _pumpSideMenu(
        tester,
        size: const Size(320, 568),
        profile: _profile(role: 'consultor'),
        role: UserRole.consultor,
      );

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.byKey(const Key('side_menu_quick_access_edit')),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('side_menu_quick_access_edit')),
        findsOneWidget,
      );
      expect(find.text('Ir para local'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    test('decode do acesso rápido ignora id desconhecido', () {
      expect(decodeSideMenuQuickAccess(null), SideMenuQuickAction.values);
      expect(decodeSideMenuQuickAccess(const []), isEmpty);
      expect(
        decodeSideMenuQuickAccess(const ['clientes', 'nope', 'clientes']),
        [SideMenuQuickAction.clientes],
      );
    });
  });
}

Future<void> _tapQuickAction(WidgetTester tester, Finder action) async {
  final menuScroll = find
      .descendant(
        of: find.byType(SideMenuOverlay),
        matching: find.byType(Scrollable),
      )
      .first;
  await tester.scrollUntilVisible(action, 160, scrollable: menuScroll);
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

Future<GoRouter> _pumpSideMenu(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  String initialLocation = AppRoutes.map,
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
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.map, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.agenda, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.clientNew, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.clients, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.carteira, builder: (_, __) => const _MenuHost()),
      GoRoute(path: AppRoutes.reports, builder: (_, __) => const _MenuHost()),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sideMenuOpenProvider.overrideWith((ref) => true),
        agendaProvider.overrideWith(_FakeAgenda.new),
        preferencesServiceProvider.overrideWithValue(
          PreferencesService(preferences),
        ),
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

/// Agenda vazia, sem repositório/sessão reais.
class _FakeAgenda extends Agenda {
  @override
  AgendaState build() => const AgendaState();
}
