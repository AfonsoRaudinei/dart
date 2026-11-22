import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import '../client_list_filter_logic.dart';
import '../providers/clients_providers.dart';
import '../widgets/client_list_filters_sheet.dart';
import '../../../../../core/router/app_routes.dart';
import '../../domain/client.dart';
import '../../domain/enums/cultura_tipo.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import '../widgets/client_avatar_widget.dart';
import 'dart:ui' as ui;
import 'package:soloforte_app/core/ui/keyboard_dismiss.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';
import 'package:soloforte_app/ui/components/consultant_share_accept_dialog.dart';

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(syncOrchestratorProvider, (_, orchestrator) {
      if (!orchestrator.isSyncing) {
        ref.invalidate(clientsListProvider);
        ref.invalidate(clientListCulturaIndexProvider);
      }
    });

    final clientsAsync = ref.watch(filteredClientsProvider);
    final filter = ref.watch(clientFilterProvider);
    final advanced = ref.watch(clientAdvancedFiltersProvider);
    final headerExtra = advanced.hasAny ? 48.0 : 0.0;
    final expandedHeight = 176.0 + headerExtra;

    return SoloforteKeyboardDismiss(
      child: Scaffold(
        backgroundColor: context.premiumBackground,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: expandedHeight,
              backgroundColor: context.premiumBackground.withValues(alpha: 0.8),
              surfaceTintColor: Colors.transparent,
              flexibleSpace: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    SoloforteKeyboardDismiss.dismiss();
                    context.push(AppRoutes.clientNew);
                  },
                  icon: Icon(SFIcons.add, color: context.themeAccent, size: 28),
                ),
                const SizedBox(width: 8),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(expandedHeight),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Clientes',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                        onTapOutside: (_) => SoloforteKeyboardDismiss.dismiss(),
                        onChanged: (value) =>
                            ref.read(clientSearchProvider.notifier).state =
                                value,
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
                        children: [
                          ...['Todos', 'Ativos', 'Inativos'].map((f) {
                            final isSelected = filter == f;
                            final accent = Theme.of(
                              context,
                            ).colorScheme.primary;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () =>
                                    ref
                                            .read(clientFilterProvider.notifier)
                                            .state =
                                        f,
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? accent
                                        : context.premiumSurface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? accent
                                          : context.premiumHairline,
                                    ),
                                  ),
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimary
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
                          }),
                          _FiltrosChip(
                            activeCount: advanced.activeChipCount,
                            onTap: () =>
                                showClientListFiltersSheet(context, ref),
                          ),
                        ],
                      ),
                    ),
                    if (advanced.hasAny) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ...advanced.cityKeys.map((key) {
                              return _ActiveFilterChip(
                                label: clientCityKeyLabel(key),
                                onRemove: () {
                                  final next = Set<String>.from(
                                    advanced.cityKeys,
                                  )..remove(key);
                                  ref
                                      .read(
                                        clientAdvancedFiltersProvider.notifier,
                                      )
                                      .state = advanced.copyWith(
                                    cityKeys: next,
                                  );
                                },
                              );
                            }),
                            ...advanced.culturas.map((cultura) {
                              return _ActiveFilterChip(
                                label: cultura.label,
                                onRemove: () {
                                  final next = Set<CulturaTipo>.from(
                                    advanced.culturas,
                                  )..remove(cultura);
                                  ref
                                      .read(
                                        clientAdvancedFiltersProvider.notifier,
                                      )
                                      .state = advanced.copyWith(
                                    culturas: next,
                                  );
                                },
                              );
                            }),
                            if (advanced.areaRange != null)
                              _ActiveFilterChip(
                                label: advanced.areaRange!.label,
                                onRemove: () {
                                  ref
                                      .read(
                                        clientAdvancedFiltersProvider.notifier,
                                      )
                                      .state = advanced.copyWith(
                                    clearAreaRange: true,
                                  );
                                },
                              ),
                            _ActiveFilterChip(
                              label: 'Limpar filtros',
                              emphasize: true,
                              onRemove: () {
                                ref
                                        .read(
                                          clientAdvancedFiltersProvider
                                              .notifier,
                                        )
                                        .state =
                                    const ClientListAdvancedFilters();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(height: 1, color: context.premiumHairline),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: ConsultantReceiveCodeCard()),

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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: context.premiumTextSecondary),
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
                          onTap: () {
                            SoloforteKeyboardDismiss.dismiss();
                            context.push(AppRoutes.clientDetail(client.id));
                          },
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      if (_clientLocation(client) != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _clientLocation(client)!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: context.premiumTextSecondary,
                                              ),
                                        ),
                                      ],
                                      if (client.phone.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          client.phone,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: context.premiumTextTertiary,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(
                                  SFIcons.chevronRight,
                                  color: context.premiumTextTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }, childCount: clients.length),
                  );
                },
                loading: () => SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.themeAccent,
                    ),
                  ),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(
                    child: Text(userFacingError(err, action: 'Erro')),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FiltrosChip extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FiltrosChip({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final hasBadge = activeCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: hasBadge
              ? accent.withValues(alpha: 0.12)
              : context.premiumSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasBadge ? accent : context.premiumHairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filtros',
              style: TextStyle(
                color: hasBadge ? accent : context.premiumTextPrimary,
                fontWeight: hasBadge ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (hasBadge) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool emphasize;

  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: emphasize
                ? accent.withValues(alpha: 0.08)
                : context.premiumSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: emphasize ? accent : context.premiumHairline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: emphasize ? accent : context.premiumTextPrimary,
                  fontWeight: emphasize ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                SFIcons.close,
                size: 14,
                color: emphasize ? accent : context.premiumTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Cidade - UF" sem sobras quando algum campo está vazio; null se ambos vazios.
String? _clientLocation(Client client) {
  final parts = [
    client.city,
    client.state,
  ].map((e) => e.trim()).where((e) => e.isNotEmpty && e != '-').toList();
  return parts.isEmpty ? null : parts.join(' - ');
}
