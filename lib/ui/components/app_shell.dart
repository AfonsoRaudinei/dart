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
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/router/app_routes.dart';
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

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Link recebido com app aberto (foreground)
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    // Link recebido que abriu o app (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Supabase envia: soloforte://reset-password#access_token=...&type=recovery
    // O fragment (#) vira query params após o redirect do Supabase
    final fragment = uri.fragment;
    if (fragment.isEmpty) return;

    final params = Uri.splitQueryString(fragment);
    final type = params['type'];
    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];

    if (type == 'recovery' &&
        accessToken != null &&
        refreshToken != null) {
      // Estabelecer sessão com os tokens do link
      Supabase.instance.client.auth
          .setSession(accessToken)
          .then((_) {
        // Navegar para tela de reset após sessão estabelecida
        if (mounted) {
          context.go(AppRoutes.resetPassword);
        }
      }).catchError((e) {
        debugPrint('⚠️ [DeepLink] Erro ao estabelecer sessão: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          widget.child,

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
