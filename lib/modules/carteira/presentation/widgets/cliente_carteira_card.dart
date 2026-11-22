import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

class ClienteCarteiraCard extends StatelessWidget {
  const ClienteCarteiraCard({
    super.key,
    required this.clienteNome,
    required this.mediaPercentual,
    required this.categoriasAtivas,
    required this.categoriasComLancamento,
    required this.onTap,
  });

  final String clienteNome;
  final double mediaPercentual;
  final int categoriasAtivas;

  /// Quantas categorias já têm algum lançamento deste produtor.
  final int categoriasComLancamento;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clamped = mediaPercentual.clamp(0, 100);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                clienteNome,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 10,
                // Sem isto a trilha herda a cor secundária (verde) do tema e
                // 0% parece uma barra cheia.
                backgroundColor: context.premiumHairline,
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Text(
                'Fechado em média: ${NumberFormat('#,##0.#', 'pt_BR').format(clamped)}% '
                '• $categoriasComLancamento de $categoriasAtivas categorias com lançamento',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
