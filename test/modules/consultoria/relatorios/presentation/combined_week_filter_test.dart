import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/domain/combined_week.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/combined_week_filter.dart';

Widget _host(CombinedWeek? week, ValueChanged<CombinedWeek?> onChanged) {
  return MaterialApp(
    home: Scaffold(
      body: CombinedWeekFilter(week: week, onChanged: onChanged),
    ),
  );
}

void main() {
  testWidgets('Semana passada devolve a semana anterior à atual', (
    tester,
  ) async {
    CombinedWeek? chosen;
    await tester.pumpWidget(_host(null, (week) => chosen = week));

    await tester.tap(find.text('Semana passada'));

    expect(chosen, CombinedWeek.of(DateTime.now()).previous);
  });

  testWidgets('Tudo limpa o filtro e a semana ativa mostra o período', (
    tester,
  ) async {
    CombinedWeek? chosen = CombinedWeek.of(DateTime.now());
    var called = false;
    await tester.pumpWidget(
      _host(chosen, (week) {
        chosen = week;
        called = true;
      }),
    );

    expect(find.text(chosen!.label), findsOneWidget);

    await tester.tap(find.text('Tudo'));

    expect(called, isTrue);
    expect(chosen, isNull);
  });

  testWidgets('semana escolhida fora de atual/passada vira o rótulo do chip', (
    tester,
  ) async {
    final old = CombinedWeek.of(
      DateTime.now().subtract(const Duration(days: 40)),
    );
    await tester.pumpWidget(_host(old, (_) {}));

    expect(find.text('Outra semana'), findsNothing);
    expect(find.text(old.label), findsNWidgets(2));
  });
}
