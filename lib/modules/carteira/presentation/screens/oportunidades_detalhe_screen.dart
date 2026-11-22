import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/extensions/context_extensions.dart';
import 'package:soloforte_app/modules/carteira/domain/oportunidades_aggregation.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_module_scaffold.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/oportunidades_chart_card.dart';

/// Detalhe de oportunidades em aberto por cliente (ADR-029).
/// Somente leitura — registro de lançamento fica na aba Clientes.
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
    final oportunidadesAsync = ref.watch(
      clientOpportunitiesProvider(clienteId),
    );

    return CarteiraModuleScaffold(
      title: clienteNome,
      forceSegment: CarteiraSegment.oportunidades,
      body: oportunidadesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Não conseguimos carregar as oportunidades. Tente de novo.')),
        data: (oportunidades) {
          if (oportunidades.isEmpty) {
            return const Center(
              child: Text('Nenhuma oportunidade em aberto 🎯'),
            );
          }

          final slices = aggregateOpportunitiesByCategory(oportunidades);
          final total = sumOpportunityValues(oportunidades);
          final outrasUnidades = oportunidades
              .where((o) => !o.monetaryPerHa)
              .toList();

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              context.fabSafeBottomPadding,
            ),
            children: [
              if (slices.isNotEmpty) ...[
                OportunidadesChartCard(
                  slices: slices,
                  title: 'Oportunidades por categoria',
                  totalValue: total,
                ),
                const SizedBox(height: 16),
                OportunidadesChartLegend(slices: slices),
              ],
              if (outrasUnidades.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Em outras unidades (fora do total em R\$)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                for (final o in outrasUnidades)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 6,
                      backgroundColor: Color(o.categoryColor),
                    ),
                    title: Text(o.categoryName),
                    subtitle: Text(o.unit),
                    trailing: Text(
                      '${o.residualPercent.toStringAsFixed(0)}% em aberto',
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
