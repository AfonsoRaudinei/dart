import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';

/// Bloco de ROI gerenciável — cálculo automático
/// ROI = ((retorno - investimento) / investimento) × 100
class RoiBlocoWidget extends StatefulWidget {
  final TextEditingController investimentoCtrl;
  final TextEditingController retornoCtrl;
  final VoidCallback onRemove;

  const RoiBlocoWidget({
    super.key,
    required this.investimentoCtrl,
    required this.retornoCtrl,
    required this.onRemove,
  });

  @override
  State<RoiBlocoWidget> createState() => _RoiBlocoWidgetState();
}

class _RoiBlocoWidgetState extends State<RoiBlocoWidget> {
  static const Color _roiGreen = Color(0xFF34C759);
  static const Color _fieldDark = Color(0xFF2C2C2E);
  static const Color _fieldBorder = Color(0xFF3A3A3C);

  double? get _roiCalculado {
    final inv = double.tryParse(
      widget.investimentoCtrl.text.replaceAll(',', '.'),
    );
    final ret = double.tryParse(widget.retornoCtrl.text.replaceAll(',', '.'));
    if (inv == null || ret == null || inv == 0) return null;
    return ((ret - inv) / inv) * 100;
  }

  @override
  void initState() {
    super.initState();
    widget.investimentoCtrl.addListener(_rebuild);
    widget.retornoCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.investimentoCtrl.removeListener(_rebuild);
    widget.retornoCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final roi = _roiCalculado;
    final accent = isIos ? SoloForteSheetSkinIos.iconStroke : _roiGreen;
    final shellBg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : _roiGreen.withValues(alpha: 0.07);
    final shellBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : _roiGreen.withValues(alpha: 0.4);
    final headerBg =
        isIos ? SoloForteSheetSkinIos.ctaBackground : _roiGreen;
    final headerFg =
        isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final headerFgMuted = isIos
        ? SoloForteSheetSkinIos.ctaText.withValues(alpha: 0.7)
        : Colors.white70;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;

    return Container(
      decoration: BoxDecoration(
        color: shellBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: shellBorder, width: 1.5),
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
                Icon(
                  Icons.trending_up_rounded,
                  color: headerFg,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bloco de ROI',
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
                    widget.onRemove();
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

          // ── Inputs ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        widget.investimentoCtrl,
                        'Investimento (R\$)',
                        isIos: isIos,
                        prefixIcon: Icons.arrow_downward_rounded,
                        prefixColor: Colors.red.shade400,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        widget.retornoCtrl,
                        'Retorno (R\$)',
                        isIos: isIos,
                        prefixIcon: Icons.arrow_upward_rounded,
                        prefixColor: accent,
                      ),
                    ),
                  ],
                ),

                // ── Resultado do ROI ─────────────────────────────
                if (roi != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: headerBg,
                      borderRadius: BorderRadius.circular(
                        isIos ? SoloForteSheetSkinIos.ctaRadius : 12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ROI Calculado',
                          style: TextStyle(
                            color: headerFg.withValues(alpha: 0.85),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${roi >= 0 ? '+' : ''}${roi.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: headerFg,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (widget.investimentoCtrl.text.isNotEmpty ||
                    widget.retornoCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Preencha ambos os campos para calcular o ROI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label, {
    required bool isIos,
    IconData? prefixIcon,
    Color? prefixColor,
  }) {
    final fieldBg =
        isIos ? SoloForteSheetSkinIos.cardBackground : _fieldDark;
    final fieldBorder =
        isIos ? SoloForteSheetSkinIos.cardBorder : _fieldBorder;
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.black87;
    final hintColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.black38;
    final fillColor =
        isIos ? SoloForteSheetSkinIos.background : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: fieldBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(
              prefixIcon,
              size: 14,
              color: prefixColor ??
                  (isIos ? SoloForteSheetSkinIos.iconStroke : _roiGreen),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: label,
                hintStyle: TextStyle(fontSize: 12, color: hintColor),
                filled: true,
                fillColor: fillColor,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
