// Indicador visual glass: modo armado ocorrência.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../providers/map_armed_mode_provider.dart';

/// Banner glass para [ArmedMode.occurrences].
/// Posicionado no topo; ignora ponteiro (IgnorePointer).
class ArmedModeBanner extends ConsumerWidget {
  const ArmedModeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final armedMode = ref.watch(armedModeProvider);
    if (armedMode != ArmedMode.occurrences) return const SizedBox.shrink();

    const label = 'Toque no mapa para marcar o ponto';
    const accent = Color(0xFFFF9F0A);

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
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(SFIcons.pinFill, color: accent, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: context.premiumTextPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.2,
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
