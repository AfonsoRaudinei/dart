import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/event.dart';
import '../providers/agenda_provider.dart';
import '../providers/agenda_filters_provider.dart';
import '../widgets/month_calendar_grid.dart';
import '../../../../core/constants/layout_constants.dart';

/// View de Calendário Mensal (view padrão anterior)
class AgendaCalendarioView extends ConsumerStatefulWidget {
  const AgendaCalendarioView({super.key});

  @override
  ConsumerState<AgendaCalendarioView> createState() =>
      _AgendaCalendarioViewState();
}

class _AgendaCalendarioViewState extends ConsumerState<AgendaCalendarioView> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaProvider);
    final filters = ref.watch(agendaFiltersProvider);
    final theme = Theme.of(context);

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    final monthEvents = ref
        .read(agendaProvider.notifier)
        .getEventsByDateRange(firstDay, lastDay);
    final filteredEvents = _applyFilters(monthEvents, filters);
    final eventsByDay = _groupEventsByDay(filteredEvents);

    return Column(
      children: [
        _buildMonthNavigation(theme),
        const SizedBox(height: 16),
        Expanded(
          child: agendaState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      MonthCalendarGrid(
                        month: _currentMonth,
                        eventsByDay: eventsByDay,
                        onDayTap: (day) {
                          context.push(
                            '/agenda/day?date=${day.toIso8601String()}',
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      if (filteredEvents.isNotEmpty)
                        _buildMonthSummary(filteredEvents, theme),
                      if (agendaState.conflicts.isNotEmpty)
                        _buildConflictWarning(agendaState.conflicts.length),
                      const SizedBox(height: kFabSafeArea), // Espaço para FAB
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A3136)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month - 1,
                );
              });
            },
          ),
          Text(
            _formatMonthYear(_currentMonth),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(
                  _currentMonth.year,
                  _currentMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConflictWarning(int count) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count evento(s) com conflito de horário',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Ver')),
        ],
      ),
    );
  }

  Widget _buildMonthSummary(List<Event> events, ThemeData theme) {
    final total = events.length;
    final concluidos = events.where((e) => e.status.isFinished).length;
    final emAndamento = events.where((e) => e.status.isActive).length;
    final agendados = events.where((e) => e.status.isEditable).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2A3136)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Mês',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total', total, const Color(0xFF4ADE80), theme),
              _buildSummaryItem('Agendados', agendados, Colors.blue, theme),
              _buildSummaryItem(
                'Em Andamento',
                emAndamento,
                Colors.orange,
                theme,
              ),
              _buildSummaryItem('Concluídos', concluidos, Colors.green, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    int count,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF6B7280),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  Map<int, List<Event>> _groupEventsByDay(List<Event> events) {
    final grouped = <int, List<Event>>{};
    for (final event in events) {
      final day = event.dataInicioPlanejada.day;
      grouped.putIfAbsent(day, () => []).add(event);
    }
    return grouped;
  }

  List<Event> _applyFilters(List<Event> events, AgendaFilters filters) {
    if (!filters.hasActiveFilters) return events;
    return events.where((event) {
      if (filters.types.isNotEmpty && !filters.types.contains(event.tipo)) {
        return false;
      }
      if (filters.statuses.isNotEmpty &&
          !filters.statuses.contains(event.status)) {
        return false;
      }
      if (filters.clienteId != null && event.clienteId != filters.clienteId) {
        return false;
      }
      if (filters.fazendaId != null && event.fazendaId != filters.fazendaId) {
        return false;
      }
      return true;
    }).toList();
  }
}
