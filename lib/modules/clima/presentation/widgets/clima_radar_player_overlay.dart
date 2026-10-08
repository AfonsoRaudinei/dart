import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../providers/radar_providers.dart';

/// Overlay flutuante de controle de reprodução do radar RainViewer (Apple Glass Style).
///
/// Exibe linha do tempo, hora do frame ativo, controles de Play/Pause,
/// navegação frame a frame, legenda de intensidade e toggle de cobertura.
class ClimaRadarPlayerOverlay extends ConsumerStatefulWidget {
  const ClimaRadarPlayerOverlay({super.key});

  @override
  ConsumerState<ClimaRadarPlayerOverlay> createState() =>
      _ClimaRadarPlayerOverlayState();
}

class _ClimaRadarPlayerOverlayState
    extends ConsumerState<ClimaRadarPlayerOverlay> {
  bool _showLegend = false;

  @override
  Widget build(BuildContext context) {
    final radarEnabled = ref.watch(climaRadarEnabledProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;

    if (!radarEnabled || !isOnline) {
      return const SizedBox.shrink();
    }

    final framesAsync = ref.watch(climaRadarFramesProvider);
    final isPlaying = ref.watch(climaRadarPlayingProvider);
    final activeFrame = ref.watch(climaRadarActiveFrameProvider);
    final activeIndex = ref.watch(climaRadarFrameIndexProvider);
    final colorScheme = ref.watch(climaRadarColorSchemeProvider);
    final coverageEnabled = ref.watch(climaRadarCoverageEnabledProvider);
    final controller = ref.read(climaRadarPlaybackControllerProvider);

    return framesAsync.maybeWhen(
      data: (result) {
        if (!result.hasFrames) return const SizedBox.shrink();
        final frames = result.frames;
        final total = frames.length;
        final currentFrame = activeFrame ?? frames[activeIndex.clamp(0, total - 1)];

        final timeStr = formatClimaRadarFrameTimeString(currentFrame.time);
        final ageStr = formatClimaRadarFrameAgeLabel(
          currentFrame.time,
          DateTime.now(),
          isNowcast: currentFrame.isNowcast,
        );

        final safeTop = MediaQuery.of(context).padding.top;

        return Positioned(
          top: safeTop + 62,
          left: 12,
          right: 12,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Linha principal de controles
                        Row(
                          children: [
                            // Botão Play/Pause
                            _IconButtonCircle(
                              icon: isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              tooltip: isPlaying ? 'Pausar' : 'Reproduzir',
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.togglePlayPause();
                              },
                            ),
                            const SizedBox(width: 8),

                            // Voltar frame
                            _IconButtonCircle(
                              icon: Icons.skip_previous_rounded,
                              tooltip: 'Quadro anterior',
                              iconSize: 18,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.stepPrevious(total);
                              },
                            ),
                            const SizedBox(width: 6),

                            // Display de Horário Central
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (currentFrame.isNowcast)
                                        Container(
                                          margin: const EdgeInsets.only(right: 5),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF64D2FF).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                              color: const Color(0xFF64D2FF).withValues(alpha: 0.6),
                                            ),
                                          ),
                                          child: const Text(
                                            'PREV',
                                            style: TextStyle(
                                              color: Color(0xFF64D2FF),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        timeStr,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '· $ageStr',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.72),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),

                                  // Timeline de segmentos/dots
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(total, (index) {
                                      final isSelected = index == activeIndex;
                                      final frame = frames[index];
                                      final isNowcast = frame.isNowcast;

                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.selectionClick();
                                          controller.seekTo(index, total);
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                            vertical: 2,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 180),
                                            width: isSelected ? 12 : 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? (isNowcast
                                                      ? const Color(0xFF64D2FF)
                                                      : const Color(0xFF30D158))
                                                  : (isNowcast
                                                      ? const Color(0xFF64D2FF).withValues(alpha: 0.35)
                                                      : Colors.white.withValues(alpha: 0.3)),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Avançar frame
                            _IconButtonCircle(
                              icon: Icons.skip_next_rounded,
                              tooltip: 'Próximo quadro',
                              iconSize: 18,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                controller.stepNext(total);
                              },
                            ),
                            const SizedBox(width: 8),

                            // Menu de Opções (Paleta, Cobertura, Legenda)
                            _IconButtonCircle(
                              icon: Icons.tune_rounded,
                              tooltip: 'Ajustes do radar',
                              iconSize: 18,
                              onTap: () => _openRadarOptionsMenu(
                                context,
                                colorScheme: colorScheme,
                                coverageEnabled: coverageEnabled,
                                controller: controller,
                              ),
                            ),
                          ],
                        ),

                        // Legenda de Intensidade Expandível
                        if (_showLegend) ...[
                          const SizedBox(height: 8),
                          _RadarIntensityLegendBar(colorScheme: colorScheme),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  void _openRadarOptionsMenu(
    BuildContext context, {
    required int colorScheme,
    required bool coverageEnabled,
    required ClimaRadarPlaybackController controller,
  }) {
    showSoloForteSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      maxHeightFraction: 0.65,
      builder: (ctx) {
        return _RadarOptionsSheet(
          showLegend: _showLegend,
          onToggleLegend: (val) => setState(() => _showLegend = val),
        );
      },
    );
  }
}

class _RadarOptionsSheet extends ConsumerWidget {
  final bool showLegend;
  final ValueChanged<bool> onToggleLegend;

  const _RadarOptionsSheet({
    required this.showLegend,
    required this.onToggleLegend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.watch(climaRadarColorSchemeProvider);
    final coverageEnabled = ref.watch(climaRadarCoverageEnabledProvider);
    final controller = ref.read(climaRadarPlaybackControllerProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final isIos = soloForteSheetIsIos(context);
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Opções do Radar',
            style: TextStyle(
              fontSize: SoloForteSheetTokens.titleFontSize,
              fontWeight: SoloForteSheetTokens.titleWeight,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),

          // Switch de Legenda
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.bar_chart_rounded, color: Colors.blueAccent),
            title: const Text(
              'Legenda de Intensidade',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Exibe régua de cores no player do mapa',
              style: TextStyle(fontSize: 12),
            ),
            value: showLegend,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              onToggleLegend(val);
            },
          ),
          const Divider(height: 20),

          // Switch de Cobertura
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.radar_rounded, color: Colors.blueAccent),
            title: const Text(
              'Máscara de Cobertura',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: const Text(
              'Mostra alcance dos radares terrestres',
              style: TextStyle(fontSize: 12),
            ),
            value: coverageEnabled,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              controller.toggleCoverage();
            },
          ),
          const Divider(height: 20),

          const Text(
            'PALETA DE CORES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _PaletteOptionCard(
                  title: 'Universal Blue',
                  description: 'Suave / Padrão',
                  isSelected: colorScheme == 2,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setColorScheme(2);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PaletteOptionCard(
                  title: 'NEXRAD Nível III',
                  description: 'Alto Contraste',
                  isSelected: colorScheme == 6,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setColorScheme(6);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;

  const _IconButtonCircle({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaletteOptionCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final secondaryTextColor =
        theme.textTheme.bodySmall?.color ?? Colors.black54;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : Colors.black.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? primaryColor : textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                color: isSelected
                    ? primaryColor.withValues(alpha: 0.8)
                    : secondaryTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarIntensityLegendBar extends StatelessWidget {
  final int colorScheme;

  const _RadarIntensityLegendBar({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final gradientColors = colorScheme == 6
        ? const [
            Color(0xFF00E400), // Fraca (verde)
            Color(0xFFFFFF00), // Moderada (amarelo)
            Color(0xFFFF7E00), // Forte (laranja)
            Color(0xFFFF0000), // Muito forte (vermelho)
            Color(0xFF8F3F97), // Tempestade (roxo)
          ]
        : const [
            Color(0xFF80D8FF), // Fraca (azul claro)
            Color(0xFF0091EA), // Moderada (azul médio)
            Color(0xFF00C853), // Forte (verde)
            Color(0xFFFFD600), // Muito forte (amarelo)
            Color(0xFFFF1744), // Tempestade (vermelho)
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fraca',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              ),
              Text(
                'Moderada',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              ),
              Text(
                'Forte',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              ),
              Text(
                'Tempestade',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(colors: gradientColors),
            ),
          ),
        ],
      ),
    );
  }
}
