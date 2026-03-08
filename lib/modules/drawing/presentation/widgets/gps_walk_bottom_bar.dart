import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';

/// Barra de ações inferior para o modo GPS Walk.
///
/// Adapta os botões exibidos conforme o [GpsWalkStatus]:
///
/// **idle:**
///   `[▶ Começar a medir]  [○ Adicionar ponto — desabilitado]`
///
/// **measuring (auto):**
///   `[⏸ Pausar]  [○ Adicionar ponto]  [✓ Concluído — se ≥ 3 pontos]`
///
/// **measuring (manual):**
///   `[○ Adicionar ponto]  [✓ Concluído — se ≥ 3 pontos]`
///
/// **paused:**
///   `[▶ Retomar]  [○ Adicionar ponto]  [✓ Concluído — se ≥ 3 pontos]`
///
/// Design: iOS Premium — botões pill, opacidade on-press.
class GpsWalkBottomBar extends ConsumerWidget {
  const GpsWalkBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);
    if (session == null || session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(gpsWalkProvider.notifier);
    final status = session.status;
    final isAutoMode = session.isAutoMode;
    final canFinish = session.canFinish;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Toggle Auto/Manual ──────────────────────────────────────────────
        if (status != GpsWalkStatus.idle) ...[
          _AutoModeToggle(
            isAutoMode: isAutoMode,
            onToggle: () {
              HapticFeedback.selectionClick();
              notifier.toggleAutoMode();
            },
          ),
          const SizedBox(height: 10),
        ],

        // ── Botões de ação ──────────────────────────────────────────────────
        Row(
          children: [
            // Começar / Pausar / Retomar
            if (status == GpsWalkStatus.idle)
              Expanded(
                child: _PrimaryButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Começar a medir',
                  color: const Color(0xFF30D158),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    notifier.startMeasuring();
                  },
                ),
              )
            else if (status == GpsWalkStatus.measuring && isAutoMode)
              _IconActionButton(
                icon: Icons.pause_rounded,
                label: 'Pausar',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.pause();
                },
              )
            else if (status == GpsWalkStatus.paused)
              _IconActionButton(
                icon: Icons.play_arrow_rounded,
                label: 'Retomar',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.resume();
                },
              ),

            if (status != GpsWalkStatus.idle) ...[
              const SizedBox(width: 8),

              // Adicionar ponto
              _IconActionButton(
                icon: Icons.add_location_alt_rounded,
                label: 'Add ponto',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.addManualPoint();
                },
              ),

              const SizedBox(width: 8),

              // Concluído
              Expanded(
                child: _PrimaryButton(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Concluído',
                  color: canFinish
                      ? const Color(0xFF34C759)
                      : Colors.white.withValues(alpha: 0.18),
                  enabled: canFinish,
                  onPressed: canFinish
                      ? () {
                          HapticFeedback.mediumImpact();
                          notifier.finish();
                        }
                      : null,
                ),
              ),
            ],

            if (status == GpsWalkStatus.idle) ...[
              const SizedBox(width: 8),
              const _IconActionButton(
                icon: Icons.add_location_alt_rounded,
                label: 'Add ponto',
                enabled: false,
                onPressed: null,
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // ── Cancelar ───────────────────────────────────────────────────────
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            notifier.cancel();
          },
          child: const Text(
            'Cancelar medição',
            style: TextStyle(
              color: Color(0xFFFF453A),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Componentes privados ─────────────────────────────────────────────────────

class _AutoModeToggle extends StatelessWidget {
  final bool isAutoMode;
  final VoidCallback onToggle;

  const _AutoModeToggle({required this.isAutoMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAutoMode
                  ? Icons.gps_fixed_rounded
                  : Icons.touch_app_rounded,
              color: isAutoMode
                  ? const Color(0xFF30D158)
                  : const Color(0xFFFFD60A),
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isAutoMode ? 'Modo GPS automático' : 'Modo manual (toque)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            // Pill toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: isAutoMode
                    ? const Color(0xFF30D158)
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Align(
                alignment:
                    isAutoMode ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  const _IconActionButton({
    required this.icon,
    required this.label,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.color,
    this.enabled = true,
    required this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.62 : (widget.enabled ? 1.0 : 0.38),
        duration: const Duration(milliseconds: 80),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(50),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
