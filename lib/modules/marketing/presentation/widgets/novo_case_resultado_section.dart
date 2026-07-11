import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
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
            dropdownColor: SoloForteSheetTokens.inputBackground,
            onChanged: (value) {
              if (value == null) return;
              onUnidadeChanged(value);
            },
            items: ProdutividadeUnidade.values.map((item) {
              return DropdownMenuItem<ProdutividadeUnidade>(
                value: item,
                child: Text(
                  item.toValue(),
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

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
    final input = _input;
    if (input == null || !input.isComplete) return const SizedBox.shrink();
    final roi = MarketingRoiCalculation(input);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF123D2A),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
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
            const Text(
              'ROI Calculado',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _RoiLine(
              label: 'Ganho',
              value: '${_signed(roi.ganhoScHa)} ${input.unidadeProdutividade}',
            ),
            _RoiLine(
              label: 'ROI líquido',
              value: '${_money(roi.roiLiquidoRsHa)} / ha',
            ),
            if (roi.roiSacasTalhao != null && roi.roiReaisTalhao != null)
              _RoiLine(
                label: 'No talhão (${tamanhoHa!.toStringAsFixed(1)} ha)',
                value:
                    '${_number(roi.roiSacasTalhao!)} sc · ${_money(roi.roiReaisTalhao!)}',
              ),
            if (roi.roiSacasTotal != null && roi.roiReaisTotal != null) ...[
              _RoiLine(
                label:
                    'Estimativa área total (${areaTotal!.toStringAsFixed(1)} ha)',
                value:
                    '${_number(roi.roiSacasTotal!)} sc · ${_money(roi.roiReaisTotal!)}',
              ),
              const SizedBox(height: 6),
              const Text(
                'Estimativa baseada na área total do produtor.',
                style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12),
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

  const _RoiLine({required this.label, required this.value});

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
              style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
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
