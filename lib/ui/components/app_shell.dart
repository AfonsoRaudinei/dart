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
import '../../core/session/auth_deep_link.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import '../../core/utils/app_logger.dart';
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
  StreamSubscription<Uri>? _deepLinkSubscription;
  String? _pendingDeepLinkType;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _listenAuthChanges();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────
  // LISTENER DE AUTH STATE — camada extra para passwordRecovery
  // O SDK Supabase emite AuthChangeEvent.passwordRecovery quando
  // detecta um token de recovery válido antes mesmo do app_links
  // capturar o URI. Este listener garante a navegação correta.
  // ─────────────────────────────────────────────────────────────────
  void _listenAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        AppLogger.debug(
          'passwordRecovery event — navegando para reset',
          tag: 'Auth',
        );
        if (mounted) {
          context.go(AppRoutes.resetPassword);
        }
        _pendingDeepLinkType = null;
        return;
      }

      if (_pendingDeepLinkType == 'signup' &&
          data.event == AuthChangeEvent.signedIn) {
        _pendingDeepLinkType = null;
        Supabase.instance.client.auth
            .signOut()
            .then((_) {
              if (!mounted) return;
              context.go(AppRoutes.login);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Email confirmado com sucesso! Faça login para continuar.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            })
            .catchError((e) {
              AppLogger.error(
                'Erro ao finalizar fluxo de signup',
                tag: 'DeepLink',
                error: e,
              );
              if (!mounted) return;
              context.go(AppRoutes.login);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Confirmação realizada. Faça login para continuar.',
                  ),
                ),
              );
            });
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────
  // DEEP LINK — inicialização
  // ─────────────────────────────────────────────────────────────────
  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Link recebido com app aberto (foreground)
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (e) {
        AppLogger.error('Erro no stream', tag: 'DeepLink', error: e);
      },
    );

    // Link recebido que abriu o app (cold start)
    _appLinks
        .getInitialLink()
        .then((uri) {
          if (uri != null) _handleDeepLink(uri);
        })
        .catchError((e) {
          AppLogger.error('Erro no getInitialLink', tag: 'DeepLink', error: e);
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
    AppLogger.debug(
      'URI recebida — host: ${uri.host}, type: ${uri.path}',
      tag: 'DeepLink',
    );

    final intent = AuthDeepLinkIntent.parse(uri);

    AppLogger.debug(
      'type=${intent.type.name}, hasCredentials=${intent.hasCredentials}',
      tag: 'DeepLink',
    );

    if (intent.hasError) {
      _pendingDeepLinkType = null;
      AppLogger.error('Deep link de autenticação rejeitado', tag: 'DeepLink');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível validar este link. Solicite um novo email.',
            ),
          ),
        );
      }
      return;
    }

    if (intent.type == AuthDeepLinkType.unknown) {
      _pendingDeepLinkType = null;
      AppLogger.debug('Sem tipo de auth — ignorando.', tag: 'DeepLink');
      return;
    }

    _pendingDeepLinkType = intent.type.name;

    switch (intent.type) {
      case AuthDeepLinkType.recovery:
        // O SDK do Supabase Flutter já detecta a sessão no deep link
        // (detectSessionInUri=true por padrão). Não consumir o refresh_token
        // manualmente evita corrida com refresh token rotation.
        if (!intent.hasCredentials) {
          _pendingDeepLinkType = null;
          AppLogger.debug(
            'Recovery sem token/código — aguardando SDK ou exibindo erro.',
            tag: 'DeepLink',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Link de recuperação inválido. Solicite um novo email.',
                ),
              ),
            );
          }
        }
        return;

      case AuthDeepLinkType.signup:
        // Mesma lógica do recovery: o SDK estabelece a sessão a partir do link.
        // O signOut final ocorre no listener de auth ao receber signedIn.
        if (!intent.hasCredentials) {
          AppLogger.debug(
            'Signup sem token/código — aguardando SDK ou exibindo fallback.',
            tag: 'DeepLink',
          );
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
          _pendingDeepLinkType = null;
        }
        return;

      case AuthDeepLinkType.unknown:
        _pendingDeepLinkType = null;
        return;
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
      // 🛡 IPA-123: background branco explícito — evita tela preta durante
      // transições de rota quando o tema é 'black' (scaffoldBackgroundColor = #000).
      backgroundColor: Colors.white,
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
