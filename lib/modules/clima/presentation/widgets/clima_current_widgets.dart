import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Location Row ─────────────────────────────────────────────────────────────

class ClimaLocationRow extends StatelessWidget {
  final String cidade;
  final DateTime atualizadoEm;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ClimaLocationRow({
    super.key,
    required this.cidade,
    required this.atualizadoEm,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 0),
    this.onTap,
  });

  String get _tempoAtras {
    final diff = DateTime.now().difference(atualizadoEm);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    return 'há ${diff.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(Icons.location_on_rounded, size: 14, color: context.climaTint),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            cidade,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: context.climaTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null) ...[
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: context.climaTextTertiary,
          ),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            'Atualizado $_tempoAtras',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: context.climaTextTertiary,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );

    return Padding(
      padding: padding,
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap!();
              },
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }
}

// ─── Current Weather Card ─────────────────────────────────────────────────────

class ClimaCurrentWeatherCard extends StatelessWidget {
  final ClimaAtual clima;
  final ClimaUnidade unidade;

  const ClimaCurrentWeatherCard({
    super.key,
    required this.clima,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: climaHeroCardDecoration(context, clima.condicaoCodigo),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  climaWeatherEmoji(clima.condicaoCodigo),
                  style: const TextStyle(fontSize: 64),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      climaTempStr(clima.temperatura, unidade),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -2,
                        color: kClimaOnGradientText,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clima.condicao.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: kClimaOnGradientTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 0.5,
              color: kClimaOnGradientText.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniStat(
                  label: 'Sensação',
                  value: climaTempStr(clima.sensacaoTermica, unidade),
                  onGradient: true,
                ),
                _MiniStat(
                  label: 'Nascer ☀️',
                  value: _hm(clima.nascerSol),
                  onGradient: true,
                ),
                _MiniStat(
                  label: 'Pôr ☀️',
                  value: _hm(clima.porSol),
                  onGradient: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _hm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool onGradient;

  const _MiniStat({
    required this.label,
    required this.value,
    this.onGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: onGradient
                ? kClimaOnGradientText
                : context.climaTextPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: onGradient
                ? kClimaOnGradientTextMuted
                : context.climaTextTertiary,
          ),
        ),
      ],
    );
  }
}

// ─── Details Card ─────────────────────────────────────────────────────────────

class ClimaDetailsCard extends StatelessWidget {
  final ClimaAtual clima;

  const ClimaDetailsCard({super.key, required this.clima});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _DetailRow(
        '💨',
        'Vento',
        '${clima.ventoVelocidade.round()} km/h ${clima.ventoDirecao}',
      ),
      _DetailRow('💧', 'Umidade', '${clima.umidade}%'),
      _DetailRow('🌧️', 'Chuva', '${clima.precipitacao.toStringAsFixed(1)} mm'),
      _DetailRow('🧭', 'Pressão', '${clima.pressao.round()} hPa'),
      _DetailRow(
        '👁️',
        'Visibilidade',
        '${clima.visibilidade.toStringAsFixed(0)} km',
      ),
      _DetailRow('☁️', 'Nuvens', '${clima.coberturaNuvens}%'),
      _DetailRow('☀️', 'Índice UV', _uvLabel(clima.indiceUV)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        decoration: climaCardDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Detalhes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                  color: context.climaTextPrimary,
                ),
              ),
            ),
            ...List.generate(rows.length, (i) {
              final row = rows[i];
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
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        Text(row.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Text(
                          row.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: context.climaTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          row.value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                            color: context.climaTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _uvLabel(int uv) {
    if (uv <= 2) return '$uv — Baixo';
    if (uv <= 5) return '$uv — Moderado';
    if (uv <= 7) return '$uv — Alto';
    if (uv <= 10) return '$uv — Muito Alto';
    return '$uv — Extremo';
  }
}

class _DetailRow {
  final String emoji;
  final String label;
  final String value;
  const _DetailRow(this.emoji, this.label, this.value);
}

// ─── Alertas Banner ───────────────────────────────────────────────────────────

class ClimaAlertasBanner extends StatelessWidget {
  final List<AlertaMeteorologico> alertas;

  const ClimaAlertasBanner({super.key, required this.alertas});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE9B44C), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  'ALERTAS (${alertas.length})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Color(0xFF92400E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...alertas
                .take(2)
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tipoEmoji(a.tipo),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.titulo,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF92400E),
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

  String _tipoEmoji(TipoAlerta tipo) => switch (tipo) {
    TipoAlerta.tempestade => '⛈️',
    TipoAlerta.geada => '❄️',
    TipoAlerta.chuvaIntensa => '🌧️',
    TipoAlerta.ventoForte => '💨',
    TipoAlerta.temperaturaExtrema => '🌡️',
  };
}

// ─── Period Toggle (Agora | 24h | 7 dias) ─────────────────────────────────────

class ClimaPeriodToggle extends ConsumerWidget {
  const ClimaPeriodToggle({super.key});

  static const labels = ['Agora', '24h', '7 dias'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(climaTabIndexProvider).clamp(0, 2);

    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.climaSegmentTrack,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: _PeriodSegment(
                    label: labels[i],
                    isSelected: selected == i,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(climaTabIndexProvider.notifier).state = i;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? context.climaCard : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: context.climaShadow,
                      offset: const Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              letterSpacing: -0.2,
              color: isSelected
                  ? context.climaTextPrimary
                  : context.climaTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
