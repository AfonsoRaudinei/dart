import 'package:flutter/material.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

/// Área / perímetro no sheet de revisão antes de salvar o desenho.
class DrawingReviewMetricsPanel extends StatelessWidget {
  final String areaLabel;
  final String perimeterLabel;
  final bool isIos;
  final Color panelBg;
  final Color panelBorder;

  const DrawingReviewMetricsPanel({
    super.key,
    required this.areaLabel,
    required this.perimeterLabel,
    required this.isIos,
    required this.panelBg,
    required this.panelBorder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metricValueColor = scheme.onSurface;
    final metricLabelColor = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.72),
      scheme.surface,
    );
    final iconColor = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricColumn(
            icon: Icons.aspect_ratio,
            value: areaLabel,
            label: 'Área',
            iconColor: iconColor,
            valueColor: metricValueColor,
            labelColor: metricLabelColor,
          ),
          Container(width: 1, height: 40, color: panelBorder),
          _MetricColumn(
            icon: Icons.straighten,
            value: perimeterLabel,
            label: 'Perímetro',
            iconColor: iconColor,
            valueColor: metricValueColor,
            labelColor: metricLabelColor,
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color valueColor;
  final Color labelColor;

  const _MetricColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.valueColor,
    required this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
