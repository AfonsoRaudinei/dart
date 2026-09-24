import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_dicas_agronomicas.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Dica Agronomica Card ─────────────────────────────────────────────────────

/// Card com dicas agronômicas geradas por regras a partir da previsão semanal.
class ClimaDicaAgronomicaCard extends StatelessWidget {
  final List<PrevisaoDiaria> previsoes;

  const ClimaDicaAgronomicaCard({super.key, required this.previsoes});

  @override
  Widget build(BuildContext context) {
    final dicas = gerarDicasAgronomicas(previsoes);
    if (dicas.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF242426)
        : const Color(0xFFF0FFF4);
    final borderColor = isDark
        ? context.climaTint.withValues(alpha: 0.45)
        : const Color.fromRGBO(52, 199, 89, 0.35);
    final textColor = isDark
        ? context.climaTextPrimary
        : const Color(0xFF1A6B3C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🌱', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'DICAS AGRONÔMICAS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...dicas.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d.texto,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
