import 'package:flutter/material.dart';

import '../../theme/premium/design_tokens.dart';
import '../../../../core/design/sf_icons.dart';

// ════════════════════════════════════════════════════════════════════
// MODELS AUXILIARES (ESTÁGIOS)
// ════════════════════════════════════════════════════════════════════

enum EstagioTipo { vegetativo, reprodutivo }

class EstagioSoja {
  final String codigo;
  final String nome;
  final String descricao;
  final String emoji;
  final String dapEsperado;
  final EstagioTipo tipo;
  final List<String> alertas;

  const EstagioSoja({
    required this.codigo,
    required this.nome,
    required this.descricao,
    required this.emoji,
    required this.dapEsperado,
    required this.tipo,
    required this.alertas,
  });
}

const List<EstagioSoja> estagiosSoja = [
  EstagioSoja(
    codigo: 'VE',
    nome: 'Emergência',
    descricao: 'Cotilédones acima do solo',
    emoji: '🌱',
    dapEsperado: '5–7 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar tombamento', 'Verificar estande'],
  ),
  EstagioSoja(
    codigo: 'VC',
    nome: 'Cotilédones',
    descricao: 'Cotilédones completamente abertos',
    emoji: '🌿',
    dapEsperado: '7–10 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Iniciar monitoramento de pragas', 'Verificar nodulação'],
  ),
  EstagioSoja(
    codigo: 'V1',
    nome: '1ª Trifoliolada',
    descricao: 'Primeiro nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '10–14 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitoramento de percevejos', 'Deficiência de ferro'],
  ),
  EstagioSoja(
    codigo: 'V2',
    nome: '2ª Trifoliolada',
    descricao: 'Segundo nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '14–20 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar lagarta-da-soja', 'Herbicida pós-emergente'],
  ),
  EstagioSoja(
    codigo: 'V3',
    nome: '3ª Trifoliolada',
    descricao: 'Terceiro nó com folha trifoliolada',
    emoji: '🍃',
    dapEsperado: '20–28 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Monitorar oídio', 'Deficiência de manganês'],
  ),
  EstagioSoja(
    codigo: 'V4',
    nome: '4ª Trifoliolada',
    descricao: 'Quarto nó com folha trifoliolada',
    emoji: '🌳',
    dapEsperado: '28–35 dias',
    tipo: EstagioTipo.vegetativo,
    alertas: ['Tripes e mosca-branca', 'Herbicida antes de V5'],
  ),
  EstagioSoja(
    codigo: 'Rn',
    nome: 'Início do Florescimento',
    descricao: 'Uma flor aberta em qualquer nó',
    emoji: '🌸',
    dapEsperado: '45–55 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: [
      'Pico de demanda hídrica',
      'Ferrugem asiática',
      'Percevejo-marrom',
    ],
  ),
  EstagioSoja(
    codigo: 'R2',
    nome: 'Floração Plena',
    descricao: 'Flor aberta nos nós superiores',
    emoji: '🌺',
    dapEsperado: '50–60 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Mancha alvo e antracnose', 'Cuidado com abelhas'],
  ),
  EstagioSoja(
    codigo: 'R3',
    nome: 'Vagens com 1 cm',
    descricao: 'Vagem com 1 cm nos 4 nós superiores',
    emoji: '🫛',
    dapEsperado: '55–65 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Percevejo reduz enchimento', 'Lagarta-da-soja'],
  ),
  EstagioSoja(
    codigo: 'R4',
    nome: 'Vagens com 2 cm',
    descricao: 'Vagem com 2 cm nos 4 nós superiores',
    emoji: '🫛',
    dapEsperado: '60–70 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Monitorar percevejo com rigor', 'Inseticida se > 2/pano'],
  ),
  EstagioSoja(
    codigo: 'R5',
    nome: 'Enchimento de Grãos',
    descricao: 'Grão perceptível ao tato',
    emoji: '🌾',
    dapEsperado: '65–80 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Máxima demanda hídrica', 'Dano irreversível de percevejo'],
  ),
  EstagioSoja(
    codigo: 'R6',
    nome: 'Grãos Formados',
    descricao: 'Grãos preenchem a cavidade',
    emoji: '🟡',
    dapEsperado: '100–110 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Deiscência precoce', 'Evitar aplicações'],
  ),
  EstagioSoja(
    codigo: 'R7',
    nome: 'Início Maturação',
    descricao: 'Vagem com cor de maturação',
    emoji: '🟠',
    dapEsperado: '110–120 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Uniformidade de maturação', 'Estimar colheita'],
  ),
  EstagioSoja(
    codigo: 'R8',
    nome: 'Maturação Plena',
    descricao: '95% das vagens maduras',
    emoji: '🟤',
    dapEsperado: '120–135 dias',
    tipo: EstagioTipo.reprodutivo,
    alertas: ['Ponto de colheita', 'Umidade ideal 14%'],
  ),
];

