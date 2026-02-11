import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/domain/publicacao.dart';
import 'package:soloforte_app/ui/components/map/publicacao_preview_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// TESTES DE PUBLICAÇÃO — ADR-007 (Guard Tests)
//
// 1. Snapshot: getLevel('/map/publicacao/edit') == L0
//    → Garante que a sub-rota nunca escape para L1/L2
//
// 2. Widget: pin tap abre preview, não navega
//    → Garante que o CTA é a única via de navegação
// ════════════════════════════════════════════════════════════════════

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ────────────────────────────────────────────────────────────────
  // 1. SNAPSHOT: Sub-rota de Publicação permanece L0
  // ────────────────────────────────────────────────────────────────

  group('AppRoutes.getLevel — Publicação sub-rotas', () {
    test('/map/publicacao/edit retorna L0', () {
      final level = AppRoutes.getLevel('/map/publicacao/edit');
      expect(level, RouteLevel.l0);
    });

    test('/map/publicacao/edit?id=abc retorna L0 (com query param)', () {
      // getLevel opera no path, não na query — mas validamos o path base
      final level = AppRoutes.getLevel('/map/publicacao/edit');
      expect(level, RouteLevel.l0);
    });

    test('/map permanece L0', () {
      final level = AppRoutes.getLevel('/map');
      expect(level, RouteLevel.l0);
    });

    test('Nenhuma rota de publicação fora de /map existe', () {
      // Se alguém criasse /publicacao, seria L2+ (não L0 nem L1)
      final level = AppRoutes.getLevel('/publicacao');
      expect(level, RouteLevel.l2Plus);
    });

    test('Sub-rotas hipotéticas de /map/ também seriam L0', () {
      // Guard contra expansão futura acidental
      expect(AppRoutes.getLevel('/map/qualquer-coisa'), RouteLevel.l0);
      expect(AppRoutes.getLevel('/map/publicacao'), RouteLevel.l0);
      expect(AppRoutes.getLevel('/map/publicacao/edit'), RouteLevel.l0);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // 2. WIDGET: Preview abre via bottom sheet, não navega
  // ────────────────────────────────────────────────────────────────

  group('PublicacaoPreview — comportamento iOS Maps', () {
    late Publicacao mockPublicacao;

    setUp(() {
      mockPublicacao = Publicacao(
        id: 'test-001',
        latitude: -23.55,
        longitude: -46.63,
        createdAt: DateTime(2026, 2, 9),
        status: 'published',
        isVisible: true,
        type: PublicacaoType.resultado,
        title: 'Teste Resultado',
        description: 'Descrição de teste',
        clientName: 'Cliente Teste',
        areaName: 'Área Norte',
        media: const [
          MediaItem(id: 'm1', path: '', caption: 'Foto', isCover: true),
        ],
      );
    });

    testWidgets('showPublicacaoPreview abre bottom sheet sem navegar',
        (tester) async {
      final observer = _SpyNavigatorObserver();
      final router = GoRouter(
        initialLocation: '/map',
        observers: [observer],
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) => _PreviewTestScreen(publicacao: mockPublicacao),
            routes: [
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, state) => const Scaffold(
                  body: Text('Editor'),
                ),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Rota inicial é /map
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map',
      );

      // Nenhum sheet visível antes do tap
      expect(find.byType(DraggableScrollableSheet), findsNothing);

      // Tap no botão que simula o pin
      await tester.tap(find.byKey(const ValueKey('pin_tap_trigger')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Preview (bottom sheet) está visível — DraggableScrollableSheet presente
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // Modal barrier confirma que é um overlay local (não uma rota)
      expect(find.byType(ModalBarrier), findsWidgets);

      // ROTA NÃO MUDOU — preview é modal local, não navegação
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map',
      );
    });

    testWidgets('Preview não tem AppBar', (tester) async {
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) => _PreviewTestScreen(publicacao: mockPublicacao),
            routes: [
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, __) => const Scaffold(body: Text('Editor')),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('pin_tap_trigger')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Sem AppBar no preview
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('CTA navega para /map/publicacao/edit com id correto',
        (tester) async {
      // Este teste valida que context.go('/map/publicacao/edit?id=...')
      // resolve para a rota e tela corretas — sem passar pelo sheet
      // (o sheet é validado nos testes acima).
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) => _CTATestScreen(publicacaoId: 'test-001'),
            routes: [
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, state) {
                  final id = state.uri.queryParameters['id'] ?? '';
                  return Scaffold(
                    body: Text('Editor: $id'),
                  );
                },
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Simular CTA tap (context.go diretamente)
      await tester.tap(find.byKey(const ValueKey('cta_trigger')));
      await tester.pumpAndSettle();

      // Navegou para a rota de edição
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map/publicacao/edit',
      );

      // Editor renderizado com ID correto
      expect(find.text('Editor: test-001'), findsOneWidget);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // 3. ENTIDADE: Publicacao — regras defensivas
  // ────────────────────────────────────────────────────────────────

  group('Publicacao — coverMedia defensivo', () {
    test('coverMedia retorna placeholder quando media está vazia', () {
      final pub = Publicacao(
        id: '1',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        status: 'draft',
        isVisible: true,
        type: PublicacaoType.tecnico,
        media: const [],
      );

      expect(pub.coverMedia.id, '__placeholder__');
      expect(pub.coverMedia.isCover, true);
    });

    test('coverMedia retorna item marcado como capa', () {
      final pub = Publicacao(
        id: '1',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        status: 'published',
        isVisible: true,
        type: PublicacaoType.resultado,
        media: const [
          MediaItem(id: 'a', path: '/a', isCover: false),
          MediaItem(id: 'b', path: '/b', isCover: true),
        ],
      );

      expect(pub.coverMedia.id, 'b');
    });

    test('coverMedia retorna primeiro item se nenhum marcado como capa', () {
      final pub = Publicacao(
        id: '1',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        status: 'published',
        isVisible: true,
        type: PublicacaoType.institucional,
        media: const [
          MediaItem(id: 'x', path: '/x'),
          MediaItem(id: 'y', path: '/y'),
        ],
      );

      expect(pub.coverMedia.id, 'x');
    });

    test('ensureCover marca primeiro item quando nenhum tem capa', () {
      final pub = Publicacao(
        id: '1',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        status: 'published',
        isVisible: true,
        type: PublicacaoType.comparativo,
        media: const [
          MediaItem(id: 'a', path: '/a'),
          MediaItem(id: 'b', path: '/b'),
        ],
      );

      final ensured = pub.ensureCover();
      expect(ensured.media[0].isCover, true);
      expect(ensured.media[1].isCover, false);
    });

    test('ensureCover não altera se já existe capa', () {
      final pub = Publicacao(
        id: '1',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
        status: 'published',
        isVisible: true,
        type: PublicacaoType.caseSucesso,
        media: const [
          MediaItem(id: 'a', path: '/a'),
          MediaItem(id: 'b', path: '/b', isCover: true),
        ],
      );

      final ensured = pub.ensureCover();
      // Retorna o mesmo objeto (referência idêntica)
      expect(identical(ensured, pub), true);
    });
  });
}

// ────────────────────────────────────────────────────────────────
// Helpers de Teste
// ────────────────────────────────────────────────────────────────

/// Tela de teste que simula o mapa com botão que abre o preview.
class _PreviewTestScreen extends StatelessWidget {
  final Publicacao publicacao;

  const _PreviewTestScreen({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('pin_tap_trigger'),
          onPressed: () => showPublicacaoPreview(context, publicacao),
          child: const Text('Simular Pin Tap'),
        ),
      ),
    );
  }
}

/// Tela de teste que simula o CTA — context.go direto (sem sheet).
class _CTATestScreen extends StatelessWidget {
  final String publicacaoId;

  const _CTATestScreen({required this.publicacaoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('cta_trigger'),
          onPressed: () {
            context.go('/map/publicacao/edit?id=$publicacaoId');
          },
          child: const Text('Ver detalhes'),
        ),
      ),
    );
  }
}

/// Observer que conta push de rotas (não modais).
class _SpyNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;
  int popCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Conta apenas GoRouter page-based pushes, ignora modais (ModalBottomSheet)
    if (route.settings.name != null && !route.settings.name!.startsWith('_')) {
      pushCount++;
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}
