import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_charts.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_dica_agronomica.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Hourly Content ───────────────────────────────────────────────────────────

class ClimaHoraryContent extends StatelessWidget {
  final List<PrevisaoHoraria> previsoes;
  final ClimaUnidade unidade;

  const ClimaHoraryContent({
    super.key,
    required this.previsoes,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scroll horizontal — cards compactos
        Padding(
          padding: const EdgeInsets.only(top: 16, left: 20),
          child: SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 20),
              itemCount: previsoes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _HourCard(item: previsoes[i], unidade: unidade),
            ),
          ),
        ),
        ClimaTemperatureLineChart(previsoes: previsoes, unidade: unidade),
        ClimaPrecipitacaoBarChart(previsoes: previsoes),
        const SizedBox(height: 20),
        // Lista detalhada
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: climaCardDecoration(context),
            child: Column(
              children: List.generate(previsoes.length, (i) {
                final h = previsoes[i];
                final hora = '${h.hora.hour.toString().padLeft(2, '0')}h';
                return Column(
                  children: [
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: context.climaDivider,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              hora,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: context.climaTextTertiary,
                              ),
                            ),
                          ),
                          Text(
                            climaWeatherEmoji(h.condicaoCodigo),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              h.condicao,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: context.climaTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            climaTempShort(h.temperatura, unidade),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.4,
                              color: context.climaTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 46,
                            child: Text(
                              '${h.precipitacao.toStringAsFixed(0)} mm',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: context.climaTint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _HourCard extends StatelessWidget {
  final PrevisaoHoraria item;
  final ClimaUnidade unidade;

  const _HourCard({required this.item, required this.unidade});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: climaHourlyCardDecoration(context, item.condicaoCodigo),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            '${item.hora.hour.toString().padLeft(2, '0')}h',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kClimaOnGradientTextMuted,
            ),
          ),
          Text(
            climaWeatherEmoji(item.condicaoCodigo),
            style: const TextStyle(fontSize: 22),
          ),
          Text(
            climaTempShort(item.temperatura, unidade),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kClimaOnGradientText,
            ),
          ),
          Text(
            '${item.precipitacao.toStringAsFixed(0)}mm',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: kClimaOnGradientAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Content ───────────────────────────────────────────────────────────

class ClimaWeeklyContent extends StatelessWidget {
  final List<PrevisaoDiaria> previsoes;
  final ClimaUnidade unidade;

  const ClimaWeeklyContent({
    super.key,
    required this.previsoes,
    required this.unidade,
  });

  static const _diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
  static const _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        children: [
          ClimaDicaAgronomicaCard(previsoes: previsoes),
          ...previsoes.map((d) {
          final diaNome = _diasSemana[d.data.weekday % 7];
          final mesNome = _meses[d.data.month - 1];
          final dataStr =
              '$diaNome ${d.data.day.toString().padLeft(2, '0')}/$mesNome';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: climaWeeklyCardDecoration(context, d.condicaoCodigo),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dataStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kClimaOnGradientText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              climaWeatherEmoji(d.condicaoCodigo),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                d.condicao,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: kClimaOnGradientTextMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (d.temAlerta)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  '⚠️',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${climaTempShort(d.tempMax, unidade)} / ${climaTempShort(d.tempMin, unidade)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: kClimaOnGradientText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🌧️ ${d.precipitacao.toStringAsFixed(0)} mm',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: kClimaOnGradientAccent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
          }),
        ],
      ),
    );
  }
}