// ════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ════════════════════════════════════════════════════════════════════

class SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SectionCard({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.premiumSurface,
        borderRadius: BorderRadius.circular(12),
        // boxShadow: PremiumTokens.tightShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.premiumTextSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class FormFieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const FormFieldRow({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.premiumTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class DapBadge extends StatelessWidget {
  final int dap;

  const DapBadge({super.key, required this.dap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dap > 0
            ? PremiumTokens.brandGreen.withValues(alpha: 0.1)
            : context.premiumBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dap > 0
              ? PremiumTokens.brandGreen.withValues(alpha: 0.3)
              : context.premiumHairline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DAP: ',
            style: TextStyle(
              fontSize: 12,
              color: context.premiumTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$dap dias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: dap > 0
                  ? PremiumTokens.brandGreen
                  : context.premiumTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class StageSelector extends StatelessWidget {
  final String? selectedStageCode;
  final ValueChanged<String?> onChanged;

  const StageSelector({
    super.key,
    required this.selectedStageCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedStageCode),
      isExpanded: true,
      initialValue: selectedStageCode,
      decoration: InputDecoration(
        filled: true,
        fillColor: context.premiumBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(
        'Selecione o estádio',
        style: TextStyle(color: context.premiumTextTertiary),
      ),
      items: estagiosSoja.map((stage) {
        return DropdownMenuItem(
          value: stage.codigo,
          child: Row(
            children: [
              Text(stage.emoji),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${stage.codigo} - ${stage.nome}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<String> onToggle;
  final Map<String, int> photoCounts;

  const CategoryGrid({
    super.key,
    required this.selectedCategories,
    required this.onToggle,
    this.photoCounts = const {},
  });

  static const categories = [
    {'id': 'doenca', 'label': 'Doenças', 'icon': SFIcons.warning},
    {'id': 'insetos', 'label': 'Pragas', 'icon': SFIcons.bugReport},
    {'id': 'ervas', 'label': 'Daninhas', 'icon': SFIcons.grass},
    {'id': 'nutrientes', 'label': 'Nutrição', 'icon': SFIcons.science},
    {'id': 'fisiologico', 'label': 'Fisiológico', 'icon': SFIcons.waterDrop},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: categories.map((cat) {
        final id = cat['id'] as String;
        final isSelected = selectedCategories.contains(id);
        final count = photoCounts[id] ?? 0;
        return GestureDetector(
          onTap: () => onToggle(id),
          child: Container(
            width:
                (MediaQuery.of(context).size.width - 80) / 3, // 3 cols approx
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? PremiumTokens.brandGreen : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? PremiumTokens.brandGreen
                    : context.premiumHairline,
              ),
              boxShadow: [
                if (!isSelected)
                  const BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: isSelected
                      ? Colors.white
                      : context.premiumTextPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : context.premiumTextPrimary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : context.premiumBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count 📷',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : context.premiumTextSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
