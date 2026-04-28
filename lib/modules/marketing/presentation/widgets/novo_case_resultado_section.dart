import 'package:flutter/material.dart';
import '../widgets/foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';

/// Seção de campos para o tipo [CaseTipo.resultado].
/// Recebe controllers e callbacks — estado permanece no _NovoCaseSheetState.
class NovoCaseResultadoSection extends StatelessWidget {
  final String? fotoPrincipalUrl;
  final void Function(String?) onFotoChanged;
  final TextEditingController qtdProduzidaCtrl;
  final TextEditingController economiaCtrl;

  const NovoCaseResultadoSection({
    super.key,
    required this.fotoPrincipalUrl,
    required this.onFotoChanged,
    required this.qtdProduzidaCtrl,
    required this.economiaCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const SizedBox(height: 16),
        novoCaseSectionLabel('Dados do Resultado'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              novoCaseTextInput(
                qtdProduzidaCtrl,
                'Quantidade Produzida *',
                keyboardType: TextInputType.number,
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
        const SizedBox(height: 20),
      ],
    );
  }
}
