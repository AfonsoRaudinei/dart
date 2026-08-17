import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_filters_provider.dart';

/// Sheet de filtros da agenda
class AgendaFiltersSheet extends ConsumerWidget {
  const AgendaFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(agendaFiltersProvider);
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final isIos = soloForteSheetIsIos(context);
    // Modal já pinta prata iOS — evitar segundo painel opaco (“dois sheets”).
    final sheetBg = isIos
        ? Colors.transparent
        : SoloForteSheetTokens.sheetBackground;
    final handleColor = isIos
        ? SoloForteSheetSkinIos.handleColor
        : SoloForteSheetTokens.divider;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final clearColor = isIos
        ? SoloForteSheetSkinIos.ghostText
        : SoloForteSheetTokens.chipBorderActive;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : SoloForteSheetTokens.chipBorderActive;
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.black;
    final ctaRadius = isIos ? SoloForteSheetSkinIos.ctaRadius : 14.0;
    final sheetRadius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPad),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(sheetRadius)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: isIos
                      ? SoloForteSheetSkinIos.handleSize.width
                      : 36,
                  height: isIos
                      ? SoloForteSheetSkinIos.handleSize.height
                      : 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: SoloForteSheetTokens.titleFontSize,
                        fontWeight: SoloForteSheetTokens.titleWeight,
                        color: titleColor,
                      ),
                    ),
                  ),
                  if (filters.hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        ref.read(agendaFiltersProvider.notifier).clearAll();
                      },
                      style: TextButton.styleFrom(foregroundColor: clearColor),
                      child: const Text(
                        'Limpar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const _SectionTitle('TIPOS DE EVENTO'),
              const SizedBox(height: 10),
              _FilterGroup(
                children: EventType.values.map((type) {
                  final isSelected = filters.types.contains(type);
                  return _AgendaFilterChip(
                    label: type.label,
                    isSelected: isSelected,
                    accentColor: isIos
                        ? SoloForteSheetSkinIos.iconStroke
                        : _typeAccentColor(type),
                    onTap: () {
                      ref.read(agendaFiltersProvider.notifier).toggleType(type);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const _SectionTitle('STATUS'),
              const SizedBox(height: 10),
              _FilterGroup(
                children: EventStatus.values.map((status) {
                  final isSelected = filters.statuses.contains(status);
                  return _AgendaFilterChip(
                    label: status.label,
                    isSelected: isSelected,
                    accentColor: isIos
                        ? SoloForteSheetSkinIos.iconStroke
                        : _statusAccentColor(status),
                    onTap: () {
                      ref
                          .read(agendaFiltersProvider.notifier)
                          .toggleStatus(status);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctaBg,
                    foregroundColor: ctaFg,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ctaRadius),
                    ),
                  ),
                  child: const Text(
                    'Aplicar Filtros',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _typeAccentColor(EventType type) {
  switch (type) {
    case EventType.visitaTecnica:
      return const Color(0xFF4ADE80);
    case EventType.aplicacao:
      return const Color(0xFF38BDF8);
    case EventType.consultoria:
      return const Color(0xFFF59E0B);
    case EventType.colheita:
      return const Color(0xFFFACC15);
    case EventType.manutencao:
      return const Color(0xFFFB923C);
    case EventType.reuniao:
      return const Color(0xFF60A5FA);
    case EventType.lembrete:
      return const Color(0xFFA78BFA);
    case EventType.personalizado:
      return const Color(0xFFF472B6);
  }
}

Color _statusAccentColor(EventStatus status) {
  switch (status) {
    case EventStatus.agendado:
      return const Color(0xFF60A5FA);
    case EventStatus.emAndamento:
      return const Color(0xFFF59E0B);
    case EventStatus.finalizando:
      return const Color(0xFFFACC15);
    case EventStatus.concluido:
      return const Color(0xFF4ADE80);
    case EventStatus.cancelado:
      return const Color(0xFF9CA3AF);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: isIos
            ? SoloForteSheetSkinIos.subtitleColor
            : SoloForteSheetTokens.inputHint,
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isIos
            ? SoloForteSheetSkinIos.cardBackground
            : SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(
          isIos ? SoloForteSheetSkinIos.cardRadius : 14,
        ),
        border: isIos
            ? Border.all(color: SoloForteSheetSkinIos.cardBorder)
            : null,
      ),
      child: Wrap(spacing: 10, runSpacing: 10, children: children),
    );
  }
}

class _AgendaFilterChip extends StatelessWidget {
  const _AgendaFilterChip({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final unselectedFill = isIos
        ? SoloForteSheetSkinIos.background
        : context.premiumSurface;
    final unselectedBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : context.premiumHairline;
    final unselectedText = isIos
        ? SoloForteSheetSkinIos.titleColor
        : context.premiumTextPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.14)
                : unselectedFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : unselectedBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? accentColor : unselectedText,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
