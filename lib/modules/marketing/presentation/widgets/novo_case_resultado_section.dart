import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../domain/entities/marketing_roi_calculation.dart';
import '../../domain/enums/produtividade_unidade.dart';
import '../widgets/foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';

/// Seção de campos para o tipo [CaseTipo.resultado].
/// Recebe controllers e callbacks — estado permanece no _NovoCaseSheetState.
class NovoCaseResultadoSection extends StatelessWidget {
  final String? fotoPrincipalUrl;
  final void Function(String?) onFotoChanged;
  final TextEditingController prodSemProdutoCtrl;
  final TextEditingController prodComProdutoCtrl;
  final TextEditingController custoProdutoPorHaCtrl;
  final TextEditingController valorGraoCtrl;
  final ProdutividadeUnidade unidade;
  final double? tamanhoHa;
  final double? areaTotal;
  final ValueChanged<ProdutividadeUnidade> onUnidadeChanged;
  final VoidCallback onRoiChanged;

  const NovoCaseResultadoSection({
    super.key,
    required this.fotoPrincipalUrl,
    required this.onFotoChanged,
    required this.prodSemProdutoCtrl,
    required this.prodComProdutoCtrl,
    required this.custoProdutoPorHaCtrl,
    required this.valorGraoCtrl,
    required this.unidade,
    required this.tamanhoHa,
    required this.areaTotal,
    required this.onUnidadeChanged,
    required this.onRoiChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        novoCaseSectionLabel('Produtividade'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              _RoiInputRow(
                controller: prodSemProdutoCtrl,
                label: 'Produção Testemunha (sem produto) *',
                unidade: unidade,
                onUnidadeChanged: onUnidadeChanged,
                onChanged: onRoiChanged,
              ),
              const NovoCaseFDivider(),
              _RoiInputRow(
                controller: prodComProdutoCtrl,
                label: 'Produção com Produto *',
                unidade: unidade,
                onUnidadeChanged: onUnidadeChanged,
                onChanged: onRoiChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        novoCaseSectionLabel('Custo & Mercado'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              novoCaseTextInput(
                custoProdutoPorHaCtrl,
                'Custo do produto (R\$/ha) *',
                keyboardType: TextInputType.number,
                required: true,
                onChanged: (_) => onRoiChanged(),
              ),
              const NovoCaseFDivider(),
              novoCaseTextInput(
                valorGraoCtrl,
                'Valor do grão (R\$/sc) *',
                keyboardType: TextInputType.number,
                required: true,
                onChanged: (_) => onRoiChanged(),
              ),
            ],
          ),
        ),
        _RoiPreviewCard(
          prodSemProdutoCtrl: prodSemProdutoCtrl,
          prodComProdutoCtrl: prodComProdutoCtrl,
          custoProdutoPorHaCtrl: custoProdutoPorHaCtrl,
          valorGraoCtrl: valorGraoCtrl,
          unidade: unidade,
          tamanhoHa: tamanhoHa,
          areaTotal: areaTotal,
        ),
        const SizedBox(height: 16),
        novoCaseSectionLabel('Foto Principal *'),
        const SizedBox(height: 8),
        FotoPickerWidget(
          label: 'Foto do Resultado (obrigatória)',
          url: fotoPrincipalUrl,
          folder: 'resultado',
          height: 180,
          required: fotoPrincipalUrl == null,
          onChanged: onFotoChanged,
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _RoiInputRow extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ProdutividadeUnidade unidade;
  final ValueChanged<ProdutividadeUnidade> onUnidadeChanged;
  final VoidCallback onChanged;

  const _RoiInputRow({
    required this.controller,
    required this.label,
    required this.unidade,
    required this.onUnidadeChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final dropdownBg = v.cardBackground;
    final dropdownFg = v.titleColor;

    return Row(
      children: [
        Expanded(
          child: novoCaseTextInput(
            controller,
            label,
            keyboardType: TextInputType.number,
            required: true,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButtonHideUnderline(
          child: DropdownButton<ProdutividadeUnidade>(
            value: unidade,
            dropdownColor: dropdownBg,
            style: TextStyle(fontSize: 13, color: dropdownFg),
            iconEnabledColor: v.subtitleColor,
            onChanged: (value) {
              if (value == null) return;
              onUnidadeChanged(value);
            },
            items: ProdutividadeUnidade.values.map((item) {
              return DropdownMenuItem<ProdutividadeUnidade>(
                value: item,
                child: Text(
                  item.toValue(),
                  style: TextStyle(fontSize: 13, color: dropdownFg),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Texto sobre fundo pinado [#123D2A] no tema Verde (fora do Azul).
const _roiOnDarkPrimary = Color(0xFFFFFFFF);
const _roiOnDarkLabel = Color(0xCCFFFFFF);

class _RoiPreviewCard extends StatelessWidget {
  final TextEditingController prodSemProdutoCtrl;
  final TextEditingController prodComProdutoCtrl;
  final TextEditingController custoProdutoPorHaCtrl;
  final TextEditingController valorGraoCtrl;
  final ProdutividadeUnidade unidade;
  final double? tamanhoHa;
  final double? areaTotal;

  const _RoiPreviewCard({
    required this.prodSemProdutoCtrl,
    required this.prodComProdutoCtrl,
    required this.custoProdutoPorHaCtrl,
    required this.valorGraoCtrl,
    required this.unidade,
    required this.tamanhoHa,
    required this.areaTotal,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final input = _input;
    if (input == null || !input.isComplete) return const SizedBox.shrink();
    final roi = MarketingRoiCalculation(input);
    final isIos = v.isIos;
    final cardBg = isIos
        ? v.cardBackground
        : const Color(0xFF123D2A);
    final titleColor = isIos ? v.titleColor : _roiOnDarkPrimary;
    final lineLabelColor =
        isIos ? v.subtitleColor : _roiOnDarkLabel;
    final lineValueColor = isIos ? v.titleColor : _roiOnDarkPrimary;
    final radius = v.cardRadius;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(radius),
          border: isIos
              ? Border.all(color: v.cardBorder)
              : null,
          boxShadow: isIos
              ? null
              : const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.08),
                    offset: Offset(0, 10),
                    blurRadius: 32,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ROI Calculado',
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _RoiLine(
              label: 'Ganho',
              value: '${_signed(roi.ganhoScHa)} ${input.unidadeProdutividade}',
              labelColor: lineLabelColor,
              valueColor: lineValueColor,
            ),
            _RoiLine(
              label: 'ROI líquido',
              value: '${_money(roi.roiLiquidoRsHa)} / ha',
              labelColor: lineLabelColor,
              valueColor: lineValueColor,
            ),
            if (roi.roiSacasTalhao != null && roi.roiReaisTalhao != null)
              _RoiLine(
                label: 'No talhão (${tamanhoHa!.toStringAsFixed(1)} ha)',
                value:
                    '${_number(roi.roiSacasTalhao!)} sc · ${_money(roi.roiReaisTalhao!)}',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
            if (roi.roiSacasTotal != null && roi.roiReaisTotal != null) ...[
              _RoiLine(
                label:
                    'Estimativa área total (${areaTotal!.toStringAsFixed(1)} ha)',
                value:
                    '${_number(roi.roiSacasTotal!)} sc · ${_money(roi.roiReaisTotal!)}',
                labelColor: lineLabelColor,
                valueColor: lineValueColor,
              ),
              const SizedBox(height: 6),
              Text(
                'Estimativa baseada na área total do produtor.',
                style: TextStyle(color: lineLabelColor, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  MarketingRoiInput? get _input {
    final semProduto = _parse(prodSemProdutoCtrl.text);
    final comProduto = _parse(prodComProdutoCtrl.text);
    final custo = _parse(custoProdutoPorHaCtrl.text);
    final valor = _parse(valorGraoCtrl.text);
    if (semProduto == null ||
        comProduto == null ||
        custo == null ||
        valor == null) {
      return null;
    }
    return MarketingRoiInput(
      prodSemProduto: semProduto,
      prodComProduto: comProduto,
      unidadeProdutividade: unidade.toValue(),
      custoProdutoPorHa: custo,
      valorGrao: valor,
      tamanhoHa: tamanhoHa,
      areaTotal: areaTotal,
    );
  }

  static double? _parse(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _number(double value) {
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _signed(double value) {
    final formatted = _number(value);
    return value >= 0 ? '+$formatted' : formatted;
  }
}

class _RoiLine extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _RoiLine({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
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
              style: TextStyle(color: labelColor, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor,
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
