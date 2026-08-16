import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/router_notifier.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import 'public_map_screen.dart';

/// Porta de entrada de `/public-map`.
///
/// Durante o bootstrap de auth ([RouterNotifier.isInitializing]) com sessão
/// ainda não confirmada como visitante, mostra um hold estável — sem tiles,
/// sem pedido de localização e sem chrome — evitando o flash de “clique
/// sozinho” no reopen (BUG-010).
class PublicMapEntryScreen extends ConsumerWidget {
  const PublicMapEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(routerNotifierProvider);

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        if (notifier.isInitializing) {
          final session = ref.read(sessionControllerProvider);
          // Visitante confirmado pode ver o mapa público mesmo no fim do boot.
          if (session is! SessionPublic) {
            return const _AuthBootstrapHold();
          }
        }
        return const PublicMapScreen();
      },
    );
  }
}

class _AuthBootstrapHold extends StatelessWidget {
  const _AuthBootstrapHold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // IPA-123: branco estável — mesma linguagem do splash / bootstrap DB.
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}
