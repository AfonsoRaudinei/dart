import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/domain/combined_week.dart';

void main() {
  test('semana vai de segunda a domingo', () {
    final week = CombinedWeek.of(DateTime(2026, 11, 22, 15));

    expect(week.start, DateTime(2026, 11, 16));
    expect(week.lastDay, DateTime(2026, 11, 22));
    expect(week.endExclusive, DateTime(2026, 11, 23));
  });

  test(
    'contains inclui segunda 00:00 e domingo 23:59, exclui a segunda seguinte',
    () {
      final week = CombinedWeek.of(DateTime(2026, 11, 18));

      expect(week.contains(DateTime(2026, 11, 16)), isTrue);
      expect(week.contains(DateTime(2026, 11, 22, 23, 59)), isTrue);
      expect(week.contains(DateTime(2026, 11, 23)), isFalse);
      expect(week.contains(DateTime(2026, 11, 15, 23, 59)), isFalse);
    },
  );

  test('previous recua sete dias e atravessa mês e ano', () {
    final week = CombinedWeek.of(DateTime(2027, 1, 2));

    expect(week.start, DateTime(2026, 12, 28));
    expect(week.previous.start, DateTime(2026, 12, 21));
  });

  test('semanas do mesmo início são iguais', () {
    expect(
      CombinedWeek.of(DateTime(2026, 11, 17)),
      CombinedWeek.of(DateTime(2026, 11, 21)),
    );
  });

  test('rótulo no mesmo mês, entre meses e entre anos', () {
    expect(CombinedWeek.of(DateTime(2026, 11, 18)).label, '16 – 22 nov 2026');
    expect(
      CombinedWeek.of(DateTime(2026, 10, 29)).label,
      '26 out – 1 nov 2026',
    );
    expect(
      CombinedWeek.of(DateTime(2026, 12, 30)).label,
      '28 dez 2026 – 3 jan 2027',
    );
  });
}
