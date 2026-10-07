import 'package:flutter/material.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/widgets/photo/soloforte_photo_picker_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

import '../../domain/occurrence.dart';
import 'occurrence_fenologia_data.dart';

// ════════════════════════════════════════════════════════════════════════════
// WIDGETS AUXILIARES DE OccurrenceCreationSheet
// ════════════════════════════════════════════════════════════════════════════
// Extraídos para manter occurrence_creation_sheet.dart abaixo de 900 linhas.
// (Sprint 7 — Bounded Context Hygiene)

/// Detecção Azul via themeId (mesmo padrão visit_sheet) — funciona dentro ou
/// fora de [SoloForteSheetSkinScope].
bool occurrenceFormIsIos(BuildContext context) =>
    Theme.of(context).extension<SoloForteThemeExtension>()?.themeId == 'blue';

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
    final isIos = occurrenceFormIsIos(context);
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isIos ? SoloForteSheetSkinIos.titleColor : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: isIos ? SoloForteSheetSkinIos.rowDivider : Colors.white12,
          ),
        ),
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
    final isIos = occurrenceFormIsIos(context);
    final textColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final labelColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white38;
    final hintColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white24;
    final fill = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF1C1C1E);
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : Colors.white12;
    final focus = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor, fontSize: 13),
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 13),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: focus, width: 1.5),
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
    final isIos = occurrenceFormIsIos(context);
    final labelColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white70;
    final inactive =
        isIos ? SoloForteSheetSkinIos.rowDivider : Colors.white12;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sliderColor(value).withValues(alpha: .2),
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
              inactiveTrackColor: inactive,
              thumbColor: color,
              overlayColor: color.withValues(alpha: .2),
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
    final isIos = occurrenceFormIsIos(context);
    final surface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF1C1C1E);
    final border = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : Colors.white12;
    final muted =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white38;
    final title =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final dropdownBg = isIos
        ? SoloForteSheetSkinIos.background
        : const Color(0xFF2C2C2E);
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<EstadioData?>(
                    value: selected,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Selecionar estádio (opcional)',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ),
                    dropdownColor: dropdownBg,
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    items: [
                      DropdownMenuItem<EstadioData?>(
                        value: null,
                        child: Text(
                          '— Nenhum —',
                          style: TextStyle(color: muted, fontSize: 13),
                        ),
                      ),
                      ...kEstadios.map(
                        (e) => DropdownMenuItem<EstadioData?>(
                          value: e,
                          child: Text(
                            e.name,
                            style: TextStyle(
                              color: title,
                              fontSize: 13,
                            ),
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
                    color: PremiumTokens.brandGreen.withValues(alpha: .07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: PremiumTokens.brandGreen.withValues(alpha: .3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: PremiumTokens.brandGreen.withValues(
                                alpha: .2,
                              ),
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
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '~${selected!.dap} DAP',
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
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
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: PremiumTokens.brandGreen,
                                  fontSize: 12,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  a,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
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
    final isIos = occurrenceFormIsIos(context);
    final accent = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : PremiumTokens.brandGreen;
    final idleSurface = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF1C1C1E);
    final idleBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : Colors.white12;
    final idleText =
        isIos ? SoloForteSheetSkinIos.subtitleColor : Colors.white38;
    final radius = isIos ? SoloForteSheetSkinIos.cardRadius : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: .15) : idleSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected ? accent : idleBorder,
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
                color: selected ? accent : idleText,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Três origens de foto (galeria, câmera, inversão vegetal) ─────────────

class OccurrencePhotoOriginToolbar extends StatelessWidget {
  final Color accent;
  final ValueChanged<SoloFortePhotoPickerOrigin> onOriginSelected;

  const OccurrencePhotoOriginToolbar({
    super.key,
    required this.accent,
    required this.onOriginSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _OccurrencePhotoOriginButton(
          tooltip: 'Galeria',
          icon: SFIcons.photoLibrary,
          accent: accent,
          onTap: () => onOriginSelected(SoloFortePhotoPickerOrigin.gallery),
        ),
        _OccurrencePhotoOriginButton(
          tooltip: 'Câmera',
          icon: Icons.camera_alt_outlined,
          accent: accent,
          onTap: () => onOriginSelected(SoloFortePhotoPickerOrigin.camera),
        ),
        _OccurrencePhotoOriginButton(
          tooltip: 'Inversão vegetal',
          icon: SFIcons.leaf,
          accent: accent,
          onTap: () => onOriginSelected(SoloFortePhotoPickerOrigin.vegetal),
        ),
      ],
    );
  }
}

class _OccurrencePhotoOriginButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _OccurrencePhotoOriginButton({
    required this.tooltip,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = occurrenceFormIsIos(context);
    final surface = isIos
        ? SoloForteSheetSkinIos.iconBackground
        : accent.withValues(alpha: 0.12);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isIos ? SoloForteSheetSkinIos.ctaRadius : 14,
          ),
          side: BorderSide(color: accent.withValues(alpha: 0.55)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            isIos ? SoloForteSheetSkinIos.ctaRadius : 14,
          ),
          child: SizedBox(
            width: 72,
            height: 52,
            child: Icon(icon, color: accent, size: 26),
          ),
        ),
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
    final isIos = occurrenceFormIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.cardBackground
        : const Color(0xFF1C1C1E);
    final radius =
        isIos ? SoloForteSheetSkinIos.cardRadius : 16.0;
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final tileColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Foto para qual categoria?',
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          ...cats.map(
            (cat) => ListTile(
              leading: Text(cat.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(cat.label, style: TextStyle(color: tileColor)),
              onTap: () => Navigator.pop(context, cat),
            ),
          ),
        ],
      ),
    );
  }
}
