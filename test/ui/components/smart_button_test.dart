/*
════════════════════════════════════════════════════════════════════
TESTES AUTOMATIZADOS — SMARTBUTTON (FAB GLOBAL)
════════════════════════════════════════════════════════════════════

OBJETIVO:
Proteger o contrato Map-First contra regressões futuras.

COBERTURA:
1. Cenário: Rota /map → FAB abre SideMenu
2. Cenário: Fora do /map → FAB navega para /map

PROIBIÇÕES:
❌ Mock de stack de navegação
❌ Testes de UI visual complexa
❌ Testes que dependem de estado global

REFERÊNCIA:
- docs/arquitetura-navegacao.md (Seção 5)
- lib/ui/components/smart_button.dart

════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/components/smart_button.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

void main() {
  group('SmartButton - Map-First Contract', () {
    // ═══════════════════════════════════════════════════════════════
    // CENÁRIO 1: NO /map — FAB ABRE SIDEMENU
    // ═══════════════════════════════════════════════════════════════
    testWidgets('DADO que estou na rota /map '
        'QUANDO o SmartButton é renderizado '
        'ENTÃO deve exibir ícone de menu (☰) '
        'E ao clicar deve abrir o SideMenu '
        'E NÃO deve executar navegação', (WidgetTester tester) async {
      // ARRANGE: Criar router mockado com rota /map
      final router = GoRouter(
        initialLocation: AppRoutes.map,
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) => Scaffold(
              endDrawer: const Drawer(child: Text('SideMenu')),
              body: const SmartButton(),
            ),
          ),
        ],
      );

      // ACT: Renderizar SmartButton
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      // ASSERT 1: FAB está visível
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // ASSERT 2: Ícone é menu (☰ = Icons.menu)
      final fabFinder = find.byType(FloatingActionButton);
      final fab = tester.widget<FloatingActionButton>(fabFinder);
      final icon = (fab.child as Icon);
      expect(icon.icon, equals(Icons.menu));

      // ASSERT 3: Ao clicar, abre drawer (não navega)
      final initialLocation =
          router.routerDelegate.currentConfiguration.uri.path;
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Drawer deve estar aberto
      expect(find.text('SideMenu'), findsOneWidget);

      // Rota NÃO deve ter mudado
      final currentLocation =
          router.routerDelegate.currentConfiguration.uri.path;
      expect(currentLocation, equals(initialLocation));
      expect(currentLocation, equals(AppRoutes.map));
    });

    // ═══════════════════════════════════════════════════════════════
    // CENÁRIO 2: FORA DO /map — FAB RETORNA AO MAPA
    // ═══════════════════════════════════════════════════════════════
    testWidgets('DADO que estou em qualquer rota fora de /map '
        'QUANDO o SmartButton é renderizado '
        'ENTÃO deve exibir ícone de voltar (←) '
        'E ao clicar deve executar context.go(/map) '
        'E NÃO deve usar pop() ou canPop()', (WidgetTester tester) async {
      // ARRANGE: Criar router com múltiplas rotas
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Mapa'))),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SmartButton()),
          ),
          GoRoute(
            path: '/consultoria/relatorios',
            builder: (context, state) => const Scaffold(body: SmartButton()),
          ),
        ],
      );

      // ACT: Renderizar SmartButton em /settings
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      // ASSERT 1: FAB está visível
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // ASSERT 2: Ícone é voltar (← = Icons.arrow_back)
      final fabFinder = find.byType(FloatingActionButton);
      final fab = tester.widget<FloatingActionButton>(fabFinder);
      final icon = (fab.child as Icon);
      expect(icon.icon, equals(Icons.arrow_back));

      // ASSERT 3: Rota inicial é /settings
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals('/settings'),
      );

      // ACT: Clicar no FAB
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // ASSERT 4: Rota mudou para /map (navegação declarativa)
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        equals(AppRoutes.map),
      );

      // ASSERT 5: Estamos agora no mapa
      expect(find.text('Mapa'), findsOneWidget);
    });

    // ═══════════════════════════════════════════════════════════════
    // CENÁRIO 3: MÚLTIPLAS ROTAS FORA DO MAPA
    // ═══════════════════════════════════════════════════════════════
    testWidgets('DADO que navego por múltiplas rotas fora do /map '
        'QUANDO clico no SmartButton '
        'ENTÃO sempre retorna ao /map independente do caminho', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: AppRoutes.map,
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Mapa'))),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(body: SmartButton()),
          ),
          GoRoute(
            path: '/consultoria/relatorios',
            builder: (context, state) => const Scaffold(body: SmartButton()),
          ),
          GoRoute(
            path: '/agenda',
            builder: (context, state) => const Scaffold(body: SmartButton()),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      // Testar múltiplas rotas
      final testRoutes = ['/settings', '/consultoria/relatorios', '/agenda'];

      for (final route in testRoutes) {
        // Navegar para rota
        router.go(route);
        await tester.pumpAndSettle();

        // Verificar que estamos na rota
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals(route),
        );

        // Clicar no FAB
        final fabFinder = find.byType(FloatingActionButton);
        await tester.tap(fabFinder);
        await tester.pumpAndSettle();

        // Verificar retorno ao mapa
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          equals(AppRoutes.map),
          reason: 'FAB em $route deve retornar ao /map',
        );
      }
    });

    // ═══════════════════════════════════════════════════════════════
    // CENÁRIO 4: VISIBILIDADE PERMANENTE
    // ═══════════════════════════════════════════════════════════════
    testWidgets('DADO qualquer rota no sistema '
        'QUANDO o SmartButton é renderizado '
        'ENTÃO deve estar SEMPRE visível', (WidgetTester tester) async {
      final routes = [
        AppRoutes.map,
        '/settings',
        '/consultoria/relatorios',
        '/agenda',
      ];

      for (final route in routes) {
        final router = GoRouter(
          initialLocation: route,
          routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (context, state) => const Scaffold(body: SmartButton()),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const Scaffold(body: SmartButton()),
            ),
            GoRoute(
              path: '/consultoria/relatorios',
              builder: (context, state) => const Scaffold(body: SmartButton()),
            ),
            GoRoute(
              path: '/agenda',
              builder: (context, state) => const Scaffold(body: SmartButton()),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(child: MaterialApp.router(routerConfig: router)),
        );
        await tester.pumpAndSettle();

        // FAB deve estar visível
        expect(
          find.byType(FloatingActionButton),
          findsOneWidget,
          reason: 'FAB deve estar visível em $route',
        );
      }
    });
  });
}
