import 'package:flutter/material.dart';

class CategoriaProgressBar extends StatelessWidget {
  const CategoriaProgressBar({
    super.key,
    required this.nome,
    required this.cor,
    required this.percentual,
    required this.observacao,
    required this.onTap,
  });

  final String nome;
  final Color cor;
  final int percentual;
  final String? observacao;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clamped = percentual.clamp(0, 100);

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
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: cor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nome,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '$clamped%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: clamped / 100,
                minHeight: 10,
                color: cor,
                borderRadius: BorderRadius.circular(999),
              ),
              if ((observacao ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(observacao!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
