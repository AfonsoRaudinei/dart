import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
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

    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomPad),
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SoloForteSheetTokens.borderRadius),
        ),
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 20),
                  decoration: BoxDecoration(
                    color: SoloForteSheetTokens.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtros',
                      style: TextStyle(
                        fontSize: SoloForteSheetTokens.titleFontSize,
                        fontWeight: SoloForteSheetTokens.titleWeight,
                        color: SoloForteSheetTokens.titleColor,
                      ),
                    ),
                  ),
                  if (filters.hasActiveFilters)
                    TextButton(
                      onPressed: () {
                        ref.read(agendaFiltersProvider.notifier).clearAll();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: SoloForteSheetTokens.chipBorderActive,
                      ),
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
                    accentColor: _typeAccentColor(type),
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
                    accentColor: _statusAccentColor(status),
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
                    backgroundColor: SoloForteSheetTokens.chipBorderActive,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: SoloForteSheetTokens.inputHint,
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  const _FilterGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(14),
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
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : const Color(0xFFE5E7EB).withValues(alpha: 0.18),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? accentColor : const Color(0xFF202124),
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
