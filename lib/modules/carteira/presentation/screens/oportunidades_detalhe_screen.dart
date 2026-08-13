import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
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
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          ref.read(carteiraSegmentProvider.notifier).state =
              CarteiraSegment.oportunidades;
          context.go(AppRoutes.carteira);
        },
      ),
      body: oportunidadesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) =>
            const Center(child: Text('Erro ao carregar oportunidades.')),
        data: (oportunidades) {
          if (oportunidades.isEmpty) {
            return const Center(
              child: Text('Nenhuma oportunidade em aberto 🎯'),
            );
          }

          final slices = aggregateOpportunitiesByCategory(oportunidades);
          final total = sumOpportunityValues(oportunidades);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              OportunidadesChartCard(
                slices: slices,
                title: 'Oportunidades por categoria',
                totalValue: total,
              ),
              const SizedBox(height: 16),
              OportunidadesChartLegend(slices: slices),
            ],
          );
        },
      ),
    );
  }
}
