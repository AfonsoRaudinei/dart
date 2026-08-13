import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/marketing_roi_calculation.dart';

/// Seção read-only de Resultado/ROI no sheet do pin (hierarquia hero + linhas).
class MarketingCaseResultadoReadOnlySection extends StatelessWidget {
  final MarketingCase marketingCase;

  const MarketingCaseResultadoReadOnlySection({
    super.key,
    required this.marketingCase,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF123D2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PremiumTokens.brandGreen.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ROI líquido',
                style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatMoney(calc.roiLiquidoRsHa)}/ha',
                style: const TextStyle(
                  color: PremiumTokens.brandGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatNumber(calc.roiEmSacasHa)} sc/ha',
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
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
            color: SoloForteSheetTokens.inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SoloForteSheetTokens.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRODUTIVIDADE',
                style: TextStyle(
                  color: SoloForteSheetTokens.inputHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _SheetRoiLine(
                label: 'Testemunha',
                value:
                    '${_formatNumber(input.prodSemProduto)} ${input.unidadeProdutividade}',
              ),
              _SheetRoiLine(
                label: 'Com produto',
                value:
                    '${_formatNumber(input.prodComProduto)} ${input.unidadeProdutividade}',
              ),
              _SheetRoiLine(
                label: 'Ganho',
                value:
                    '${_formatSigned(calc.ganhoScHa)} ${input.unidadeProdutividade}',
                valueColor: PremiumTokens.brandGreen,
              ),
              const SizedBox(height: 8),
              const Text(
                'ROI / RETORNO',
                style: TextStyle(
                  color: SoloForteSheetTokens.inputHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _SheetRoiLine(
                label: 'Custo do produto',
                value: '${_formatMoney(input.custoProdutoPorHa)}/ha',
              ),
              _SheetRoiLine(
                label: 'Valor do grão',
                value: '${_formatMoney(input.valorGrao)}/sc',
              ),
              if (calc.roiSacasTalhao != null && calc.roiReaisTalhao != null)
                _SheetRoiLine(
                  label:
                      'No talhão (${marketingCase.tamanhoHa!.toStringAsFixed(1)} ha)',
                  value:
                      '${_formatNumber(calc.roiSacasTalhao!)} sc · ${_formatMoney(calc.roiReaisTalhao!)}',
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

  const _SheetRoiLine({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SoloForteSheetTokens.inputHint,
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
                color: valueColor ?? SoloForteSheetTokens.inputText,
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
