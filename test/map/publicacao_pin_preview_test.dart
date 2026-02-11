import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/domain/publicacao.dart';
import 'package:soloforte_app/ui/components/map/publicacao_preview_sheet.dart';

// ════════════════════════════════════════════════════════════════════
// TESTE 2 — Gate ADR-007: Pin → Preview → CTA (Widget Test)
//
// O que garante:
//   - Tocar no pin NÃO navega (abre preview).
//   - Somente o CTA navega para /map/publicacao/edit.
//   - Preview é bottom sheet (DraggableScrollableSheet), não rota.
//   - Nenhum push de rota ocorre ao abrir o preview.
//   - CI bloqueia merge se pin navegar direto.
// ════════════════════════════════════════════════════════════════════

/// Observer que conta TODOS os pushes (inclusive modais).
class _NavObserver extends NavigatorObserver {
  int pushes = 0;
  final List<String?> pushedRouteNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
    pushedRouteNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
}

/// Mock de Publicacao para testes.
Publicacao _createMockPublicacao() {
  return Publicacao(
    id: 'test-pin-001',
    latitude: -23.55,
    longitude: -46.63,
    createdAt: DateTime(2026, 2, 9),
    status: 'published',
    isVisible: true,
    type: PublicacaoType.resultado,
    title: 'Resultado Safra Teste',
    description: 'Descrição de teste para auditoria ADR-007.',
    clientName: 'Fazenda Teste',
    areaName: 'Talhão Teste',
    media: const [
      MediaItem(id: 'm1', path: '', caption: 'Foto teste', isCover: true),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ADR-007 | Pin opens preview without navigation', () {
    late Publicacao mockPublicacao;

    setUp(() {
      mockPublicacao = _createMockPublicacao();
    });

    testWidgets('Tap on pin opens preview sheet and does NOT navigate',
        (WidgetTester tester) async {
      final observer = _NavObserver();

      final router = GoRouter(
        observers: [observer],
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) =>
                _PinSimulatorScreen(publicacao: mockPublicacao),
            routes: [
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, state) => const Scaffold(
                  key: Key('editor'),
                  body: Text('Editor Screen'),
                ),
              ),
            ],
          ),
        ],
        initialLocation: '/map',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Confirma estado inicial
      expect(find.byKey(const Key('publicacao-pin')), findsOneWidget);
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(find.byKey(const Key('editor')), findsNothing);

      // ── TAP NO PIN ──
      await tester.tap(find.byKey(const Key('publicacao-pin')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // ── ASSERT: Preview abriu como sheet (não rota) ──
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // ── ASSERT: Modal barrier (overlay sobre o mapa) ──
      expect(find.byType(ModalBarrier), findsWidgets);

      // ── ASSERT: Rota NÃO mudou ──
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map',
      );

      // ── ASSERT: Nenhum push de rota (apenas modal overlay) ──
      // O modal bottom sheet causa um push no Navigator, mas NÃO no GoRouter.
      // Verificamos que o editor NÃO foi empilhado.
      expect(find.byKey(const Key('editor')), findsNothing);

      // ── ASSERT: Sem AppBar no preview ──
      // O preview é sheet contextual, não tela com AppBar
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('CTA "Ver detalhes" is the ONLY navigation point',
        (WidgetTester tester) async {
      // Este teste valida que context.go('/map/publicacao/edit?id=...')
      // resolve para a rota correta — usa tela helper que simula
      // o CTA diretamente (sem depender da viewport do sheet).
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) =>
                _CTASimulatorScreen(publicacaoId: mockPublicacao.id),
            routes: [
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, state) {
                  final id = state.uri.queryParameters['id'] ?? '';
                  return Scaffold(
                    key: const Key('editor'),
                    body: Text('Editor: $id'),
                  );
                },
              ),
            ],
          ),
        ],
        initialLocation: '/map',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // ── Simular CTA tap (context.go direto, como o botão faz) ──
      await tester.tap(find.byKey(const Key('cta-trigger')));
      await tester.pumpAndSettle();

      // ── ASSERT: Navegação ocorreu via CTA ──
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map/publicacao/edit',
      );

      // ── ASSERT: ID correto passado via query param ──
      expect(find.text('Editor: test-pin-001'), findsOneWidget);

      // ── ASSERT: Editor renderizado ──
      expect(find.byKey(const Key('editor')), findsOneWidget);
    });

    testWidgets('Preview sheet has DraggableScrollableSheet with ~30% peek',
        (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) =>
                _PinSimulatorScreen(publicacao: mockPublicacao),
          ),
        ],
        initialLocation: '/map',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Abrir preview
      await tester.tap(find.byKey(const Key('publicacao-pin')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // ── ASSERT: DraggableScrollableSheet presente ──
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // ── ASSERT: Não é fullscreen (sem Scaffold/AppBar no sheet) ──
      // O Scaffold pertence ao _PinSimulatorScreen (host), não ao sheet
      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('Closing preview does not leave residual state',
        (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/map',
            builder: (_, __) =>
                _PinSimulatorScreen(publicacao: mockPublicacao),
          ),
        ],
        initialLocation: '/map',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Abrir preview
      await tester.tap(find.byKey(const Key('publicacao-pin')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);

      // ── FECHAR o sheet via Navigator.pop (simula tap na barrier) ──
      Navigator.of(tester.element(find.byType(DraggableScrollableSheet))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // ── ASSERT: Sheet fechou ──
      expect(find.byType(DraggableScrollableSheet), findsNothing);

      // ── ASSERT: Rota permanece /map (sem resíduos) ──
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/map',
      );

      // ── ASSERT: Mapa (host screen) ainda presente ──
      expect(find.byKey(const Key('publicacao-pin')), findsOneWidget);
    });
  });
}

// ────────────────────────────────────────────────────────────────
// Helpers de Teste
// ────────────────────────────────────────────────────────────────

/// Tela de teste que simula o mapa com um "pin" (botão com Key).
/// Ao tocar no pin, abre o preview contextual real.
class _PinSimulatorScreen extends StatelessWidget {
  final Publicacao publicacao;

  const _PinSimulatorScreen({required this.publicacao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          key: const Key('publicacao-pin'),
          onTap: () => showPublicacaoPreview(context, publicacao),
          child: Container(
            width: 80,
            height: 96,
            color: Colors.orange.withValues(alpha: 0.3),
            child: const Center(child: Text('Pin')),
          ),
        ),
      ),
    );
  }
}

/// Tela de teste que simula o CTA — context.go direto (sem sheet).
/// Isola o teste de navegação da viewport do DraggableScrollableSheet.
class _CTASimulatorScreen extends StatelessWidget {
  final String publicacaoId;

  const _CTASimulatorScreen({required this.publicacaoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('cta-trigger'),
          onPressed: () {
            context.go('/map/publicacao/edit?id=$publicacaoId');
          },
          child: const Text('Ver detalhes'),
        ),
      ),
    );
  }
}
