import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

enum JanelaPulverizacaoStatus {
  favoravel,
  atencao,
  desfavoravel,
}

class ClimaPulverizacaoCard extends StatelessWidget {
  final ClimaAtual clima;

  const ClimaPulverizacaoCard({super.key, required this.clima});

  JanelaPulverizacaoStatus get _status {
    if (clima.precipitacao > 0) return JanelaPulverizacaoStatus.desfavoravel;
    if (clima.ventoVelocidade > 15) return JanelaPulverizacaoStatus.desfavoravel;
    if (clima.temperatura >= 32) return JanelaPulverizacaoStatus.desfavoravel;
    if (clima.umidade < 45) return JanelaPulverizacaoStatus.desfavoravel;

    if (clima.ventoVelocidade < 3) return JanelaPulverizacaoStatus.atencao;
    if (clima.ventoVelocidade > 10) return JanelaPulverizacaoStatus.atencao;
    if (clima.temperatura >= 30) return JanelaPulverizacaoStatus.atencao;
    if (clima.umidade < 55) return JanelaPulverizacaoStatus.atencao;

    return JanelaPulverizacaoStatus.favoravel;
  }

  String get _recomendacao {
    final motivos = <String>[];

    if (clima.precipitacao > 0) {
      motivos.add('Chuva detectada — risco de lavagem da calda.');
    }
    if (clima.ventoVelocidade > 15) {
      motivos.add('Vento forte (${clima.ventoVelocidade.round()} km/h) — alto risco de deriva.');
    } else if (clima.ventoVelocidade > 10) {
      motivos.add('Vento moderado (${clima.ventoVelocidade.round()} km/h) — use bicos de baixa deriva.');
    } else if (clima.ventoVelocidade < 3) {
      motivos.add('Vento calmo (<3 km/h) — risco de inversão térmica.');
    }

    if (clima.temperatura >= 32) {
      motivos.add('Temperatura muito alta (${clima.temperatura.round()}°C) — evaporação crítica.');
    } else if (clima.temperatura >= 30) {
      motivos.add('Temperatura elevada (${clima.temperatura.round()}°C) — monitore evaporação.');
    }

    if (clima.umidade < 45) {
      motivos.add('Umidade muito baixa (${clima.umidade}%) — rápida dessecação das gotas.');
    } else if (clima.umidade < 55) {
      motivos.add('Umidade limítrofe (${clima.umidade}%) — prefira gotas médias/grossas.');
    }

    if (motivos.isEmpty) {
      return 'Condições climáticas ideais para pulverização foliar e aplicação fitossanitária.';
    }
    return motivos.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (badgeBg, badgeBorder, badgeText, statusLabel, icon) = switch (status) {
      JanelaPulverizacaoStatus.favoravel => (
          isDark ? const Color(0xFF143823) : const Color(0xFFE8F8EE),
          isDark ? const Color(0xFF2EA043) : const Color(0xFF34C759),
          isDark ? const Color(0xFF3FB950) : const Color(0xFF1A6B3C),
          'FAVORÁVEL',
          '✅',
        ),
      JanelaPulverizacaoStatus.atencao => (
          isDark ? const Color(0xFF382E12) : const Color(0xFFFFFBEB),
          isDark ? const Color(0xFFD29922) : const Color(0xFFF59E0B),
          isDark ? const Color(0xFFE3B341) : const Color(0xFFB45309),
          'ATENÇÃO',
          '⚠️',
        ),
      JanelaPulverizacaoStatus.desfavoravel => (
          isDark ? const Color(0xFF3D181A) : const Color(0xFFFEF2F2),
          isDark ? const Color(0xFFF85149) : const Color(0xFFEF4444),
          isDark ? const Color(0xFFFF7B72) : const Color(0xFFB91C1C),
          'DESFAVORÁVEL',
          '🚫',
        ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.climaCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: badgeBorder.withValues(alpha: isDark ? 0.4 : 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: context.climaShadow,
              offset: const Offset(0, 6),
              blurRadius: 18,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🚜', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PULVERIZAÇÃO AGRÍCOLA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: context.climaTextSecondary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: badgeBorder, width: 0.6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _recomendacao,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: context.climaTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, thickness: 0.5, color: context.climaDivider),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CondicaoMini(
                  label: 'Vento',
                  valor: '${clima.ventoVelocidade.round()} km/h',
                  faixaIdeal: '3 a 10 km/h',
                  atende: clima.ventoVelocidade >= 3 && clima.ventoVelocidade <= 10,
                ),
                _CondicaoMini(
                  label: 'Umidade',
                  valor: '${clima.umidade}%',
                  faixaIdeal: '> 55%',
                  atende: clima.umidade >= 55,
                ),
                _CondicaoMini(
                  label: 'Temperatura',
                  valor: '${clima.temperatura.round()}°C',
                  faixaIdeal: '< 30°C',
                  atende: clima.temperatura < 30,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CondicaoMini extends StatelessWidget {
  final String label;
  final String valor;
  final String faixaIdeal;
  final bool atende;

  const _CondicaoMini({
    required this.label,
    required this.valor,
    required this.faixaIdeal,
    required this.atende,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = atende
        ? context.climaTextPrimary
        : const Color(0xFFD97706);

    return Column(
      children: [
        Text(
          valor,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: context.climaTextSecondary,
          ),
        ),
        Text(
          faixaIdeal,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: context.climaTextTertiary,
          ),
        ),
      ],
    );
  }
}
