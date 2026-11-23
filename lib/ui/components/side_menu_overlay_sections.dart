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
                    route: AppRoutes.agenda,
                  ),
                  _MenuItem(
                    icon: Icons.people_outline_rounded,
                    label: 'Clientes',
                    route: AppRoutes.clients,
                  ),
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    label: 'Relatórios',
                    route: AppRoutes.reports,
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback',
                    route: AppRoutes.feedback,
                  ),
                  _MenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Carteira',
                    route: AppRoutes.carteira,
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Configurações',
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
                    icon: Icons.calendar_today_outlined,
                    label: 'Calendário',
                    subtitle: 'Plantio, estádios e visitas',
                    route: AppRoutes.producerCalendar,
                  ),
                  _MenuItem(
                    icon: Icons.analytics_outlined,
                    label: 'Relatórios',
                    route: AppRoutes.reports,
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Feedback',
                    route: AppRoutes.feedback,
                  ),
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    label: 'Configurações',
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
          const SideMenuQuickAccessBlock(),
        ],
      ],
    );
  }
}
