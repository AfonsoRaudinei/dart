import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../widgets/foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';

/// Seção de campos para o tipo [CaseTipo.antesDepois].
/// Recebe controllers e callbacks — estado permanece no _NovoCaseSheetState.
class NovoCaseAntesDepoisSection extends StatelessWidget {
  final String? fotoAntesUrl;
  final String? fotoDepoisUrl;
  final void Function(String?) onFotoAntesChanged;
  final void Function(String?) onFotoDepoisChanged;
  final TextEditingController ganhoProdutividadeCtrl;
  final TextEditingController economiaCtrl;

  const NovoCaseAntesDepoisSection({
    super.key,
    required this.fotoAntesUrl,
    required this.fotoDepoisUrl,
    required this.onFotoAntesChanged,
    required this.onFotoDepoisChanged,
    required this.ganhoProdutividadeCtrl,
    required this.economiaCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        novoCaseSectionLabel('Comparação Antes/Depois'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              novoCaseTextInput(
                ganhoProdutividadeCtrl,
                'Ganho de Produtividade (ex: +38%) *',
                required: true,
              ),
              const NovoCaseFDivider(),
              novoCaseTextInput(
                economiaCtrl,
                'Economia Gerada (ex: R\$ 22.000)',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Antes *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: SoloForteSheetTokens.inputHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Antes',
                    url: fotoAntesUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: fotoAntesUrl == null,
                    onChanged: onFotoAntesChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Depois *',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: SoloForteSheetTokens.inputHint,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FotoPickerWidget(
                    label: 'Foto Depois',
                    url: fotoDepoisUrl,
                    folder: 'antes_depois',
                    height: 140,
                    required: fotoDepoisUrl == null,
                    onChanged: onFotoDepoisChanged,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
