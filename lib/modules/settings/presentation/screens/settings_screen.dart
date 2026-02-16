import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../ui/theme/soloforte_theme.dart';
import '../../../../core/session/session_controller.dart';
import '../providers/settings_providers.dart';
import '../../domain/settings_models.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Current theme colors for consistency with global theme if needed,
    // but we use SoloForteTheme styles logic or context.
    // The scaffold background is set by main.dart theme, so we can rely on Theme.of(context)
    final theme = Theme.of(context);
    final userProfile = ref.watch(profileProvider);
    final currentThemeMode = ref.watch(themeProvider);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.1,
                child: Image.asset(
                  'assets/images/soloforte_logo.png',
                  width: 300,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Customizado
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Configurações',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Perfil
                      _buildSectionHeader('PERFIL'),
                      _buildSection(context, [
                        _buildProfileTile(context, ref, userProfile),
                        _buildSwitchTile(
                          context,
                          title: 'Usar como ícone do app',
                          value: userProfile.useAsAppIcon,
                          onChanged: (val) => ref
                              .read(profileProvider.notifier)
                              .toggleUseAsAppIcon(val),
                        ),
                      ]),

                      // Aparência
                      _buildSectionHeader('APARÊNCIA'),
                      _buildSection(context, [
                        _buildThemeSelector(context, ref, currentThemeMode),
                      ]),

                      // Dados Offline
                      _buildSectionHeader('DADOS OFFLINE'),
                      _buildSection(context, [
                        _buildSwitchTile(
                          context,
                          title: 'Modo Offline',
                          subtitle:
                              'Baixar mapas e dados para uso sem internet.',
                          value: false, // Placeholder
                          onChanged: (val) {},
                          icon: Icons.offline_pin_outlined,
                        ),
                        // Storage Usage
                        _buildStorageUsageTile(context, ref),
                        _buildActionTile(
                          context,
                          title: 'Limpar cache',
                          icon: Icons.cleaning_services_outlined,
                          onTap: () async {
                            // Placeholder action
                          },
                        ),
                        _buildActionTile(
                          context,
                          title: 'Limpar dados locais',
                          icon: Icons.delete_outline,
                          isDestructive: true,
                          onTap: () => _showClearConfirmation(context),
                        ),
                      ]),

                      // Preferências
                      _buildSectionHeader('PREFERÊNCIAS'),
                      _buildSection(context, [
                        _buildSwitchTile(
                          context,
                          title: 'Notificações',
                          value: true,
                          onChanged: (val) {},
                          icon: Icons.notifications_none,
                        ),
                        _buildTile(
                          context,
                          title: 'Relatórios & Exportação',
                          icon: Icons.bar_chart,
                          onTap: () {},
                        ),
                        _buildTile(
                          context,
                          title: 'Termos de Serviço',
                          icon: Icons.description_outlined,
                          onTap: () {},
                        ),
                      ]),

                      // Sessão
                      _buildSectionHeader('SESSÃO'),
                      _buildSection(context, [
                        _buildActionTile(
                          context,
                          title: 'Sair do aplicativo',
                          icon: Icons.logout,
                          isDestructive: true,
                          onTap: () {
                            ref
                                .read(sessionControllerProvider.notifier)
                                .logout();
                          },
                        ),
                      ]),

                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'SoloForte v1.0.0',
                          style: SoloTextStyles.label,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: SoloTextStyles.label),
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
  ) {
    File? imageFile;
    if (profile.imagePath != null) {
      imageFile = File(profile.imagePath!);
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
                  backgroundImage: imageFile != null
                      ? FileImage(imageFile)
                      : null,
                  child: imageFile == null
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
                  style: SoloTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontSize: 17,
                  ),
                ),
                Text('Toque para alterar', style: SoloTextStyles.label),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                        ? Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 3,
                          )
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
                      ? SoloTextStyles.label.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        )
                      : SoloTextStyles.label,
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
            _buildStatItem('Mapas', data['mapas'] ?? '0'),
            _buildStatItem('Dados', data['dados'] ?? '0'),
            _buildStatItem('Cache', data['cache'] ?? '0'),
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: SoloTextStyles.headingMedium.copyWith(fontSize: 16)),
        Text(label, style: SoloTextStyles.label),
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
      onChanged: onChanged,
      title: Text(
        title,
        style: SoloTextStyles.body.copyWith(
          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: SoloTextStyles.label)
          : null,
      secondary: icon != null
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            )
          : null,
      activeTrackColor: Theme.of(context).primaryColor,
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
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: SoloTextStyles.body.copyWith(
          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
      onTap: onTap,
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
        : Theme.of(context).primaryColor;
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
        style: SoloTextStyles.body.copyWith(
          color: isDestructive
              ? color
              : (isDark ? Colors.white : const Color(0xFF1D1D1F)),
        ),
      ),
      onTap: onTap,
      dense: true,
    );
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
