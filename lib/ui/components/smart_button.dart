import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class SmartButton extends ConsumerWidget {
  const SmartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need to know the current route location
    // GoRouterState can be accessed but sometimes it's tricky inside a Shell without getting rebuilds.
    // However, we can use the router listener or just check GoRouter.of(context)

    final RouteMatchList matchList = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration;
    final String uri = matchList.uri.toString();

    // Logic:
    // /public-map -> "Acessar" (Login)
    // /map -> "Menu" (Open Drawer)
    // /settings, /relatorios, etc -> "Voltar ao mapa"

    String label = '';
    IconData? icon;
    VoidCallback? onTap;

    if (uri == '/public-map' || uri == '/') {
      label = 'Acessar';
      icon = Icons.login;
      onTap = () => context.go('/login');
    } else if (uri == '/map') {
      label = 'Menu';
      icon = Icons.menu;
      onTap = () {
        Scaffold.of(
          context,
        ).openEndDrawer(); // Right side menu implies EndDrawer usually or we position it right.
        // Prompt says "SmartButton (lado direito)". drawer is usually left, endDrawer right.
        // "SideMenu reduzido" - generic. I'll use EndDrawer for "Right side".
      };
    } else if (['/login', '/signup'].contains(uri)) {
      // Maybe hide it or show back to public?
      // Prompt: "qualquer outra rota -> 'Voltar ao mapa'"
      if (uri == '/login') {
        label = 'Voltar';
        icon = Icons.arrow_back;
        onTap = () => context.go('/public-map');
      } else {
        // Signup
        label = 'Voltar';
        icon = Icons.arrow_back;
        onTap = () => context.go('/public-map');
      }
    } else {
      // Other auth routes
      label = 'Voltar';
      icon = Icons.arrow_back;
      onTap = () => context.go('/map');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 40, right: 20),
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: SoloForteColors.greenIOS,
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}
