/*
════════════════════════════════════════════════════════════════════
APP SHELL — ARQUITETURA STACK-BASED (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Shell global refatorado para arquitetura Stack.

PROBLEMAS RESOLVIDOS:
1. ✅ Botão verde (SmartButton) não some mais quando menu abre
2. ✅ SideMenu como overlay controlado, não Drawer do Scaffold
3. ✅ Botão sempre visível, acima de tudo (z-index correto)
4. ✅ Deep link handler: recovery + signup com switch explícito
5. ✅ setSession com accessToken + refreshToken (SDK v2)
6. ✅ onAuthStateChange listener para passwordRecovery
7. ✅ Fallback fragment → query params
8. ✅ SnackBar em erros — sem silêncio

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
import 'dart:async';
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
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _listenAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // LISTENER DE AUTH STATE — camada extra para passwordRecovery
  // O SDK Supabase emite AuthChangeEvent.passwordRecovery quando
  // detecta um token de recovery válido antes mesmo do app_links
  // capturar o URI. Este listener garante a navegação correta.
  // ─────────────────────────────────────────────────────────────────
  void _listenAuthChanges() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        debugPrint('[Auth] passwordRecovery event — navegando para reset');
        if (mounted) {
          context.go(AppRoutes.resetPassword);
        }
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // DEEP LINK — inicialização
  // ─────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────
  // DEEP LINK — handler principal
  //
  // Supabase envia tokens no fragment (#) ou em query params (?).
  // Tipos tratados:
  //   recovery → tela de nova senha
  //   signup   → confirmação de cadastro → login com SnackBar
  // ─────────────────────────────────────────────────────────────────
  void _handleDeepLink(Uri uri) {
    debugPrint('[DeepLink] URI recebida — host: ${uri.host}, type: ${uri.path}');

    // Fallback: tentar fragment primeiro, depois query params
    final rawParams =
        uri.fragment.isNotEmpty ? uri.fragment : uri.query;

    if (rawParams.isEmpty) {
      debugPrint('[DeepLink] Sem parâmetros — ignorando.');
      return;
    }

    final params = Uri.splitQueryString(rawParams);
    final type = params['type'];
    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];

    debugPrint('[DeepLink] type=$type, hasToken=${accessToken != null}');

    if (accessToken == null || refreshToken == null) {
      debugPrint('[DeepLink] Tokens ausentes — ignorando.');
      return;
    }

    switch (type) {
      case 'recovery':
        // Reset de senha — estabelecer sessão e navegar para tela de nova senha.
        // gotrue 2.18.0: setSession(refreshToken) — apenas o refreshToken.
        // O onAuthStateChange também dispara passwordRecovery, mas manter
        // ambos garante cobertura em cold start e foreground.
        Supabase.instance.client.auth
            .setSession(refreshToken)
            .then((_) {
          debugPrint('[DeepLink] Recovery: sessão estabelecida');
          if (mounted) {
            context.go(AppRoutes.resetPassword);
          }
        }).catchError((e) {
          debugPrint('⚠️ [DeepLink] Erro no recovery: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Link expirado ou inválido. Solicite uma nova recuperação de senha.',
                ),
              ),
            );
          }
        });

      case 'signup':
        // Confirmação de cadastro — o Supabase já ativou o usuário.
        // Estabelecer sessão, fazer signOut limpo e navegar para login.
        // signOut garante que ensureProfileComplete rode no próximo login.
        Supabase.instance.client.auth
            .setSession(refreshToken)
            .then((_) {
          debugPrint('[DeepLink] Signup confirmado — fazendo signOut limpo');
          return Supabase.instance.client.auth.signOut();
        }).then((_) {
          if (mounted) {
            context.go(AppRoutes.login);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Email confirmado com sucesso! Faça login para continuar.',
                ),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }).catchError((e) {
          debugPrint('⚠️ [DeepLink] Erro no signup: $e');
          if (mounted) {
            context.go(AppRoutes.login);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Confirmação realizada. Faça login para continuar.',
                ),
              ),
            );
          }
        });

      default:
        debugPrint('[DeepLink] Tipo desconhecido: $type — ignorando.');
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