/// Segunda-feira da semana que contém [day].
DateTime planningWeekStart(DateTime day) {
  final date = DateTime(day.year, day.month, day.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

/// Os sete dias da semana que começa em [weekStart], inclusive os já passados.
List<DateTime> planningWeekDays(DateTime weekStart) {
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  return List.generate(7, (index) => start.add(Duration(days: index)));
}
