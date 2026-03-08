import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';
import 'gps_walk_bottom_bar.dart';
import 'gps_walk_metrics_bar.dart';

/// Overlay composto de controle do modo GPS Walk.
///
/// Agrupa todos os elementos visuais do modo de medição em campo:
/// - [_GpsWalkTopBanner]: banner de instrução no topo do mapa
/// - [GpsWalkMetricsBar]: métricas em tempo real (Perímetro + Área)
/// - [GpsWalkBottomBar]: botões de ação (Começar / Pausar / Concluído)
///
/// ### Posicionamento
/// Projetado para ser inserido como filho do Stack do [DrawingSheet].
/// O [_GpsWalkTopBanner] é posicionado no topo via Overlay do Flutter,
/// garantindo que apareça sobre o mapa sem alterar a hierarquia de widgets.
///
/// ### Isolamento de rebuild
/// Envolvido em [RepaintBoundary] para evitar rebuild do mapa quando
/// métricas GPS atualizam a cada segundo.
///
/// ### Performance
/// - Recalculo de métricas apenas quando `session.points` muda
/// - Widgets de métricas e botões são separados (rebuild isolado)
class GpsWalkControlsOverlay extends ConsumerStatefulWidget {
  const GpsWalkControlsOverlay({super.key});

  @override
  ConsumerState<GpsWalkControlsOverlay> createState() =>
      _GpsWalkControlsOverlayState();
}

class _GpsWalkControlsOverlayState
    extends ConsumerState<GpsWalkControlsOverlay> {
  OverlayEntry? _topBannerEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showTopBanner());
  }

  @override
  void dispose() {
    _removeTopBanner();
    super.dispose();
  }

  void _showTopBanner() {
    if (_topBannerEntry != null) return;
    final overlay = Overlay.of(context);
    _topBannerEntry = OverlayEntry(
      builder: (_) => _GpsWalkTopBannerOverlay(
        onDismiss: _removeTopBanner,
      ),
    );
    overlay.insert(_topBannerEntry!);
  }

  void _removeTopBanner() {
    _topBannerEntry?.remove();
    _topBannerEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(gpsWalkProvider);

    // Remove banner quando a sessão termina ou é cancelada
    if (session == null || session.status == GpsWalkStatus.finished) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _removeTopBanner());
    }

    if (session == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.60),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Drag pill ──────────────────────────────────────
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5C5C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // ── Header ────────────────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.directions_walk_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GPS — Caminhar o perímetro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    _GpsQualityIndicator(),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Métricas ─────────────────────────────────────
                const GpsWalkMetricsBar(),

                const SizedBox(height: 16),

                // ── Ações ─────────────────────────────────────────
                const GpsWalkBottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banner de instrução no topo do mapa ─────────────────────────────────────

/// Overlay posicionado no topo do mapa com instrução contextual ao usuário.
class _GpsWalkTopBannerOverlay extends ConsumerWidget {
  final VoidCallback onDismiss;

  const _GpsWalkTopBannerOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);
    if (session == null || session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final topPad = MediaQuery.of(context).padding.top;
    final message = _message(session.status, session.isAutoMode);

    return Positioned(
      top: topPad + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: _GlassBanner(message: message, status: session.status),
      ),
    );
  }

  String _message(GpsWalkStatus status, bool isAutoMode) {
    switch (status) {
      case GpsWalkStatus.idle:
        return '📍 Pressione "Começar" e caminhe ao redor do campo';
      case GpsWalkStatus.measuring:
        return isAutoMode
            ? '🟢 Caminhando... GPS coletando pontos automaticamente'
            : '👆 Modo manual — toque "Add ponto" ao longo do perímetro';
      case GpsWalkStatus.paused:
        return '⏸ Medição pausada — retome quando quiser continuar';
      case GpsWalkStatus.finished:
        return '';
    }
  }
}

class _GlassBanner extends StatelessWidget {
  final String message;
  final GpsWalkStatus status;

  const _GlassBanner({required this.message, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      GpsWalkStatus.idle => Colors.black.withValues(alpha: 0.72),
      GpsWalkStatus.measuring => const Color(0xFF1C3A1C).withValues(alpha: 0.85),
      GpsWalkStatus.paused => const Color(0xFF3A2E00).withValues(alpha: 0.85),
      GpsWalkStatus.finished => Colors.transparent,
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 0.8,
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Indicador de qualidade GPS compacto ─────────────────────────────────────

class _GpsQualityIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lê a qualidade diretamente do DrawingController (já expõe esse dado)
    // para não duplicar o acesso ao GPS
    final session = ref.watch(gpsWalkProvider);
    if (session == null || session.status == GpsWalkStatus.idle) {
      return const SizedBox.shrink();
    }

    // Indicador simples baseado no número de pontos (animado)
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF30D158).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF30D158),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '${session.points.length} pts',
            style: const TextStyle(
              color: Color(0xFF30D158),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
