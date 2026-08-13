import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Dica Agronomica Card ─────────────────────────────────────────────────────

/// Card com dicas agronômicas geradas por regras a partir da previsão semanal.
class ClimaDicaAgronomicaCard extends StatelessWidget {
  final List<PrevisaoDiaria> previsoes;

  const ClimaDicaAgronomicaCard({super.key, required this.previsoes});

  @override
  Widget build(BuildContext context) {
    final dicas = _gerarDicas(previsoes);
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

  static List<_Dica> _gerarDicas(List<PrevisaoDiaria> previsoes) {
    if (previsoes.isEmpty) return [];

    final dicas = <_Dica>[];
    final proximos2 = previsoes.take(2).toList();
    final proximos7 = previsoes.take(7).toList();

    final chuvaIntensa = proximos2.any((d) => d.precipitacao > 5);
    if (chuvaIntensa) {
      dicas.add(const _Dica(
        '🌧️',
        'Chuva prevista nos próximos 2 dias — evite aplicações fitossanitárias e adubações de cobertura.',
      ));
    }

    final seco = proximos7.every((d) => d.precipitacao < 1);
    if (seco) {
      dicas.add(const _Dica(
        '🏜️',
        'Período seco prolongado — monitore a umidade do solo e avalie irrigação suplementar.',
      ));
    }

    final ventoForte = proximos2.any((d) => d.ventoMedio > 20);
    if (ventoForte) {
      dicas.add(const _Dica(
        '💨',
        'Ventos fortes previstos — evite pulverizações e operações com pó nos próximos 2 dias.',
      ));
    }

    final temAlerta = proximos7.any((d) => d.temAlerta);
    if (temAlerta) {
      dicas.add(const _Dica(
        '⚠️',
        'Alerta meteorológico previsto para os próximos dias — fique atento antes de iniciar operações de campo.',
      ));
    }

    if (!chuvaIntensa && !seco && !ventoForte && !temAlerta) {
      dicas.add(const _Dica(
        '✅',
        'Condições favoráveis nos próximos dias — bom período para colheita e operações de campo.',
      ));
    }

    return dicas;
  }
}

class _Dica {
  final String emoji;
  final String texto;

  const _Dica(this.emoji, this.texto);
}
