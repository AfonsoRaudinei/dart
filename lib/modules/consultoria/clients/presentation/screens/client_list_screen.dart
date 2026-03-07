import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/clients_providers.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';
import '../../../../map/design/sf_icons.dart';
import '../widgets/client_avatar_widget.dart';
import 'dart:ui' as ui;

class ClientListScreen extends ConsumerWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(filteredClientsProvider);
    final filter = ref.watch(clientFilterProvider);

    return Scaffold(
      backgroundColor: PremiumTokens.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: PremiumTokens.backgroundLight.withValues(
              alpha: 0.8,
            ),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Clientes',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: PremiumTokens.textPrimaryLight,
                ),
              ),
              background: ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
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
              preferredSize: const Size.fromHeight(120),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      onChanged: (value) =>
                          ref.read(clientSearchProvider.notifier).state = value,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          SFIcons.search,
                          color: PremiumTokens.textSecondaryLight,
                          size: 20,
                        ),
                        hintText: 'Buscar por nome',
                        filled: true,
                        fillColor: PremiumTokens.surfaceLight, // White Inset
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
                                    : PremiumTokens.surfaceLight,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? PremiumTokens.brandGreen
                                      : PremiumTokens.hairlineLight,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : PremiumTokens.textPrimaryLight,
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
                  const Divider(height: 1, color: PremiumTokens.hairlineLight),
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
                          color: PremiumTokens.textSecondaryLight,
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
                            content:
                                Text('"${client.name}" excluído'),
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
                            color: PremiumTokens.surfaceLight,
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
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${client.city} - ${client.state}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color:
                                              PremiumTokens.textSecondaryLight,
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
                  SliverFillRemaining(child: Center(child: Text('Erro: $err'))),
            ),
          ),
        ],
      ),
    );
  }
}
