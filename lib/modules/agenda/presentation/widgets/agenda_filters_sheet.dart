import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_filters_provider.dart';

/// Sheet de filtros da agenda
class AgendaFiltersSheet extends ConsumerWidget {
  const AgendaFiltersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(agendaFiltersProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (filters.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    ref.read(agendaFiltersProvider.notifier).clearAll();
                  },
                  child: const Text('Limpar'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Tipos
          Text(
            'Tipos de Evento',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventType.values.map((type) {
              final isSelected = filters.types.contains(type);
              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.icon),
                    const SizedBox(width: 6),
                    Text(type.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(agendaFiltersProvider.notifier).toggleType(type);
                },
                backgroundColor: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : null,
                selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: theme.primaryColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Status
          Text(
            'Status',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EventStatus.values.map((status) {
              final isSelected = filters.statuses.contains(status);
              return FilterChip(
                label: Text(status.label),
                selected: isSelected,
                onSelected: (_) {
                  ref.read(agendaFiltersProvider.notifier).toggleStatus(status);
                },
                backgroundColor: isSelected
                    ? theme.primaryColor.withValues(alpha: 0.1)
                    : null,
                selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: theme.primaryColor,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Botão aplicar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Aplicar Filtros'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
