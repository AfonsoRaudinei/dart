import 'package:flutter/material.dart';

class ClienteCarteiraCard extends StatelessWidget {
  const ClienteCarteiraCard({
    super.key,
    required this.clienteNome,
    required this.mediaPercentual,
    required this.categoriasAtivas,
    required this.onTap,
  });

  final String clienteNome;
  final double mediaPercentual;
  final int categoriasAtivas;
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
                borderRadius: BorderRadius.circular(999),
              ),
              const SizedBox(height: 8),
              Text(
                'Média geral: ${clamped.toStringAsFixed(1)}% • $categoriasAtivas categorias',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
