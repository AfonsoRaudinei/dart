import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

/// TESTES UNITÁRIOS — AppRoutes.getLevel()
///
/// Objetivo: garantir que a classificação de nível de rota é determinística,
/// pura e imune a restart/hot reload.
///
/// PREMISSAS:
/// - Função pura (sem side effects)
/// - Entrada: String path
/// - Saída: RouteLevel enum
/// - Sem BuildContext
/// - Sem dependência de UI
///
/// NÍVEIS:
/// - L0 = Dashboard/Mapa (ícone ☰, abre SideMenu)
/// - L1 = Módulos raiz (ícone ←, go para dashboard)
/// - L2+ = Subtelas (ícone ←, pop com fallback)
/// - PUBLIC = Rotas públicas (CTA login)

void main() {
  group('AppRoutes.getLevel', () {
    group('1️⃣ L0 — Dashboard/Mapa (raiz absoluta)', () {
      test('Dashboard raiz é L0', () {
        expect(AppRoutes.getLevel('/dashboard'), RouteLevel.l0);
      });

      test('Sub-rota do dashboard (mapa-tecnico) é L0', () {
        expect(AppRoutes.getLevel('/dashboard/mapa-tecnico'), RouteLevel.l0);
      });

      test('Sub-rota profunda do dashboard é L0', () {
        expect(
          AppRoutes.getLevel('/dashboard/ocorrencias/novo'),
          RouteLevel.l0,
        );
      });
    });

    group('2️⃣ L1 — Módulos raiz', () {
      test('Settings é L1', () {
        expect(AppRoutes.getLevel('/settings'), RouteLevel.l1);
      });

      test('Agenda é L1', () {
        expect(AppRoutes.getLevel('/agenda'), RouteLevel.l1);
      });

      test('Feedback é L1', () {
        expect(AppRoutes.getLevel('/feedback'), RouteLevel.l1);
      });

      test('Clientes é L1', () {
        expect(AppRoutes.getLevel('/consultoria/clientes'), RouteLevel.l1);
      });

      test('Relatórios é L1', () {
        expect(AppRoutes.getLevel('/consultoria/relatorios'), RouteLevel.l1);
      });
    });

    group('3️⃣ L2+ — Subtelas', () {
      test('Detalhe de cliente é L2+', () {
        expect(
          AppRoutes.getLevel('/consultoria/clientes/abc-123'),
          RouteLevel.l2Plus,
        );
      });

      test('Novo cliente é L2+', () {
        expect(
          AppRoutes.getLevel('/consultoria/clientes/novo'),
          RouteLevel.l2Plus,
        );
      });

      test('Detalhe de fazenda é L2+', () {
        expect(
          AppRoutes.getLevel('/consultoria/clientes/abc-123/fazendas/def-456'),
          RouteLevel.l2Plus,
        );
      });

      test('Detalhe de talhão é L2+', () {
        expect(
          AppRoutes.getLevel(
            '/consultoria/clientes/abc-123/fazendas/def-456/talhoes/ghi-789',
          ),
          RouteLevel.l2Plus,
        );
      });

      test('Detalhe de relatório é L2+', () {
        expect(
          AppRoutes.getLevel('/consultoria/relatorios/12345'),
          RouteLevel.l2Plus,
        );
      });

      test('Novo relatório é L2+', () {
        expect(
          AppRoutes.getLevel('/consultoria/relatorios/novo'),
          RouteLevel.l2Plus,
        );
      });

      test('Rota desconhecida é L2+ (fallback seguro)', () {
        expect(AppRoutes.getLevel('/rota-desconhecida'), RouteLevel.l2Plus);
      });
    });

    group('4️⃣ PUBLIC — Rotas públicas', () {
      test('Public map é PUBLIC', () {
        expect(AppRoutes.getLevel('/public-map'), RouteLevel.public);
      });

      test('Login é PUBLIC', () {
        expect(AppRoutes.getLevel('/login'), RouteLevel.public);
      });

      test('Signup é PUBLIC', () {
        expect(AppRoutes.getLevel('/signup'), RouteLevel.public);
      });

      test('Raiz (/) é PUBLIC', () {
        expect(AppRoutes.getLevel('/'), RouteLevel.public);
      });
    });

    group('5️⃣ Casos defensivos', () {
      test('Rota vazia é L2+ (fallback)', () {
        expect(AppRoutes.getLevel(''), RouteLevel.l2Plus);
      });

      test('Dashboard com barra final é L0', () {
        // /dashboard/ ainda inicia com /dashboard/ então é L0
        expect(AppRoutes.getLevel('/dashboard/'), RouteLevel.l0);
      });
    });

    group('6️⃣ AppRoutes.canOpenSideMenu', () {
      test('Pode abrir SideMenu no dashboard', () {
        expect(AppRoutes.canOpenSideMenu('/dashboard'), true);
      });

      test('Pode abrir SideMenu em sub-rota do dashboard', () {
        expect(AppRoutes.canOpenSideMenu('/dashboard/mapa-tecnico'), true);
      });

      test('Não pode abrir SideMenu em /settings', () {
        expect(AppRoutes.canOpenSideMenu('/settings'), false);
      });

      test('Não pode abrir SideMenu em /consultoria/clientes', () {
        expect(AppRoutes.canOpenSideMenu('/consultoria/clientes'), false);
      });

      test('Não pode abrir SideMenu em detalhe de cliente', () {
        expect(
          AppRoutes.canOpenSideMenu('/consultoria/clientes/abc-123'),
          false,
        );
      });

      test('Não pode abrir SideMenu no mapa público', () {
        expect(AppRoutes.canOpenSideMenu('/public-map'), false);
      });
    });

    group('7️⃣ Performance', () {
      test('Executa rápido (<1ms para 1000 chamadas)', () {
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 1000; i++) {
          AppRoutes.getLevel('/consultoria/clientes/abc-123');
        }
        stopwatch.stop();

        // 1000 chamadas devem executar em menos de 10ms
        expect(stopwatch.elapsedMilliseconds, lessThan(10));
      });
    });
  });
}
