import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import '../providers/clients_providers.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import '../widgets/client_avatar_widget.dart';
import 'dart:ui' as ui;
import 'package:soloforte_app/core/utils/user_facing_error.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncOrchestratorProvider, (_, orchestrator) {
      if (!orchestrator.isSyncing) {
        ref.invalidate(clientsListProvider);
      }
    });

    final clientsAsync = ref.watch(filteredClientsProvider);
    final filter = ref.watch(clientFilterProvider);

    return Scaffold(
      backgroundColor: context.premiumBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 176.0,
            backgroundColor: context.premiumBackground.withValues(
              alpha: 0.8,
            ),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.go(AppRoutes.clientNew),
                icon: const Icon(
                  SFIcons.add,
                  color: PremiumTokens.brandGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(176),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Clientes',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: context.premiumTextPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      onChanged: (value) =>
                          ref.read(clientSearchProvider.notifier).state = value,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          SFIcons.search,
                          color: context.premiumTextSecondary,
                          size: 20,
                        ),
                        hintText: 'Buscar por nome',
                        filled: true,
                        fillColor: context.premiumSurface, // White Inset
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            PremiumTokens.borderRadiusSm,
                          ),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filters
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: ['Todos', 'Ativos', 'Inativos'].map((f) {
                        final isSelected = filter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () =>
                                ref.read(clientFilterProvider.notifier).state =
                                    f,
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? PremiumTokens.brandGreen
                                    : context.premiumSurface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? PremiumTokens.brandGreen
                                      : context.premiumHairline,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : context.premiumTextPrimary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.premiumHairline),
                ],
              ),
            ),
          ),

          // List
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: clientsAsync.when(
              data: (clients) {
                if (clients.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        'Nenhum cliente encontrado',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: context.premiumTextSecondary,
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final client = clients[index];
                    return Dismissible(
                      key: ValueKey(client.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(
                            PremiumTokens.borderRadiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Excluir cliente'),
                                content: Text(
                                  'Deseja excluir "${client.name}"?\nEsta ação não pode ser desfeita.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancelar'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) {
                        ref
                            .read(clientsControllerProvider)
                            .deleteClient(client.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"${client.name}" excluído'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      child: GestureDetector(
                        onTap: () =>
                            context.go(AppRoutes.clientDetail(client.id)),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.premiumSurface,
                            borderRadius: BorderRadius.circular(
                              PremiumTokens.borderRadiusMd,
                            ),
                            boxShadow: PremiumTokens.tightShadow,
                          ),
                          child: Row(
                            children: [
                              ClientAvatarWidget(
                                fotoPath: client.photoPath,
                                nome: client.name,
                                radius: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${client.city} - ${client.state}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: PremiumTokens
                                                .textSecondaryLight,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      client.phone,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color:
                                                PremiumTokens.textTertiaryLight,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                SFIcons.chevronRight,
                                color: PremiumTokens.textTertiaryLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }, childCount: clients.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: PremiumTokens.brandGreen,
                  ),
                ),
              ),
              error: (err, stack) =>
                  SliverFillRemaining(child: Center(child: Text(userFacingError(err, action: 'Erro')))),
            ),
          ),
        ],
      ),
    );
  }
}
