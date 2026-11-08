import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/marketing_roi_calculation.dart';

/// Seção read-only de Resultado/ROI no sheet do pin (hierarquia hero + linhas).
class MarketingCaseResultadoReadOnlySection extends StatelessWidget {
  final MarketingCase marketingCase;
  final bool isIos;

  const MarketingCaseResultadoReadOnlySection({
    super.key,
    required this.marketingCase,
    this.isIos = false,
  });

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _formatSigned(double value) {
    final formatted = _formatNumber(value);
    return value >= 0 ? '+$formatted' : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final roi = marketingCase.computeRoi();
    if (roi == null) return const SizedBox.shrink();
    final MarketingRoiCalculation calc = roi;
    final input = calc.input;
    final v = SoloForteSheetVisuals.of(context);

    final heroBg = isIos
        ? v.cardBackground
        : const Color(0xFF123D2A);
    final heroRadius =
        v.cardRadius;
    final heroLabelColor = isIos
        ? v.subtitleColor
        : const Color(0xCCFFFFFF);
    final heroValueColor = isIos
        ? v.iconStroke
        : context.themeAccent;
    final heroSubColor = isIos
        ? v.titleColor
        : const Color(0xCCFFFFFF);

    final detailBg = v.cardBackground;
    final detailBorder = v.cardBorder;
    final sectionLabelColor = v.subtitleColor;
    final lineLabelColor = v.subtitleColor;
    final lineValueColor = v.titleColor;
    final gainColor = isIos
        ? v.iconStroke
        : context.themeAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: heroBg,
            borderRadius: BorderRadius.circular(heroRadius),
            border: Border.all(
              color: isIos
                  ? v.cardBorder
                  : context.themeAccent.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ROI líquido',
                style: TextStyle(
                  color: heroLabelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatMoney(calc.roiLiquidoRsHa)}/ha',
                style: TextStyle(
                  color: heroValueColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatNumber(calc.roiEmSacasHa)} sc/ha',
                style: TextStyle(
                  color: heroSubColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: detailBg,
            borderRadius: BorderRadius.circular(
              v.cardRadius,
            ),
            border: Border.all(color: detailBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRODUTIVIDADE',
                style: TextStyle(
                  color: sectionLabelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _SheetRoiLine(
                label: 'Testemunha',
                value:
                    '${_formatNumber(input.prodSemProduto)} ${input.unidadeProdutividade}',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
              _SheetRoiLine(
                label: 'Com produto',
                value:
                    '${_formatNumber(input.prodComProduto)} ${input.unidadeProdutividade}',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
              _SheetRoiLine(
                label: 'Ganho',
                value:
                    '${_formatSigned(calc.ganhoScHa)} ${input.unidadeProdutividade}',
                valueColor: gainColor,
                labelColor: lineLabelColor,
              ),
              const SizedBox(height: 8),
              Text(
                'ROI / RETORNO',
                style: TextStyle(
                  color: sectionLabelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _SheetRoiLine(
                label: 'Custo do produto',
                value: '${_formatMoney(input.custoProdutoPorHa)}/ha',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
              _SheetRoiLine(
                label: 'Valor do grão',
                value: '${_formatMoney(input.valorGrao)}/sc',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
              if (calc.roiSacasTalhao != null && calc.roiReaisTalhao != null)
                _SheetRoiLine(
                  label:
                      'No talhão (${marketingCase.tamanhoHa!.toStringAsFixed(1)} ha)',
                  value:
                      '${_formatNumber(calc.roiSacasTalhao!)} sc · ${_formatMoney(calc.roiReaisTalhao!)}',
                  labelColor: lineLabelColor,
                  valueColor: lineValueColor,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetRoiLine extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? labelColor;

  const _SheetRoiLine({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor ?? v.inputHint,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? v.inputText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
