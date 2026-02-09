/*
════════════════════════════════════════════════════════════════════
SMART BUTTON — CONTRATO MAP-FIRST (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Este botão é um CONTROLE SISTÊMICO ÚNICO, não um botão de tela.

REGRA CANÔNICA (TRAVA DETERMINÍSTICA):
- O Mapa (/map) é o centro absoluto do aplicativo.
- O comportamento é 100% determinístico e baseado APENAS na rota atual.
- Classificação via AppRoutes.getLevel() — SEM heurísticas.
- Navegação SEMPRE declarativa via context.go() — SEM pop()/canPop().

COMPORTAMENTO OFICIAL:
┌─────────┬───────────────────────┬─────────┬───────────────────────────────┐
│ Nível   │ Rota                  │ Ícone   │ Ação                          │
├─────────┼───────────────────────┼─────────┼───────────────────────────────┤
│ L0      │ /map                  │ ☰       │ Abrir SideMenu                │
│ L1/L2+  │ Qualquer outra        │ ←       │ go('/map')                    │
│ PUBLIC  │ /public-map, /login   │ CTA     │ "Acessar SoloForte"           │
└─────────┴───────────────────────┴─────────┴───────────────────────────────┘

PROIBIÇÕES ABSOLUTAS:
❌ Navigator.pop() ou context.pop()
❌ Navigator.canPop() ou context.canPop()
❌ Lógica baseada em stack de navegação
❌ Múltiplos FABs no sistema
❌ Esconder o FAB em qualquer fluxo
❌ Transformar FAB em botão contextual (salvar, cancelar, etc.)

PRINCÍPIO DE OURO:
"No mapa, o FAB governa o sistema."
"Fora do mapa, o FAB retorna ao mapa."
Nada além disso.

⚠️ Qualquer alteração exige revisão arquitetural formal.
Ver: docs/arquitetura-navegacao.md (Seção 5)
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
        // L0: MAPA — ☰ Abre SideMenu
        // Único FAB que não navega
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
      case RouteLevel.l2Plus:
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // L1/L2+: FORA DO MAPA — ← Retorna ao mapa via go()
        // CONTRATO MAP-FIRST: Navegação declarativa obrigatória
        // ❌ SEM pop() — ❌ SEM canPop() — ❌ SEM stack
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        return _buildFAB(
          context,
          child: FloatingActionButton(
            heroTag: 'smart_button_back',
            onPressed: () {
              // Retorno EXPLÍCITO e DECLARATIVO para o mapa
              // Funciona sempre: deep link, hot restart, app kill, etc.
              context.go(AppRoutes.map);
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
