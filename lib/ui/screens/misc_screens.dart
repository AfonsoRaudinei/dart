import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/session/session_controller.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import '../../modules/consultoria/reports/presentation/widgets/kpi_dashboard_widget.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Configurações', style: SoloTextStyles.headingMedium),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SoloForteColors.error,
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

class RelatoriosScreen extends StatelessWidget {
  const RelatoriosScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Removido const
        title: Text(
          'Relatórios & Performance',
          style: SoloTextStyles.headingMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: const KpiDashboardWidget(),
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
                  Text('Agenda', style: SoloTextStyles.headingMedium),
                ],
              ),
            ),
            Expanded(
              child: Center(
                // Removido const/style fixo
                child: Text('Agenda', style: SoloTextStyles.headingMedium),
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
    return Center(child: Text('Clientes', style: SoloTextStyles.headingMedium));
  }
}
