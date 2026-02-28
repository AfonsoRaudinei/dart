import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';
import '../widgets/day_event_card.dart';
import 'package:intl/intl.dart';

/// View de Planejamento Semanal (modelo da skill)
class AgendaPlanejamentoView extends ConsumerStatefulWidget {
  const AgendaPlanejamentoView({super.key});

  @override
  ConsumerState<AgendaPlanejamentoView> createState() =>
      _AgendaPlanejamentoViewState();
}

class _AgendaPlanejamentoViewState
    extends ConsumerState<AgendaPlanejamentoView> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final agendaState = ref.watch(agendaProvider);

    final weekEnd = _weekStart.add(const Duration(days: 6));
    final weekEvents = ref
        .read(agendaProvider.notifier)
        .getEventsByDateRange(_weekStart, weekEnd);

    final eventsByDay = _groupEventsByDay(weekEvents);

    return Column(
      children: [
        _buildWeekNavigation(theme),
        const SizedBox(height: 16),
        Expanded(
          child: agendaState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = _weekStart.add(Duration(days: index));
                    final dayEvents = eventsByDay[_dayKey(day)] ?? [];
                    return _buildDayCard(context, theme, day, dayEvents);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildWeekNavigation(ThemeData theme) {
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
                _weekStart = _weekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Text(
            _formatWeekRange(_weekStart),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _weekStart = _weekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    ThemeData theme,
    DateTime day,
    List<Event> events,
  ) {
    final isSunday = day.weekday == DateTime.sunday;
    final isToday = _isToday(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isSunday
            ? (theme.brightness == Brightness.dark
                  ? const Color(0xFF1A3A1F)
                  : const Color(0xFFD1FAE5))
            : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday
              ? const Color(0xFF4ADE80)
              : (theme.brightness == Brightness.dark
                    ? const Color(0xFF2A3136)
                    : const Color(0xFFE5E7EB)),
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(theme, day, events, isSunday),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nenhum evento agendado',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return DayEventCard(
                  event: events[index],
                  onTap: () {
                    // Navegar para detalhes
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(
    ThemeData theme,
    DateTime day,
    List<Event> events,
    bool isSunday,
  ) {
    final completedCount = events
        .where((e) => e.status == EventStatus.concluido)
        .length;
    final totalCount = events.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A3136)
                : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE', 'pt_BR').format(day),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isSunday ? const Color(0xFF4ADE80) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy', 'pt_BR').format(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF1E2428)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, List<Event>> _groupEventsByDay(List<Event> events) {
    final map = <String, List<Event>>{};
    for (final event in events) {
      final key = _dayKey(event.dataInicioPlanejada);
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatWeekRange(DateTime start) {
    final end = start.add(const Duration(days: 6));
    return '${DateFormat('d MMM', 'pt_BR').format(start)} - ${DateFormat('d MMM yyyy', 'pt_BR').format(end)}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
