import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../domain/report_model.dart';
import '../providers/reports_providers.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/modules/map/design/sf_icons.dart';
import 'dart:ui' as ui;

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredReportsProvider);
    final filter = ref.watch(reportFilterProvider);

    return Scaffold(
      backgroundColor: PremiumTokens.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120.0,
            backgroundColor: PremiumTokens.backgroundLight.withValues(alpha: 0.8),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Relatórios',
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
                icon: const Icon(SFIcons.add, color: PremiumTokens.brandGreen, size: 28),
                onPressed: () {
                  context.go(AppRoutes.reportNew);
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Meus',
                          selected: filter == 'Meus',
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(reportFilterProvider.notifier).state = 'Meus';
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Compartilhados',
                          selected: filter == 'Compartilhados',
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(reportFilterProvider.notifier).state = 'Compartilhados';
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: PremiumTokens.hairlineLight),
                ],
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: reportsAsync.when(
              data: (reports) {
                if (reports.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text('Nenhum relatório encontrado.', style: TextStyle(color: PremiumTokens.textSecondaryLight)),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final report = reports[index];
                      return _ReportCard(report: report);
                    },
                    childCount: reports.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: PremiumTokens.brandGreen))),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Erro: $err'))),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(true),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? PremiumTokens.brandGreen : PremiumTokens.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? PremiumTokens.brandGreen : PremiumTokens.hairlineLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : PremiumTokens.textPrimaryLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends ConsumerWidget {
  final Report report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to find client name
    final clientAsync = ref.watch(clientDetailProvider(report.clientId));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GestureDetector(
      onTap: () {
        context.go(AppRoutes.reportDetail(report.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: PremiumTokens.surfaceLight,
          borderRadius: BorderRadius.circular(PremiumTokens.borderRadiusMd),
          boxShadow: PremiumTokens.tightShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              clientAsync.when(
                data: (client) => Text(
                  'Cliente: ${client?.name ?? "Desconhecido"}',
                  style: const TextStyle(color: Colors.grey),
                ),
                loading: () => const Text(
                  'Carregando cliente...',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                error: (_, __) => const Text('Erro ao carregar cliente'),
              ),
              const SizedBox(height: 4),
              Text(
                'Período: ${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Criado em: ${dateFormat.format(report.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
