import 'package:flutter/material.dart';
import 'package:soloforte_app/core/domain/cultura_tipo.dart';

/// Cultura (chips) + material livre, usados no talhão do mapa.
class CulturaMaterialFields extends StatelessWidget {
  const CulturaMaterialFields({
    super.key,
    required this.selectedTipo,
    required this.culturaLivreController,
    required this.materialController,
    required this.onTipoSelected,
    this.materialSuggestions = const [],
    this.accent = const Color(0xFF248A3D),
  });

  final CulturaTipo? selectedTipo;
  final TextEditingController culturaLivreController;
  final TextEditingController materialController;
  final ValueChanged<CulturaTipo> onTipoSelected;
  final List<String> materialSuggestions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final showLivre = selectedTipo == CulturaTipo.outro;
    final showMaterial = selectedTipo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cultura',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tipo in CulturaTipo.values)
              _CulturaChip(
                label: tipo.label,
                selected: selectedTipo == tipo,
                accent: accent,
                onTap: () => onTipoSelected(tipo),
              ),
          ],
        ),
        if (showLivre) ...[
          const SizedBox(height: 10),
          TextField(
            controller: culturaLivreController,
            decoration: const InputDecoration(
              labelText: 'Qual cultura?',
              hintText: 'Ex.: Girassol',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        if (showMaterial) ...[
          const SizedBox(height: 16),
          Text(
            'Material',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: materialController,
            decoration: const InputDecoration(hintText: 'Ex.: Olimpo RR'),
            textCapitalization: TextCapitalization.words,
          ),
          if (materialSuggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final suggestion in materialSuggestions.take(8))
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () {
                      materialController.text = suggestion;
                    },
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _CulturaChip extends StatelessWidget {
  const _CulturaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? accent : Colors.grey[200],
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Valor persistido no talhão a partir da seleção de chips.
String? persistCulturaValue({
  required CulturaTipo? selectedTipo,
  required String culturaLivre,
}) {
  if (selectedTipo == null) return null;
  if (selectedTipo == CulturaTipo.outro) {
    final trimmed = culturaLivre.trim();
    return trimmed.isEmpty ? 'Outra' : trimmed;
  }
  return selectedTipo.label;
}
