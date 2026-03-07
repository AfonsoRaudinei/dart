import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import 'occurrence_fenologia_data.dart';

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES DE OccurrenceCreationSheet
// ════════════════════════════════════════════════════════════════════════════
// Extraídos para manter occurrence_creation_sheet.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)

// ── Cabeçalho de seção ────────────────────────────────────────────────────

class OccurrenceSectionHeader extends StatelessWidget {
  final String icon;
  final String title;

  const OccurrenceSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(color: Colors.white12)),
      ],
    );
  }
}

// ── Campo de texto estilo dark ────────────────────────────────────────────

class OccurrenceDarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLines;

  const OccurrenceDarkField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1C1C1E),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: PremiumTokens.brandGreen, width: 1.5),
        ),
      ),
    );
  }
}

// ── Linha de slider de intensidade ───────────────────────────────────────

class OccurrenceSliderRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const OccurrenceSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sliderColor(value).withOpacity(.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  kSliderLabels[value],
                  style: TextStyle(
                    color: _sliderColor(value),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              thumbColor: color,
              overlayColor: color.withOpacity(.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 3,
              divisions: 3,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  static Color _sliderColor(int v) {
    switch (v) {
      case 1:
        return const Color(0xFFFFCC00);
      case 2:
        return const Color(0xFFFF9500);
      case 3:
        return const Color(0xFFFF3B30);
      default:
        return const Color(0xFF8E8E93);
    }
  }
}

// ── Dropdown de estádio fenológico ────────────────────────────────────────

class OccurrenceEstadioDropdown extends StatelessWidget {
  final EstadioData? selected;
  final bool expanded;
  final ValueChanged<EstadioData?> onChanged;
  final VoidCallback onToggleCard;

  const OccurrenceEstadioDropdown({
    super.key,
    required this.selected,
    required this.expanded,
    required this.onChanged,
    required this.onToggleCard,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EstadioData?>(
                    value: selected,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Selecionar estádio (opcional)',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                    dropdownColor: const Color(0xFF2C2C2E),
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    items: [
                      const DropdownMenuItem<EstadioData?>(
                        value: null,
                        child: Text(
                          '— Nenhum —',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 13),
                        ),
                      ),
                      ...kEstadios.map(
                        (e) => DropdownMenuItem<EstadioData?>(
                          value: e,
                          child: Text(
                            e.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: onChanged,
                  ),
                ),
              ),
              if (selected != null)
                GestureDetector(
                  onTap: onToggleCard,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: PremiumTokens.brandGreen,
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: (selected != null && expanded)
              ? Container(
                  key: ValueKey(selected!.code),
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PremiumTokens.brandGreen.withOpacity(.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: PremiumTokens.brandGreen.withOpacity(.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  PremiumTokens.brandGreen.withOpacity(.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              selected!.code,
                              style: const TextStyle(
                                color: PremiumTokens.brandGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selected!.description,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ),
                          Text(
                            '~${selected!.dap} DAP',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '⚠️ Atenção neste estádio:',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...selected!.attention.map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: PremiumTokens.brandGreen,
                                      fontSize: 12)),
                              Expanded(
                                child: Text(a,
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ── Chip de opção única (radio-style) ────────────────────────────────────

class OccurrenceRadioChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const OccurrenceRadioChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? PremiumTokens.brandGreen.withOpacity(.15)
              : const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? PremiumTokens.brandGreen : Colors.white12,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? PremiumTokens.brandGreen : Colors.white38,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet de seleção de fonte de foto ────────────────────────────────────

class OccurrencePhotoSourceSheet extends StatelessWidget {
  final String catEmoji;
  final String catLabel;

  const OccurrencePhotoSourceSheet({
    super.key,
    required this.catEmoji,
    required this.catLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$catEmoji $catLabel',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading:
                const Icon(Icons.camera_alt_outlined, color: Colors.white70),
            title: const Text('Câmera',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: Colors.white70),
            title: const Text('Galeria',
                style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

// ── Sheet de seleção de categoria para foto ──────────────────────────────

class OccurrenceCatPickerSheet extends StatelessWidget {
  final List<OccurrenceCategory> cats;

  const OccurrenceCatPickerSheet({super.key, required this.cats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Foto para qual categoria?',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...cats.map(
            (cat) => ListTile(
              leading: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
              title:
                  Text(cat.label, style: const TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, cat),
            ),
          ),
        ],
      ),
    );
  }
}
