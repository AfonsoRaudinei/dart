/// Semana (segunda a domingo, horário local) usada para filtrar os capítulos
/// do relatório combinado.
class CombinedWeek {
  final DateTime start;

  const CombinedWeek._(this.start);

  factory CombinedWeek.of(DateTime day) {
    final local = day.toLocal();
    return CombinedWeek._(
      DateTime(local.year, local.month, local.day - (local.weekday - 1)),
    );
  }

  DateTime get endExclusive => DateTime(start.year, start.month, start.day + 7);

  DateTime get lastDay => DateTime(start.year, start.month, start.day + 6);

  CombinedWeek get previous =>
      CombinedWeek._(DateTime(start.year, start.month, start.day - 7));

  bool contains(DateTime moment) {
    final local = moment.toLocal();
    return !local.isBefore(start) && local.isBefore(endExclusive);
  }

  String get label => combinedWeekLabel(this);

  @override
  bool operator ==(Object other) =>
      other is CombinedWeek && other.start == start;

  @override
  int get hashCode => start.hashCode;
}

const _months = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

/// `16 – 22 nov 2026`, `28 out – 3 nov 2026` ou `29 dez 2026 – 4 jan 2027`.
String combinedWeekLabel(CombinedWeek week) {
  final first = week.start;
  final last = week.lastDay;
  final firstMonth = _months[first.month - 1];
  final lastMonth = _months[last.month - 1];
  if (first.year != last.year) {
    return '${first.day} $firstMonth ${first.year} – '
        '${last.day} $lastMonth ${last.year}';
  }
  if (first.month != last.month) {
    return '${first.day} $firstMonth – ${last.day} $lastMonth ${last.year}';
  }
  return '${first.day} – ${last.day} $lastMonth ${last.year}';
}
