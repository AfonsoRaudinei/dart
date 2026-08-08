// ADR-030 F2 — Banner de modo armado (ocorrência / marketing).
// Visual alinhado ao glass do VisitActiveCard / PremiumGlassPanel.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../providers/map_armed_mode_provider.dart';

/// Banner efêmero no topo quando o mapa espera um toque para posicionar
/// ocorrência ou case de marketing. [IgnorePointer] — não bloqueia gestos.
class ArmedModeBanner extends ConsumerWidget {
  const ArmedModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final armedMode = ref.watch(armedModeProvider);
    final spec = _ArmedBannerSpec.from(armedMode);
    if (spec == null) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        offset: Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: spec.accent.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(spec.icon, size: 16, color: spec.accent),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          spec.message,
                          style: TextStyle(
                            color: context.premiumTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ArmedBannerSpec {
  const _ArmedBannerSpec({
    required this.message,
    required this.icon,
    required this.accent,
  });

  final String message;
  final IconData icon;
  final Color accent;

  static _ArmedBannerSpec? from(ArmedMode mode) {
    switch (mode) {
      case ArmedMode.occurrences:
        return const _ArmedBannerSpec(
          message: 'Toque no mapa para marcar a ocorrência',
          icon: SFIcons.pinFill,
          accent: Color(0xFFFF9F0A), // iOS system orange
        );
      case ArmedMode.marketing:
        return const _ArmedBannerSpec(
          message: 'Toque no mapa para localizar o case',
          icon: SFIcons.pinFill,
          accent: PremiumTokens.brandGreen,
        );
      case ArmedMode.none:
        return null;
    }
  }
}
