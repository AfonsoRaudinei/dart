import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import 'side_menu.dart';
import 'smart_button.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAuth = session is SessionAuthenticated;

    return Scaffold(
      body: child,
      // SmartButton is strict: "lado direito".
      // FAB default is endFloat (bottom-right).
      // We can adjust position if needed.
      floatingActionButton: const SmartButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // SideMenu global: disponível em todas as rotas autenticadas
      // O SmartButton controla quando o ícone ☰ aparece (apenas no dashboard)
      endDrawer: isAuth ? const SideMenu() : null,
      drawerScrimColor: Colors.black54,
      resizeToAvoidBottomInset:
          false, // Maps usually don't resize, but forms do. Shell might handle it.
    );
  }
}
