part of 'side_menu_overlay.dart';

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          height: 84,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.event_available_outlined,
                  label: 'Nova Visita',
                  route: '${AppRoutes.agenda}?novoEvento=true',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Novo Cliente',
                  route: AppRoutes.clientNew,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.insert_chart_outlined_rounded,
                  label: 'Ver Relatórios',
                  route: AppRoutes.reports,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Nova Ocorrência',
                  route: '${AppRoutes.map}?modo=ocorrencia',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String route;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _closeAndNavigate(context, ref, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _menuGreen, size: 21),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _SummaryMetric(icon: Icons.calendar_today_outlined, label: 'Visitas'),
          _SummaryMetric(icon: Icons.people_outline_rounded, label: 'Clientes'),
          _SummaryMetric(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Carteira',
          ),
          _SummaryMetric(icon: Icons.analytics_outlined, label: 'Relatórios'),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _menuGreen),
          const SizedBox(height: 2),
          const Text(
            '--',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 90),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco_outlined, color: _menuGreen, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foco no que importa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Flexible(
                  child: Text(
                    'Acompanhe suas visitas, clientes e resultados em tempo real.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
