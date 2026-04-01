import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../../../core/design/sf_icons.dart';
import 'package:flutter/services.dart';

/// Tab 4 — PERFIL
/// Exibe dados reais do usuário autenticado via Supabase.
class ProfileTabContent extends ConsumerWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    String displayName = 'Usuário';
    String displayRole = '';

    if (session is SessionAuthenticated) {
      final user = session.user;
      displayName =
          (user.userMetadata?['full_name'] as String?)?.trim().isNotEmpty ==
              true
          ? user.userMetadata!['full_name'] as String
          : user.email ?? 'Usuário';

      final role = user.userMetadata?['role'] as String?;
      displayRole = switch (role) {
        'produtor' => 'Produtor Rural',
        'consultor' => 'Consultor Agronômico',
        _ => '',
      };
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do perfil
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: PremiumTokens.brandGreen.withValues(
                  alpha: 0.2,
                ),
                child: const Icon(
                  SFIcons.person,
                  size: 36,
                  color: PremiumTokens.brandGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600).copyWith(
                        fontSize: 18,
                      ),
                    ),
                    if (displayRole.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        displayRole,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: SFIcons.settings,
            title: 'Configurações',
            onTap: () => context.push(AppRoutes.settings),
          ),
          _ProfileTile(
            icon: SFIcons.accountCircle,
            title: 'Minha Conta',
            onTap: () {},
          ),
          _ProfileTile(icon: SFIcons.help, title: 'Suporte', onTap: () {}),
          _ProfileTile(icon: SFIcons.info, title: 'Sobre', onTap: () {}),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: SFIcons.logout,
            title: 'Sair',
            isDestructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text(
          'Deseja mesmo sair? Seus dados locais serão mantidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(sessionControllerProvider.notifier).logout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : Colors.black.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (!isDestructive)
                Icon(
                  SFIcons.chevronRight,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
