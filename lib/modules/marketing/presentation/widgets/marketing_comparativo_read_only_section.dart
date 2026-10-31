import 'package:flutter/material.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'comparativo_chart.dart';

class MarketingComparativoReadOnlySection extends StatefulWidget {
  final List<ParametroComparativo> parametros;
  final double mediaGanhoPercent;
  final bool isIos;

  const MarketingComparativoReadOnlySection({
    super.key,
    required this.parametros,
    required this.mediaGanhoPercent,
    this.isIos = false,
  });

  @override
  State<MarketingComparativoReadOnlySection> createState() =>
      _MarketingComparativoReadOnlySectionState();
}

class _MarketingComparativoReadOnlySectionState
    extends State<MarketingComparativoReadOnlySection> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isIos
        ? SoloForteSheetSkinIos.cardBackground
        : SoloForteSheetTokens.inputBackground;
    final cardBorder = widget.isIos
        ? SoloForteSheetSkinIos.cardBorder
        : PremiumTokens.hairlineLight;
    final sectionLabelColor = widget.isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final titleColor = widget.isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(
              widget.isIos ? SoloForteSheetSkinIos.cardRadius : 16,
            ),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PARÂMETROS COMPARATIVOS',
                style: TextStyle(
                  color: sectionLabelColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Média de ganho: ${_formatSigned(widget.mediaGanhoPercent)}%',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.parametros.map(
                (parametro) => _ParametroReadOnlyRow(
                  parametro: parametro,
                  isIos: widget.isIos,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ComparativoChart(
          parametros: widget.parametros,
          selecionadoId: _selectedId,
          onSelect: (id) => setState(() => _selectedId = id),
        ),
      ],
    );
  }

  static String _formatSigned(double value) {
    final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
    return value >= 0 ? '+$formatted' : formatted;
  }
}

class _ParametroReadOnlyRow extends StatelessWidget {
  final ParametroComparativo parametro;
  final bool isIos;

  const _ParametroReadOnlyRow({
    required this.parametro,
    this.isIos = false,
  });

  @override
  Widget build(BuildContext context) {
    final unit = parametro.unidade == null || parametro.unidade!.isEmpty
        ? ''
        : ' ${parametro.unidade}';
    final delta = parametro.testemunha == 0
        ? '--'
        : '${parametro.deltaPercent >= 0 ? '+' : ''}${parametro.deltaPercent.toStringAsFixed(1).replaceAll('.', ',')}%';
    final deltaColor = parametro.isNegativo
        ? PremiumTokens.alertError
        : parametro.isPositivo
        ? (isIos ? SoloForteSheetSkinIos.iconStroke : PremiumTokens.brandGreen)
        : (isIos
              ? SoloForteSheetSkinIos.subtitleColor
              : SoloForteSheetTokens.inputHint);
    final textColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.inputText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parametro.titulo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${_formatValue(parametro.testemunha)} -> ${_formatValue(parametro.teste)}$unit',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            delta,
            style: TextStyle(
              color: deltaColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatValue(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }
}
