import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../widgets/avaliacao_bloco_widget.dart';
import '../widgets/conclusao_bloco_widget.dart';
import '../widgets/roi_bloco_widget.dart';
import 'novo_case_form_helpers.dart';

/// Seção de campos para o tipo [CaseTipo.avaliacao].
/// Inclui lista dinâmica de avaliações, ROI e conclusão.
/// Estado permanece no _NovoCaseSheetState — tudo via callbacks.
class NovoCaseAvaliacaoSection extends StatelessWidget {
  final List<AvaliacaoBlocoState> avaliacoes;
  final TextEditingController nomeTalhaoCtrl;
  final TextEditingController tamanhoHaCtrl;
  final bool hasRoi;
  final TextEditingController roiInvestimentoCtrl;
  final TextEditingController roiRetornoCtrl;
  final bool hasConclusao;
  final TextEditingController conclusaoCtrl;
  final VoidCallback onAddAvaliacao;
  final void Function(int) onRemoveAvaliacao;
  final VoidCallback onAddRoi;
  final VoidCallback onRemoveRoi;
  final VoidCallback onAddConclusao;
  final VoidCallback onRemoveConclusao;
  final VoidCallback onChanged;

  const NovoCaseAvaliacaoSection({
    super.key,
    required this.avaliacoes,
    required this.nomeTalhaoCtrl,
    required this.tamanhoHaCtrl,
    required this.hasRoi,
    required this.roiInvestimentoCtrl,
    required this.roiRetornoCtrl,
    required this.hasConclusao,
    required this.conclusaoCtrl,
    required this.onAddAvaliacao,
    required this.onRemoveAvaliacao,
    required this.onAddRoi,
    required this.onRemoveRoi,
    required this.onAddConclusao,
    required this.onRemoveConclusao,
    required this.onChanged,
  });

  Widget _buildAddBlocoButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        novoCaseSectionLabel('Dados do Talhão'),
        const SizedBox(height: 8),
        novoCaseFieldBox(
          child: Column(
            children: [
              novoCaseTextInput(
                nomeTalhaoCtrl,
                'Nome do Talhão *',
                required: true,
              ),
              const NovoCaseFDivider(),
              novoCaseTextInput(
                tamanhoHaCtrl,
                'Tamanho (ha)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (avaliacoes.isNotEmpty) ...[
          novoCaseSectionLabel('Avaliações (${avaliacoes.length})'),
          const SizedBox(height: 10),
          ...List.generate(avaliacoes.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AvaliacaoBlocoWidget(
                key: ValueKey(avaliacoes[i].id),
                state: avaliacoes[i],
                index: i,
                onRemove: () => onRemoveAvaliacao(i),
                onChanged: onChanged,
              ),
            );
          }),
        ],
        GestureDetector(
          onTap: onAddAvaliacao,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.5),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: PremiumTokens.brandGreen.withValues(alpha: 0.05),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: PremiumTokens.brandGreen,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  '+ Adicionar Avaliação',
                  style: TextStyle(
                    color: PremiumTokens.brandGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (!hasRoi)
          _buildAddBlocoButton(
            icon: Icons.trending_up_rounded,
            label: '+ Adicionar Bloco de ROI',
            color: const Color(0xFF34C759),
            onTap: onAddRoi,
          )
        else ...[
          RoiBlocoWidget(
            investimentoCtrl: roiInvestimentoCtrl,
            retornoCtrl: roiRetornoCtrl,
            onRemove: onRemoveRoi,
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        if (!hasConclusao)
          _buildAddBlocoButton(
            icon: Icons.notes_rounded,
            label: '+ Adicionar Conclusão Técnica',
            color: const Color(0xFF0057FF),
            onTap: onAddConclusao,
          )
        else
          ConclusaoBlocoWidget(
            conclusaoCtrl: conclusaoCtrl,
            onRemove: onRemoveConclusao,
          ),
        const SizedBox(height: 20),
      ],
    );
  }
}
