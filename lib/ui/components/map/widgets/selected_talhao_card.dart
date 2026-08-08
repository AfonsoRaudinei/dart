import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Card glass do talhão selecionado no mapa (substitui SnackBar).
/// Idioma visual alinhado a [VisitActiveCard] / FieldView field chip.
class SelectedTalhaoCard extends ConsumerWidget {
  const SelectedTalhaoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedTalhaoIdProvider);
    if (selectedId == null) return const SizedBox.shrink();

    final fields = ref.watch(mapFieldsProvider).valueOrNull ?? const [];
    TalhaoSummary? match;
    for (final field in fields) {
      if (field.id == selectedId) {
        match = TalhaoSummary(
          name: field.name,
          areaHa: field.areaHa,
          crop: field.crop,
        );
        break;
      }
    }
    if (match == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.62,
      ),
      child: _GlassChip(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                SFIcons.pinFill,
                size: 14,
                color: PremiumTokens.brandGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    match.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.premiumTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    match.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.premiumTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(selectedTalhaoIdProvider.notifier).state = null;
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.premiumTextTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class TalhaoSummary {
  const TalhaoSummary({
    required this.name,
    required this.areaHa,
    required this.crop,
  });

  final String name;
  final double areaHa;
  final String crop;

  String get subtitle {
    final area = areaHa > 0 ? '${_formatHa(areaHa)} ha' : null;
    final culture = crop.trim().isEmpty ? null : crop.trim();
    if (area != null && culture != null) return '$area · $culture';
    if (area != null) return area;
    if (culture != null) return culture;
    return 'Talhão selecionado';
  }

  static String _formatHa(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.07),
                offset: Offset(0, 8),
                blurRadius: 28,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
