import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';

/// Duas colunas por dia no card de compartilhamento: chance (%) e mm.
class ClimaShareRainChart extends StatelessWidget {
  const ClimaShareRainChart({super.key, required this.dias});

  final List<PrevisaoDiaria> dias;

  static const double _barMaxHeight = 72;

  /// 5 mm enche a coluna de volume; acima disso a escala acompanha o pico.
  static const double _mmPiso = 5;

  @override
  Widget build(BuildContext context) {
    final visiveis = dias.take(7).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    final picoMm = visiveis.fold<double>(
      0,
      (pico, dia) => math.max(pico, dia.precipitacao),
    );
    final escalaMm = math.max(_mmPiso, picoMm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _Legenda(color: Color(0xFF8EDEFF), label: 'Chance %'),
            SizedBox(width: 14),
            _Legenda(color: Color(0xFF7DFFB3), label: 'mm'),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final dia in visiveis)
              Expanded(
                child: _DiaColunas(
                  rotulo: ClimaSharePayloadSemanal.diaCurto(dia.data),
                  chance: dia.probabilidadeChuva.clamp(0, 100),
                  mm: dia.precipitacao,
                  escalaMm: escalaMm,
                ),
              ),
          ],
        ),
      ],
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
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xE6FFFFFF),
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _Barra(
                  fracao: chance / 100,
                  valor: '$chance%',
                  color: const Color(0xFF8EDEFF),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: _Barra(
                  fracao: (mm / escalaMm).clamp(0, 1),
                  valor: _mmRotulo(mm),
                  color: const Color(0xFF7DFFB3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rotulo,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
    final altura = math.max(3.0, ClimaShareRainChart._barMaxHeight * fracao);
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: ClimaShareRainChart._barMaxHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: altura,
              decoration: BoxDecoration(
                color: color,
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

String _mmRotulo(double mm) {
  if (mm <= 0) return '0';
  if (mm >= 10) return mm.toStringAsFixed(0);
  return mm.toStringAsFixed(1);
}
