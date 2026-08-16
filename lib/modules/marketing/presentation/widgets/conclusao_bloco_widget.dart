import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';

/// Bloco de Conclusão Técnica — fundo #0057FF
/// Apenas 1 por case
class ConclusaoBlocoWidget extends StatelessWidget {
  final TextEditingController conclusaoCtrl;
  final VoidCallback onRemove;

  const ConclusaoBlocoWidget({
    super.key,
    required this.conclusaoCtrl,
    required this.onRemove,
  });

  static const Color _blueConc = Color(0xFF0057FF);

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final accent =
        isIos ? SoloForteSheetSkinIos.iconStroke : _blueConc;
    final shellBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : _blueConc.withValues(alpha: 0.06);
    final shellBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : _blueConc.withValues(alpha: 0.35);
    final headerBg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : _blueConc;
    final headerFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final headerFgMuted = isIos
        ? SoloForteSheetSkinIos.ctaText.withValues(alpha: 0.7)
        : Colors.white70;
    final fill = isIos
        ? SoloForteSheetSkinIos.background
        : Colors.white;
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : null;
    final hintColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : _blueConc.withValues(alpha: 0.5);
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: shellBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: shellBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(radius - 2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.notes_rounded, color: headerFg, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conclusão Técnica',
                    style: TextStyle(
                      color: headerFg,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onRemove();
                  },
                  child: Icon(
                    Icons.close,
                    color: headerFgMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),

          // ── Textarea ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: conclusaoCtrl,
              maxLines: 5,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: textColor,
              ),
              decoration: InputDecoration(
                hintText:
                    'Escreva sua conclusão técnica sobre o resultado do produto neste talhão...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: hintColor,
                  height: 1.5,
                ),
                filled: true,
                fillColor: fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: accent.withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: accent.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
