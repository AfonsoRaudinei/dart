import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

class SmartButton extends ConsumerWidget {
  const SmartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Access current route URI
    final RouteMatchList matchList = GoRouter.of(
      context,
    ).routerDelegate.currentConfiguration;
    final String uri = matchList.uri.path;

    // 0. PUBLIC MAP (CTA)
    if (uri == AppRoutes.publicMap || uri == '/') {
      return Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.login),
          backgroundColor: SoloForteColors.greenIOS,
          label: const Text(
            'Acessar SoloForte',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          icon: const Icon(Icons.login, color: Colors.white),
        ),
      );
    }

    // 1. MAP (ROOT)
    // O mapa é o home real do sistema.
    // Usamos a constante global.
    final bool isMapRoot = uri == AppRoutes.dashboard;

    if (isMapRoot) {
      return Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: FloatingActionButton(
          onPressed: () {
            Scaffold.of(context).openEndDrawer();
          },
          backgroundColor: SoloForteColors.greenIOS,
          child: const Icon(Icons.menu, color: Colors.white),
        ),
      );
    }

    // 2. MÓDULOS PRINCIPAIS (LEVEL 1)
    // Regra CONTRATUAL: L1 sempre volta para o Mapa (sem exceção).
    // Não decide entre Menu ou Back. Sempre Back to Map.
    final Set<String> moduleRoots = {
      AppRoutes.clients,
      AppRoutes.reports,
      AppRoutes.settings,
      AppRoutes.agenda,
      AppRoutes.feedback,
    };

    // Strict exact match for L1
    final bool isModuleRoot = moduleRoots.contains(uri);

    if (isModuleRoot) {
      return Container(
        margin: const EdgeInsets.only(bottom: 40, right: 20),
        child: FloatingActionButton(
          onPressed: () {
            // L1 action: Always go to Map Root
            context.go(AppRoutes.dashboard);
          },
          backgroundColor: SoloForteColors.greenIOS,
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      );
    }

    // 3. SUBMÓDULOS (LEVEL 2+)
    // Regra: Sub-telas apenas fazem pop.
    // Se não houver histórico (refresh), fallback para Mapa.
    return Container(
      margin: const EdgeInsets.only(bottom: 40, right: 20),
      child: FloatingActionButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            // Fallback para ROOT
            context.go(AppRoutes.dashboard);
          }
        },
        backgroundColor: SoloForteColors.greenIOS,
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }
}
