import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Configurações', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
            ),
            onPressed: () {
              ref.read(sessionControllerProvider.notifier).logout();
            },
            child: const Text('Sair (Logout)'),
          ),
        ],
      ),
    );
  }
}

class AgendaScreen extends StatelessWidget {
  const AgendaScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  // Removido const/style fixo
                  const Text('Agenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Expanded(
              child: Center(
                // Removido const/style fixo
                child: Text('Agenda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Removido const
    return const Center(child: Text('Clientes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)));
  }
}
