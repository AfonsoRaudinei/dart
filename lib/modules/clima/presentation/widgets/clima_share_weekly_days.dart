import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_date_labels.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_weather_icon.dart';

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
              bottom: i == visiveis.length - 1 ? 0 : 10,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DataChip(data: dia.data),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CondicaoBloco(dia: dia),
                ),
                const SizedBox(width: 10),
                _ChuvaDestaque(
                  chance: dia.probabilidadeChuva.clamp(0, 100),
                  mm: dia.precipitacao,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.16),
            ),
            const SizedBox(height: 10),
            _TemperaturaLinha(
              tempMax: dia.tempMax,
              tempMin: dia.tempMin,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.data});

  final DateTime data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 11,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(width: 6),
            Text(
              climaDataDiaMes(data).toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: kClimaOnGradientText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CondicaoBloco extends StatelessWidget {
  const _CondicaoBloco({required this.dia});

  final PrevisaoDiaria dia;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            climaWeatherIcon(dia.condicaoCodigo),
            size: 24,
            color: kClimaOnGradientText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dia.condicao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: kClimaOnGradientText,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(
                    Icons.air_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      'Vento ${dia.ventoMedio.toStringAsFixed(0)} km/h',
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
            ],
          ),
        ),
      ],
    );
  }
}

class _ChuvaDestaque extends StatelessWidget {
  const _ChuvaDestaque({required this.chance, required this.mm});

  final int chance;
  final double mm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.umbrella_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'CHUVA',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: kClimaOnGradientTextMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$chance%',
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -0.6,
                      color: kClimaOnGradientText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '${climaShareMmCurto(mm)} mm',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: kClimaOnGradientText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          mm > 0 ? 'precip.' : 'sem chuva',
                          maxLines: 1,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            height: 1.2,
                            color: kClimaOnGradientTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _ChanceBarra(chance: chance),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChanceBarra extends StatelessWidget {
  const _ChanceBarra({required this.chance});

  final int chance;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 5,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: 0.22),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (chance / 100).clamp(0.04, 1).toDouble(),
              child: const ColoredBox(color: kClimaOnGradientText),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemperaturaLinha extends StatelessWidget {
  const _TemperaturaLinha({required this.tempMax, required this.tempMin});

  final double tempMax;
  final double tempMin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TempPill(
          valor: tempMax,
          rotulo: 'MAX',
          iconBg: const Color(0xFFFF8A4C),
        ),
        const SizedBox(width: 18),
        _TempPill(
          valor: tempMin,
          rotulo: 'MIN',
          iconBg: Colors.white.withValues(alpha: 0.2),
        ),
      ],
    );
  }
}

class _TempPill extends StatelessWidget {
  const _TempPill({
    required this.valor,
    required this.rotulo,
    required this.iconBg,
  });

  final double valor;
  final String rotulo;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: const Icon(
            Icons.thermostat_rounded,
            size: 14,
            color: kClimaOnGradientText,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '${valor.toStringAsFixed(0)}°',
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            height: 1,
            color: kClimaOnGradientText,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          rotulo,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: kClimaOnGradientTextMuted,
          ),
        ),
      ],
    );
  }
}
