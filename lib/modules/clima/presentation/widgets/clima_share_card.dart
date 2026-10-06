import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/clima_share_payload.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_share_weekly_days.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_weather_icon.dart';

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
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF123A8C), Color(0xFF0B2156)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Cabecalho(payload: payload),
              const SizedBox(height: 14),
              _Corpo(payload: payload),
              const SizedBox(height: 14),
              _Rodape(payload: payload),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.payload});

  final ClimaSharePayload payload;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOLOFORTE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.place_rounded,
                    size: 15,
                    color: kClimaOnGradientText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      payload.cidade,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: kClimaOnGradientText,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _PeriodoBadge(payload: payload),
      ],
    );
  }
}

class _PeriodoBadge extends StatelessWidget {
  const _PeriodoBadge({required this.payload});

  final ClimaSharePayload payload;

  String get _label {
    if (payload is ClimaSharePayloadAtual) return 'AGORA';
    if (payload is ClimaSharePayloadHoraria) return 'PRÓXIMAS HORAS';
    if (payload is ClimaSharePayloadSemanal) return '7 DIAS';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_label.isEmpty) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: kClimaOnGradientText,
          ),
        ),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  const _Rodape({required this.payload});

  final ClimaSharePayload payload;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.verified_rounded,
          size: 13,
          color: Colors.white.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            climaShareRodape(payload.fonte),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xB3FFFFFF),
            ),
          ),
        ),
      ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: climaWeatherGradient(clima.condicaoCodigo),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${clima.temperatura.toStringAsFixed(0)}°',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -2,
                          color: kClimaOnGradientText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        clima.condicao,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kClimaOnGradientText,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    climaWeatherIcon(clima.condicaoCodigo),
                    size: 34,
                    color: kClimaOnGradientText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatBloco(
                    icon: Icons.umbrella_rounded,
                    rotulo: 'CHUVA',
                    valor: '${climaShareMmCurto(clima.precipitacao)} mm',
                  ),
                ),
                Expanded(
                  child: _StatBloco(
                    icon: Icons.water_drop_rounded,
                    rotulo: 'UMIDADE',
                    valor: '${clima.umidade}%',
                  ),
                ),
                Expanded(
                  child: _StatBloco(
                    icon: Icons.air_rounded,
                    rotulo: 'VENTO',
                    valor:
                        '${clima.ventoVelocidade.toStringAsFixed(0)} km/h',
                  ),
                ),
                Expanded(
                  child: _StatBloco(
                    icon: Icons.wb_sunny_rounded,
                    rotulo: 'UV',
                    valor: '${clima.indiceUV}',
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

class _StatBloco extends StatelessWidget {
  const _StatBloco({
    required this.icon,
    required this.rotulo,
    required this.valor,
  });

  final IconData icon;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(height: 5),
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.1,
            color: kClimaOnGradientText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rotulo,
          maxLines: 1,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: kClimaOnGradientTextMuted,
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
      children: [
        for (var i = 0; i < payload.previsoes.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == payload.previsoes.length - 1 ? 0 : 8,
            ),
            child: _HoraLinha(previsao: payload.previsoes[i]),
          ),
      ],
    );
  }
}

class _HoraLinha extends StatelessWidget {
  const _HoraLinha({required this.previsao});

  final PrevisaoHoraria previsao;

  @override
  Widget build(BuildContext context) {
    final hora = previsao.hora;
    final codigo = previsao.condicaoCodigo;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: climaWeatherGradient(codigo),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                '${hora.hour.toString().padLeft(2, '0')}h',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kClimaOnGradientText,
                ),
              ),
            ),
            Icon(
              climaWeatherIcon(codigo),
              size: 20,
              color: kClimaOnGradientText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                previsao.condicao,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: kClimaOnGradientTextMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${climaShareMmCurto(previsao.precipitacao)} mm',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kClimaOnGradientAccent,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${previsao.temperatura.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kClimaOnGradientText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dias extends StatelessWidget {
  const _Dias({required this.payload});

  final ClimaSharePayloadSemanal payload;

  @override
  Widget build(BuildContext context) {
    return ClimaShareWeeklyDays(dias: payload.previsoes);
  }
}
