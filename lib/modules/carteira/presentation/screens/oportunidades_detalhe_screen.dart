import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';

/// Detalhe de oportunidades em aberto por cliente.
/// Aberta via Navigator.push — sem rota pública. ADR-022.
class OportunidadesDetalheScreen extends ConsumerWidget {
  const OportunidadesDetalheScreen({
    super.key,
    required this.clienteId,
    required this.clienteNome,
  });

  final String clienteId;
  final String clienteNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oportunidadesAsync =
        ref.watch(clientOpportunitiesProvider(clienteId));
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: Text(clienteNome)),
      body: oportunidadesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Erro ao carregar oportunidades.'),
        ),
        data: (oportunidades) {
          if (oportunidades.isEmpty) {
            return const Center(
              child: Text('Nenhuma oportunidade em aberto 🎯'),
            );
          }

          final totalOpportunityValue = oportunidades.fold<double>(
            0.0,
            (sum, op) => sum + op.totalOpportunityValue,
          );

          final sections = oportunidades.asMap().entries.map(
            (entry) {
              final op = entry.value;
              return PieChartSectionData(
                color: Color(op.categoryColor),
                value: op.totalOpportunityValue > 0
                    ? op.totalOpportunityValue
                    : 0.01,
                radius: 55,
                title: '',
              );
            },
          ).toList();

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                              borderData: FlBorderData(show: false),
                              pieTouchData: PieTouchData(enabled: false),
                              startDegreeOffset: -90,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Oportunidades por categoria',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          totalOpportunityValue > 0
                              ? 'Total: ${currencyFormat.format(totalOpportunityValue)}'
                              : 'Total: R\$ 0',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: oportunidades.map((op) {
                    final percentOfTotal = totalOpportunityValue > 0
                        ? op.totalOpportunityValue / totalOpportunityValue * 100
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(op.categoryColor),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  op.categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currencyFormat.format(op.totalOpportunityValue)} · ${percentOfTotal.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
