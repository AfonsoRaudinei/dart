/*
════════════════════════════════════════════════════════════════════
APP SHELL — ARQUITETURA STACK-BASED (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Shell global refatorado para arquitetura Stack.

PROBLEMAS RESOLVIDOS:
1. ✅ Botão verde (SmartButton) não some mais quando menu abre
2. ✅ SideMenu como overlay controlado, não Drawer do Scaffold
3. ✅ Botão sempre visível, acima de tudo (z-index correto)

HIERARQUIA (z-index do Stack):
 ├── child (conteúdo da tela)
 ├── SideMenuOverlay (overlay do menu)
 └── SmartButton (sempre no topo)

REGRAS:
- SmartButton: Sempre visível, nunca coberto
- SideMenu: Overlay controlado via provider, não Drawer
- Sem dependência de Scaffold endDrawer
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import 'side_menu_overlay.dart';
import 'smart_button.dart';

/// Wrapper que força rebuild do SmartButton a cada mudança de rota.
/// GoRouterState.of(context) registra dependência no InheritedWidget
/// do GoRouter, causando rebuild automático quando a rota muda.
class _SmartButtonWrapper extends StatelessWidget {
  const _SmartButtonWrapper();

  @override
  Widget build(BuildContext context) {
    // Ler a rota aqui registra a dependência no InheritedWidget do GoRouter.
    // Quando a rota muda, este widget é reconstruído, e consequentemente
    // o SmartButton filho também, recebendo a rota atualizada.
    final uri = GoRouterState.of(context).uri.path;
    return SmartButton(key: ValueKey(uri));
  }
}

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
    // 2. SCAFFOLD SIMPLES (SEM DRAWER)
    // ═══════════════════════════════════════════════════════════════
    return Scaffold(
      body: Stack(
        children: [
          // Camada 1: Conteúdo da tela (child)
          child,

          // Camada 2: SideMenu Overlay (apenas se autenticado)
          // Backdrop do menu NÃO bloqueia botão (z-index inferior)
          if (isAuth) const SideMenuOverlay(),

          // Camada 3: SmartButton (sempre no topo)
          // Z-index máximo garante:
          // - Visível com menu aberto
          // - Clicável com menu aberto
          // - Não bloqueado por backdrop
          // NÃO usar const — precisa rebuild a cada mudança de rota
          // bottom: MediaQuery.padding.bottom + 16 respeita SafeArea
          // dinâmica de cada dispositivo (iPhone gesture bar = 34px,
          // Android sem barra = 0px), garantindo posição correta em todos.
          if (isAuth)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              right: 16,
              child: const _SmartButtonWrapper(),
            ),
        ],
      ),

      // Mapas não redimensionam com teclado (mas forms sim)
      resizeToAvoidBottomInset: false,
    );
  }
}
