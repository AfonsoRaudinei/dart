import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_date_labels.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

/// Quantos dias cabem no card compartilhado.
const int kClimaShareDiasMax = 7;

/// `0`, `0.7`, `1`, `13` — rótulo curto de milímetros, sem `,0` sobrando.
String climaShareMmCurto(double mm) {
  if (mm <= 0) return '0';
  if (mm >= 10) return mm.toStringAsFixed(0);
  final comDecimal = mm.toStringAsFixed(1);
  return comDecimal.endsWith('.0')
      ? comDecimal.substring(0, comDecimal.length - 2)
      : comDecimal;
}

/// Dias da semana no card compartilhado, no modelo da aba 7 dias: gradiente
/// por condição e uma linha por dia.
///
/// A hierarquia é invertida em relação à aba: chuva em destaque (chance e mm
/// num bloco próprio) e temperatura como informação de apoio — o card é
/// compartilhado para decidir pulverização e plantio, não para saber o calor.
class ClimaShareWeeklyDays extends StatelessWidget {
  const ClimaShareWeeklyDays({super.key, required this.dias});

  final List<PrevisaoDiaria> dias;

  @override
  Widget build(BuildContext context) {
    final visiveis = dias.take(kClimaShareDiasMax).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < visiveis.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == visiveis.length - 1 ? 0 : 8,
            ),
            child: _DiaCard(dia: visiveis[i]),
          ),
      ],
    );
  }
}

class _DiaCard extends StatelessWidget {
  const _DiaCard({required this.dia});

  final PrevisaoDiaria dia;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: climaWeatherGradient(dia.condicaoCodigo),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    climaDataDiaMes(dia.data),
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: kClimaOnGradientText,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        climaWeatherEmoji(dia.condicaoCodigo),
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          dia.condicao,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: kClimaOnGradientTextMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${dia.tempMax.toStringAsFixed(0)}° / '
                    '${dia.tempMin.toStringAsFixed(0)}°',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kClimaOnGradientTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _ChuvaDestaque(
              chance: dia.probabilidadeChuva.clamp(0, 100),
              mm: dia.precipitacao,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChuvaDestaque extends StatelessWidget {
  const _ChuvaDestaque({required this.chance, required this.mm});

  final int chance;
  final double mm;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                const Text('☔', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 5),
                Text(
                  '$chance%',
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    letterSpacing: -0.4,
                    color: kClimaOnGradientText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${climaShareMmCurto(mm)} mm',
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kClimaOnGradientAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
