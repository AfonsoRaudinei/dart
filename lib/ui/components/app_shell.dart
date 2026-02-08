/*
════════════════════════════════════════════════════════════════════
APP SHELL — CONTRATO DE NAVEGAÇÃO (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Este widget é o SHELL GLOBAL do aplicativo, responsável por:
1. Exibir o SmartButton (FAB global) — SEMPRE visível em rotas autenticadas
2. Gerenciar o SideMenu (drawer) — SOMENTE disponível no Dashboard/Mapa

REGRAS:
- SmartButton: Sempre presente (ele decide seu próprio ícone/ação)
- SideMenu (endDrawer): APENAS quando AppRoutes.canOpenSideMenu() = true
- drawerEnableOpenDragGesture: DESABILITADO fora do mapa (evitar swipe acidental)

⚠️ Qualquer alteração neste comportamento exige revisão arquitetural.
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import '../../core/router/app_routes.dart';
import 'side_menu.dart';
import 'smart_button.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ═══════════════════════════════════════════════════════════════
    // 1. VERIFICAR AUTENTICAÇÃO
    // ═══════════════════════════════════════════════════════════════
    final session = ref.watch(sessionControllerProvider);
    final isAuth = session is SessionAuthenticated;

    // ═══════════════════════════════════════════════════════════════
    // 2. OBTER ROTA ATUAL PARA DECIDIR SOBRE SIDEMENU
    // ═══════════════════════════════════════════════════════════════
    final String currentPath = GoRouterState.of(context).uri.path;

    // SideMenu SOMENTE no Dashboard (L0)
    // Usar método determinístico de AppRoutes
    final bool canOpenMenu = isAuth && AppRoutes.canOpenSideMenu(currentPath);

    // ═══════════════════════════════════════════════════════════════
    // 3. SCAFFOLD COM REGRAS ESTRITAS
    // ═══════════════════════════════════════════════════════════════
    return Scaffold(
      body: child,

      // SmartButton SEMPRE visível (ele decide seu próprio comportamento)
      floatingActionButton: const SmartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // SideMenu SOMENTE disponível no L0 (Dashboard/Mapa)
      // null em qualquer outra rota = impossível abrir mesmo programaticamente
      endDrawer: canOpenMenu ? const SideMenu() : null,

      // Desabilitar swipe para abrir drawer fora do mapa
      // Isso evita abertura acidental em outras telas
      endDrawerEnableOpenDragGesture: canOpenMenu,

      // Cor do overlay quando drawer está aberto
      drawerScrimColor: Colors.black54,

      // Mapas não redimensionam com teclado (mas forms sim)
      // Shell mantém false; telas individuais podem sobrescrever
      resizeToAvoidBottomInset: false,
    );
  }
}
