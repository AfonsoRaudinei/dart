import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/parametro_comparativo.dart';
import 'comparativo_chart.dart';
import '../widgets/foto_picker_widget.dart';
import 'novo_case_form_helpers.dart';
import 'parametro_card.dart';

/// Seção de campos para o tipo [CaseTipo.antesDepois].
/// Recebe controllers e callbacks — estado permanece no _NovoCaseSheetState.
class NovoCaseAntesDepoisSection extends StatelessWidget {
  final String? fotoAntesUrl;
  final String? fotoDepoisUrl;
  final void Function(String?) onFotoAntesChanged;
  final void Function(String?) onFotoDepoisChanged;
  final List<ParametroComparativo> parametros;
  final String? parametroSelecionadoId;
  final VoidCallback onAddParametro;
  final ValueChanged<String?> onSelectParametro;
  final ValueChanged<ParametroComparativo> onParametroChanged;
  final ValueChanged<String> onDeleteParametro;

  const NovoCaseAntesDepoisSection({
    super.key,
    required this.fotoAntesUrl,
    required this.fotoDepoisUrl,
    required this.onFotoAntesChanged,
    required this.onFotoDepoisChanged,
    required this.parametros,
    required this.parametroSelecionadoId,
    required this.onAddParametro,
    required this.onSelectParametro,
    required this.onParametroChanged,
    required this.onDeleteParametro,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        novoCaseSectionLabel('Parâmetros Comparativos'),
        const SizedBox(height: 8),
        ...parametros.map(
          (parametro) => ParametroCard(
            key: ValueKey(parametro.id),
            parametro: parametro,
            selected: parametroSelecionadoId == parametro.id,
            onChanged: onParametroChanged,
            onDelete: () => onDeleteParametro(parametro.id),
            onTap: () => onSelectParametro(
              parametroSelecionadoId == parametro.id ? null : parametro.id,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onAddParametro,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Adicionar Parâmetro'),
          style: OutlinedButton.styleFrom(
            foregroundColor: SoloForteSheetTokens.inputText,
            side: const BorderSide(color: PremiumTokens.hairlineLight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 16),
        if (parametros.isNotEmpty) ...[
          novoCaseSectionLabel('Resultado Geral'),
          const SizedBox(height: 8),
          ComparativoChart(
            parametros: parametros,
            selecionadoId: parametroSelecionadoId,
            onSelect: onSelectParametro,
          ),
          const SizedBox(height: 16),
        ],
        novoCaseSectionLabel('Fotos'),
        const SizedBox(height: 8),
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
