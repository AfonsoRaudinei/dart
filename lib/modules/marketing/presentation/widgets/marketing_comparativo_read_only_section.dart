import 'package:flutter/material.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'comparativo_chart.dart';

class MarketingComparativoReadOnlySection extends StatefulWidget {
  final List<ParametroComparativo> parametros;
  final double mediaGanhoPercent;

  const MarketingComparativoReadOnlySection({
    super.key,
    required this.parametros,
    required this.mediaGanhoPercent,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SoloForteSheetTokens.inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PremiumTokens.hairlineLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PARÂMETROS COMPARATIVOS',
                style: TextStyle(
                  color: PremiumTokens.textSecondaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Média de ganho: ${_formatSigned(widget.mediaGanhoPercent)}%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.parametros.map(
                (parametro) => _ParametroReadOnlyRow(parametro: parametro),
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

  const _ParametroReadOnlyRow({required this.parametro});

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
        ? PremiumTokens.brandGreen
        : PremiumTokens.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parametro.titulo,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${_formatValue(parametro.testemunha)} -> ${_formatValue(parametro.teste)}$unit',
            style: const TextStyle(fontSize: 12),
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
