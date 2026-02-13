import 'package:flutter/material.dart';
import '../../domain/entities/event.dart';

/// Grid do calendário mensal
class MonthCalendarGrid extends StatelessWidget {
  final DateTime month;
  final Map<int, List<Event>> eventsByDay;
  final Function(DateTime) onDayTap;

  const MonthCalendarGrid({
    super.key,
    required this.month,
    required this.eventsByDay,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7; // 0 = domingo
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();

    return Column(
      children: [
        // Header dos dias da semana
        _buildWeekdayHeader(theme),
        const SizedBox(height: 8),

        // Grid de dias
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startWeekday) {
              return const SizedBox.shrink();
            }

            final day = index - startWeekday + 1;
            final date = DateTime(month.year, month.month, day);
            final events = eventsByDay[day] ?? [];
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;

            return _buildDayCell(
              context,
              theme,
              day,
              date,
              events,
              isToday,
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader(ThemeData theme) {
    const weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return Row(
      children: weekdays.map((day) {
        return Expanded(
          child: Center(
            child: Text(
              day,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    ThemeData theme,
    int day,
    DateTime date,
    List<Event> events,
    bool isToday,
  ) {
    return InkWell(
      onTap: () => onDayTap(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: theme.primaryColor, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Número do dia
            Text(
              day.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                color: isToday ? theme.primaryColor : null,
              ),
            ),

            // Badge de quantidade
            if (events.isNotEmpty) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  events.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            // Indicadores coloridos por tipo (máx 3)
            if (events.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: events.take(3).map((event) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _getEventColor(event),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEventColor(Event event) {
    switch (event.tipo) {
      case var type when type.toString().contains('visitaTecnica'):
        return Colors.blue;
      case var type when type.toString().contains('aplicacao'):
        return Colors.cyan;
      case var type when type.toString().contains('consultoria'):
        return Colors.purple;
      case var type when type.toString().contains('colheita'):
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
