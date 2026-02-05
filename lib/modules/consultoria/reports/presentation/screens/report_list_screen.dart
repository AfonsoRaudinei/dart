import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../clients/presentation/providers/clients_providers.dart';
import '../../domain/report_model.dart';
import '../providers/reports_providers.dart';
import '../../../../../core/router/app_routes.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(filteredReportsProvider);
    final filter = ref.watch(reportFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Customizado
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Relatórios',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 30),
                    onPressed: () {
                      context.go(AppRoutes.reportNew);
                    },
                  ),
                ],
              ),
            ),
            // Filters
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
                        ref.read(reportFilterProvider.notifier).state =
                            'Compartilhados';
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // List
            Expanded(
              child: reportsAsync.when(
                data: (reports) {
                  if (reports.isEmpty) {
                    return const Center(
                      child: Text('Nenhum relatório encontrado.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _ReportCard(report: report);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Erro: $err')),
              ),
            ),
          ],
        ),
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          context.go(AppRoutes.reportDetail(report.id));
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.blue.withOpacity(0.1),
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
