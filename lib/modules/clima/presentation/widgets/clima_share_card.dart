import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_rain_chart.dart';

/// Card visual para captura PNG e compartilhamento como imagem.
class ClimaShareCard extends StatelessWidget {
  const ClimaShareCard({super.key, required this.payload});

  final ClimaSharePayload payload;

  static const double cardWidth = 360;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1428A0), Color(0xFF2C5564)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SoloForte',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                payload.cidade,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _Corpo(payload: payload),
              const SizedBox(height: 16),
              Text(
                climaShareRodape(payload.fonte),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xB3FFFFFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Corpo extends StatelessWidget {
  const _Corpo({required this.payload});

  final ClimaSharePayload payload;

  @override
  Widget build(BuildContext context) {
    final atual = payload;
    if (atual is ClimaSharePayloadAtual) return _Agora(payload: atual);
    if (atual is ClimaSharePayloadHoraria) return _Horas(payload: atual);
    if (atual is ClimaSharePayloadSemanal) return _Dias(payload: atual);
    return const SizedBox.shrink();
  }
}

class _Agora extends StatelessWidget {
  const _Agora({required this.payload});

  final ClimaSharePayloadAtual payload;

  @override
  Widget build(BuildContext context) {
    final clima = payload.clima;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${clima.temperatura.toStringAsFixed(0)}°',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 56,
            fontWeight: FontWeight.w700,
            height: 1,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          clima.condicao,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Umidade ${clima.umidade}% · '
          '${climaChuvaFrase(clima.precipitacao, inicioMaiusculo: true)}\n'
          'Vento ${clima.ventoVelocidade.toStringAsFixed(0)} km/h '
          '${clima.ventoDirecao} · ${climaUvFrase(clima.indiceUV)}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            height: 1.4,
            color: Color(0xE6FFFFFF),
          ),
        ),
      ],
    );
  }
}

class _Horas extends StatelessWidget {
  const _Horas({required this.payload});

  final ClimaSharePayloadHoraria payload;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final h in payload.previsoes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${h.hora.hour.toString().padLeft(2, '0')}h  '
              '${h.temperatura.toStringAsFixed(0)}°  ${h.condicao}  '
              '${climaChuvaFrase(h.precipitacao, inicioMaiusculo: false)}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.3,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _Dias extends StatelessWidget {
  const _Dias({required this.payload});

  final ClimaSharePayloadSemanal payload;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClimaShareRainChart(dias: payload.previsoes),
        const SizedBox(height: 12),
        ClimaShareWeeklyDays(dias: payload.previsoes),
      ],
    );
  }
}
