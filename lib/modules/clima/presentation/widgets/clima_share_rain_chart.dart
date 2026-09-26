import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_date_labels.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// 5 mm enche a coluna de volume; acima disso a escala acompanha o pico.
const double _mmEscalaMinima = 5;

const double _barMaxHeight = 64;

const Color _corChance = Color(0xFF007AFF);
const Color _corVolume = Color(0xFF34C759);

/// O PNG compartilhado não acompanha o tema do usuário: cores fixas claras.
const Color _cardSurface = PremiumTokens.surfaceLight;
const Color _textPrimary = PremiumTokens.textPrimaryLight;
const Color _textSecondary = PremiumTokens.textSecondaryLight;

/// Chuva por dia no card compartilhado: chance (%) e volume (mm).
///
/// Reaproveita o card branco dos gráficos da aba 24h — mesmo raio, sombra e
/// título com emoji — para a imagem compartilhada falar a língua do app.
class ClimaShareRainChart extends StatelessWidget {
  const ClimaShareRainChart({super.key, required this.dias});

  final List<PrevisaoDiaria> dias;

  @override
  Widget build(BuildContext context) {
    final visiveis = dias.take(7).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    final picoMm = visiveis.fold<double>(
      0,
      (pico, dia) => math.max(pico, dia.precipitacao),
    );
    final escalaMm = math.max(_mmEscalaMinima, picoMm);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '☔  Chuva na semana',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              children: [
                _Legenda(color: _corChance, label: 'Chance %'),
                SizedBox(width: 12),
                _Legenda(color: _corVolume, label: 'mm'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final dia in visiveis)
                  Expanded(
                    child: _DiaColunas(
                      rotulo: climaDiaSemanaCurto(dia.data),
                      chance: dia.probabilidadeChuva.clamp(0, 100),
                      mm: dia.precipitacao,
                      escalaMm: escalaMm,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }
}

class _DiaColunas extends StatelessWidget {
  const _DiaColunas({
    required this.rotulo,
    required this.chance,
    required this.mm,
    required this.escalaMm,
  });

  final String rotulo;
  final int chance;
  final double mm;
  final double escalaMm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Barra(
                  fracao: chance / 100,
                  valor: '$chance%',
                  color: _corChance,
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _Barra(
                  fracao: (mm / escalaMm).clamp(0, 1),
                  valor: climaShareMmCurto(mm),
                  color: _corVolume,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rotulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.fracao,
    required this.valor,
    required this.color,
  });

  final double fracao;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _barMaxHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: math.max(3, _barMaxHeight * fracao),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
/// por condição, data e condição à esquerda, temperaturas e chuva à direita.
class ClimaShareWeeklyDays extends StatelessWidget {
  const ClimaShareWeeklyDays({super.key, required this.dias});

  final List<PrevisaoDiaria> dias;

  @override
  Widget build(BuildContext context) {
    final visiveis = dias.take(7).toList();
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    climaDataDiaMes(dia.data),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
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
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${dia.tempMax.toStringAsFixed(0)}° / '
                  '${dia.tempMin.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                    color: kClimaOnGradientText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '☔ ${dia.probabilidadeChuva.clamp(0, 100)}%   '
                  '🌧️ ${climaShareMmCurto(dia.precipitacao)} mm',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kClimaOnGradientAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
