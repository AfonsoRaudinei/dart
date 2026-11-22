import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/planning_week.dart';

void main() {
  test('semana corrente inclui dia anterior a hoje', () {
    final today = DateTime(2026, 11, 22);
    final days = planningWeekDays(planningWeekStart(today));

    expect(days, hasLength(7));
    expect(days.first, DateTime(2026, 11, 16));
    expect(days.last, DateTime(2026, 11, 22));
    expect(days.any((day) => day.isBefore(today)), isTrue);
    expect(days.map((day) => day.day), [16, 17, 18, 19, 20, 21, 22]);
  });
}
