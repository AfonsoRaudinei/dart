import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../../../core/router/app_routes.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import 'dart:ui' as ui;
import '../../../../core/session/session_controller.dart';
import '../providers/settings_providers.dart';
import '../providers/user_profile_provider.dart';
import '../../domain/settings_models.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/audit_trail_widget.dart';
import 'report_branding_screen.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(profileProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final currentThemeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: context.premiumBackground.withValues(alpha: 0.8),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Configurações',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: context.premiumTextPrimary,
                ),
              ),
              background: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 16),
              // Perfil
              _buildSectionHeader('PERFIL'),
              _buildSection(context, [
                _buildProfileTile(context, ref, userProfile, userProfileAsync),
                _buildSwitchTile(
                  context,
                  title: 'Usar como ícone do app',
                  value: userProfile.useAsAppIcon,
                  onChanged: (val) => ref
                      .read(profileProvider.notifier)
                      .toggleUseAsAppIcon(val),
                ),
              ]),

              // Dados cadastrais
              _buildSectionHeader('DADOS CADASTRAIS'),
              _buildSection(context, [
                _buildAccountProfileTile(context, userProfileAsync),
              ]),

              // Aparência
              _buildSectionHeader('APARÊNCIA'),
              _buildSection(context, [
                _buildThemeSelector(context, ref, currentThemeMode),
              ]),

              // Histórico de alterações do perfil
              _buildSectionHeader('HISTÓRICO DE ALTERAÇÕES'),
              _buildSection(context, [
                Consumer(
                  builder: (ctx, r, _) {
                    final auditAsync = r.watch(profileAuditTrailProvider);
                    return auditAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (entries) => AuditTrailWidget(entries: entries),
                    );
                  },
                ),
              ]),

              // Dados Offline
              _buildSectionHeader('DADOS OFFLINE'),
              _buildSection(context, [
                _buildSwitchTile(
                  context,
                  title: 'Modo Offline',
                  subtitle: 'Baixar mapas e dados para uso sem internet.',
                  value: false, // Placeholder
                  onChanged: (val) {},
                  icon: SFIcons.layers,
                ),
                // Storage Usage
                _buildStorageUsageTile(context, ref),
                _buildActionTile(
                  context,
                  title: 'Limpar cache',
                  icon: SFIcons.settings,
                  onTap: () async {
                    // Placeholder action
                  },
                ),
                _buildActionTile(
                  context,
                  title: 'Limpar dados locais',
                  icon: SFIcons.delete,
                  isDestructive: true,
                  onTap: () => _showClearConfirmation(context),
                ),
              ]),

              // Preferências
              _buildSectionHeader('PREFERÊNCIAS'),
              _buildSection(context, [
                _buildTile(
                  context,
                  title: 'Meu Plano',
                  icon: Icons.workspace_premium_rounded,
                  onTap: () => context.go(AppRoutes.meuPlano),
                ),
                _buildSwitchTile(
                  context,
                  title: 'Notificações',
                  value: true,
                  onChanged: (val) {},
                  icon: SFIcons.info,
                ),
                _buildTile(
                  context,
                  title: 'Relatórios & Exportação',
                  icon: SFIcons.openInNew,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReportBrandingScreen(),
                    ),
                  ),
                ),
                _buildTile(
                  context,
                  title: 'Termos de Serviço',
                  icon: SFIcons.info,
                  onTap: () => _openUrl(
                    'https://afonsoraudinei.github.io/SoloForte-Termos-de-Uso/',
                  ),
                ),
                _buildTile(
                  context,
                  title: 'Política de Privacidade',
                  icon: SFIcons.info,
                  onTap: () => _openUrl(
                    'https://afonsoraudinei.github.io/SoloForte-Pol-tica-de-Privacidade/',
                  ),
                ),
              ]),

              // Sessão
              _buildSectionHeader('SESSÃO'),
              _buildSection(context, [
                _buildActionTile(
                  context,
                  title: 'Sair do aplicativo',
                  icon: SFIcons.arrowLeft,
                  isDestructive: true,
                  onTap: () {
                    ref.read(sessionControllerProvider.notifier).logout();
                  },
                ),
                _buildActionTile(
                  context,
                  title: 'Excluir minha conta',
                  icon: SFIcons.delete,
                  isDestructive: true,
                  onTap: () => _showDeleteAccountConfirmation(context, ref),
                ),
              ]),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'SoloForte v1.1.0',
                  style:
                      (Theme.of(context).textTheme.labelMedium ??
                              const TextStyle())
                          .copyWith(color: context.premiumTextSecondary),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Builder(
        builder: (ctx) => Text(
          title,
          style: (Theme.of(ctx).textTheme.labelMedium ?? const TextStyle())
              .copyWith(color: ctx.premiumTextSecondary),
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<Widget> children) {
    // Determine card color based on brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    final List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(const Divider(height: 1, indent: 56));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: dividedChildren),
    );
  }

  // --- Tiles ---

  Widget _buildProfileTile(
    BuildContext context,
    WidgetRef ref,
    ProfileState profile,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    File? imageFile;
    if (profile.imagePath != null && File(profile.imagePath!).existsSync()) {
      imageFile = File(profile.imagePath!);
    }

    final photoUrl = userProfileAsync.asData?.value?.photoUrl ?? '';
    ImageProvider<Object>? avatarImage;
    if (imageFile != null) {
      avatarImage = FileImage(imageFile);
    } else if (photoUrl.trim().isNotEmpty) {
      avatarImage = NetworkImage(photoUrl);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1D1D1F);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showImagePicker(context, ref),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua Foto',
                  style:
                      (Theme.of(context).textTheme.bodyMedium ??
                              const TextStyle())
                          .copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            fontSize: 17,
                          ),
                ),
                Text(
                  'Toque para alterar',
                  style:
                      (Theme.of(context).textTheme.labelMedium ??
                              const TextStyle())
                          .copyWith(color: context.premiumTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context, WidgetRef ref) async {
    showSoloForteSheet(
      context: context,
      showDragHandle: false,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(profileProvider.notifier)
                    .updateImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(profileProvider.notifier)
                    .updateImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    WidgetRef ref,
    String currentTheme,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final themes = [
      {'id': 'green', 'color': const Color(0xFF34C759), 'label': 'Verde'},
      {'id': 'blue', 'color': const Color(0xFF1B6EE0), 'label': 'Azul'},
      {'id': 'black', 'color': const Color(0xFF1A1A1A), 'label': 'Black'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: themes.map((t) {
          final isSelected = t['id'] == currentTheme;
          return GestureDetector(
            onTap: () =>
                ref.read(themeProvider.notifier).setTheme(t['id'] as String),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: t['color'] as Color,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: primaryColor, width: 3)
                        : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: (t['color'] as Color).withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  t['label'] as String,
                  style: isSelected
                      ? (Theme.of(context).textTheme.labelMedium ??
                                const TextStyle())
                            .copyWith(color: context.premiumTextSecondary)
                            .copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            )
                      : (Theme.of(context).textTheme.labelMedium ??
                                const TextStyle())
                            .copyWith(color: context.premiumTextSecondary),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAccountProfileTile(
    BuildContext context,
    AsyncValue<UserProfile?> userProfileAsync,
  ) {
    return userProfileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Não foi possível carregar os dados cadastrais.',
          style: (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
              .copyWith(color: context.premiumTextSecondary),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Usuário não autenticado.',
              style:
                  (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                      .copyWith(color: context.premiumTextSecondary),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                context,
                'Nome',
                profile.fullName?.isNotEmpty == true
                    ? profile.fullName!
                    : 'Não informado',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(context, 'E-mail', profile.email),
              const SizedBox(height: 10),
              _buildInfoRow(
                context,
                'Telefone',
                profile.phone?.isNotEmpty == true
                    ? profile.phone!
                    : 'Não informado',
              ),
              const SizedBox(height: 10),
              _buildInfoRow(
                context,
                'Perfil',
                profile.role?.isNotEmpty == true
                    ? profile.role!
                    : 'Não informado',
              ),
              if (profile.creaNumber?.isNotEmpty == true) ...[
                const SizedBox(height: 10),
                _buildInfoRow(context, 'CREA/CFT', profile.creaNumber!),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.settingsEditProfile),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar perfil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style:
                (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                    .copyWith(
                      color: context.premiumTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
                .copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageUsageTile(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageUsageProvider);

    return storageAsync.when(
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(context, 'Mapas', data['mapas'] ?? '0'),
            _buildStatItem(context, 'Dados', data['dados'] ?? '0'),
            _buildStatItem(context, 'Cache', data['cache'] ?? '0'),
          ],
        ),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle())
              .copyWith(fontSize: 16),
        ),
        Text(
          label,
          style: (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
              .copyWith(color: context.premiumTextSecondary),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SwitchListTile(
      value: value,
      onChanged: (val) {
        HapticFeedback.lightImpact();
        onChanged(val);
      },
      title: Text(
        title,
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: isDark ? Colors.white : const Color(0xFF1D1D1F)),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style:
                  (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                      .copyWith(color: context.premiumTextSecondary),
            )
          : null,
      secondary: icon != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: PremiumTokens.brandGreen, size: 20),
            )
          : null,
      activeTrackColor: PremiumTokens.brandGreen,
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: PremiumTokens.brandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: PremiumTokens.brandGreen, size: 20),
      ),
      title: Text(
        title,
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: isDark ? Colors.white : const Color(0xFF1D1D1F)),
      ),
      trailing: const Icon(
        SFIcons.chevronRight,
        color: PremiumTokens.textTertiaryLight,
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      dense: true,
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFFF3B30)
        : PremiumTokens.brandGreen;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(
              color: isDestructive
                  ? color
                  : (isDark ? Colors.white : const Color(0xFF1D1D1F)),
            ),
      ),
      onTap: () {
        if (isDestructive) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
        onTap();
      },
      dense: true,
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteAccountConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir Conta'),
        content: const Text(
          'Esta ação é permanente e irreversível.\n\n'
          'Todos os seus dados serão removidos:\n'
          '• Perfil e configurações\n'
          '• Fazendas, talhões e visitas\n'
          '• Ocorrências e relatórios\n'
          '• Publicações e planos\n\n'
          'Deseja realmente excluir sua conta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _executeDeleteAccount(context, ref);
            },
            child: const Text(
              'Excluir Permanentemente',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await ref.read(sessionControllerProvider.notifier).deleteAccount();
      // Dialog de loading será descartado automaticamente ao navegar para login
    } catch (e) {
      // Fechar loading
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(e, action: 'Erro ao excluir conta'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Dados Locais?'),
        content: const Text(
          'Isso removerá todos os dados baixados e mapas offline. Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Call clear action
            },
            child: const Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
