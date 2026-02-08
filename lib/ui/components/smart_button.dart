/*
════════════════════════════════════════════════════════════════════
SMART BUTTON — CONTRATO DE NAVEGAÇÃO (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Este botão é um CONTROLE SISTÊMICO, não um botão de tela.

REGRA CANÔNICA (TRAVA DETERMINÍSTICA):
- O Dashboard (/dashboard) é o centro absoluto do aplicativo.
- O comportamento é 100% determinístico e baseado APENAS na rota atual.
- Classificação via AppRoutes.getLevel() — SEM heurísticas frágeis.

NÍVEIS DE NAVEGAÇÃO:
┌─────────┬───────────────────────┬─────────┬───────────────────────────────┐
│ Nível   │ Rota                  │ Ícone   │ Ação                          │
├─────────┼───────────────────────┼─────────┼───────────────────────────────┤
│ L0      │ /dashboard            │ ☰       │ Abrir SideMenu                │
│ L1      │ /settings, /clients   │ ←       │ go('/dashboard')              │
│ L2+     │ /clients/:id/...      │ ←       │ pop() ou go('/dashboard')     │
│ PUBLIC  │ /public-map, /login   │ CTA     │ "Acessar SoloForte"           │
└─────────┴───────────────────────┴─────────┴───────────────────────────────┘

PROIBIÇÕES ABSOLUTAS:
❌ Lógica baseada em Navigator.canPop() para decidir ícone
❌ Depender de stack ou histórico implícito
❌ Comparar URI com contains() como regra principal
❌ Exceções por módulo sem estar no Set explícito

⚠️ Qualquer alteração neste comportamento exige revisão arquitetural.
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

class SmartButton extends ConsumerWidget {
  const SmartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ═══════════════════════════════════════════════════════════════
    // 1. OBTER ROTA ATUAL
    // ═══════════════════════════════════════════════════════════════
    final RouteMatchList matchList = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration;
    final String uri = matchList.uri.path;

    // ═══════════════════════════════════════════════════════════════
    // 2. CLASSIFICAR NÍVEL (DETERMINÍSTICO via AppRoutes)
    // ═══════════════════════════════════════════════════════════════
    final RouteLevel level = AppRoutes.getLevel(uri);

    // ═══════════════════════════════════════════════════════════════
    // 3. RENDERIZAR BASEADO NO NÍVEL
    // ═══════════════════════════════════════════════════════════════
    switch (level) {
      case RouteLevel.public:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // PÚBLICO: CTA "Acessar SoloForte"
        // Mapa público não tem SmartButton de navegação
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return _buildFAB(
          context,
          child: FloatingActionButton.extended(
            heroTag: 'smart_button_cta',
            onPressed: () => context.go(AppRoutes.login),
            backgroundColor: SoloForteColors.greenIOS,
            label: const Text(
              'Acessar SoloForte',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: const Icon(Icons.login, color: Colors.white),
          ),
        );

      case RouteLevel.l0:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L0: DASHBOARD/MAPA — ☰ Abre SideMenu
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return _buildFAB(
          context,
          child: FloatingActionButton(
            heroTag: 'smart_button_menu',
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            backgroundColor: SoloForteColors.greenIOS,
            child: const Icon(Icons.menu, color: Colors.white),
          ),
        );

      case RouteLevel.l1:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L1: MÓDULOS RAIZ — ← Volta para o mapa via go()
        // NÃO usa pop() — navegação declarativa direta
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return _buildFAB(
          context,
          child: FloatingActionButton(
            heroTag: 'smart_button_back_l1',
            onPressed: () {
              context.go(AppRoutes.dashboard);
            },
            backgroundColor: SoloForteColors.greenIOS,
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        );

      case RouteLevel.l2Plus:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L2+: SUBTELAS — ← Volta um nível via pop()
        // Se stack vazia, fallback para go('/dashboard')
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return _buildFAB(
          context,
          child: FloatingActionButton(
            heroTag: 'smart_button_back_l2',
            onPressed: () {
              // Tenta pop; se não puder, vai para dashboard
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.dashboard);
              }
            },
            backgroundColor: SoloForteColors.greenIOS,
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        );
    }
  }

  /// Builder helper para posicionamento consistente do FAB.
  ///
  /// Garante:
  /// - SafeArea respeitada
  /// - Posição fixa no canto inferior direito
  /// - Z-order correto (não coberto por sheets)
  Widget _buildFAB(BuildContext context, {required Widget child}) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: child,
      ),
    );
  }
}
