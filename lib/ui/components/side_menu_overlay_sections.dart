part of 'side_menu_overlay.dart';

class _SideMenuContent extends StatelessWidget {
  final UserRole role;

  const _SideMenuContent({required this.role});

  @override
  Widget build(BuildContext context) {
    final isConsultor = role.isConsultor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Menu principal'),
        const SizedBox(height: 6),
        _MenuPanel(
          children: isConsultor
              ? const [
                  _MenuItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Agenda',
                    subtitle: 'Próximas visitas',
                    route: AppRoutes.agenda,
                  ),
                  _MenuItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Clientes',
                    subtitle: 'Gerenciar carteira',
                    route: AppRoutes.clients,
                  ),
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    label: 'Relatórios',
                    subtitle: 'Análises e KPIs',
                    route: AppRoutes.reports,
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback',
                    subtitle: 'Envie sua opinião',
                    route: AppRoutes.feedback,
                  ),
                  _MenuItem(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Clima',
                    subtitle: 'Previsão para o campo',
                    route: AppRoutes.clima,
                  ),
                  _MenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Carteira',
                    subtitle: 'Acompanhamento de mercado',
                    route: AppRoutes.carteira,
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Configurações',
                    subtitle: 'Ajustes do aplicativo',
                    route: AppRoutes.settings,
                    showDivider: false,
                  ),
                ]
              : const [
                  _MenuItem(
                    icon: Icons.agriculture_outlined,
                    label: 'Minha propriedade',
                    subtitle: 'Fazendas e relatórios',
                    route: AppRoutes.producerProperty,
                  ),
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    label: 'Relatórios',
                    subtitle: 'Análises e KPIs',
                    route: AppRoutes.reports,
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback',
                    subtitle: 'Envie sua opinião',
                    route: AppRoutes.feedback,
                  ),
                  _MenuItem(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Clima',
                    subtitle: 'Previsão para o campo',
                    route: AppRoutes.clima,
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Configurações',
                    subtitle: 'Ajustes do aplicativo',
                    route: AppRoutes.settings,
                    showDivider: false,
                  ),
                ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Conta'),
        const SizedBox(height: 6),
        const _MenuPanel(children: [_MenuPlanoBadgeItem(), _ManualSyncItem()]),
        if (isConsultor) ...[
          const SizedBox(height: 18),
          const _SectionTitle('Acesso rápido'),
          const SizedBox(height: 8),
          const _QuickActionsGrid(),
          const SizedBox(height: 18),
          const _SectionTitle('Resumo de hoje'),
          const SizedBox(height: 8),
          const _DailySummary(),
          const SizedBox(height: 16),
          const _MotivationalCard(),
        ],
      ],
    );
  }
}

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
        side: BorderSide(color: _menuBorder(context)),
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
              Icon(icon, color: _menuAccent(context), size: 21),
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
        color: _menuIconBg(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
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
          Icon(icon, size: 15, color: _menuAccent(context)),
          const SizedBox(height: 2),
          const Text(
            '--',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: _menuSecondaryText(context)),
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
        color: _menuIconBg(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.eco_outlined, color: _menuAccent(context), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foco no que importa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: Text(
                    'Acompanhe suas visitas, clientes e resultados em tempo real.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: _menuSecondaryText(context),
                    ),
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
