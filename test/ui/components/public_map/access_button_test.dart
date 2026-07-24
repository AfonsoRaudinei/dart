import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/components/public_map/access_button.dart';

void main() {
  GoRouter buildRouter({
    Duration taglineInterval = const Duration(seconds: 4),
    Random? random,
  }) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => Scaffold(
            body: AccessSoloForteButton(
              taglineInterval: taglineInterval,
              random: random,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );
  }

  String latestTagline(WidgetTester tester) {
    final scored = <({int key, String text})>[];
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data;
      if (data == null || !kAccessSoloForteTaglines.contains(data)) continue;
      final key = text.key;
      scored.add((
        key: key is ValueKey<int> ? key.value : -1,
        text: data,
      ));
    }
    expect(scored, isNotEmpty);
    scored.sort((a, b) => a.key.compareTo(b.key));
    return scored.last.text;
  }

  testWidgets('AccessSoloForteButton mostra título, tagline e logo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildRouter(random: Random(1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText && w.text.toPlainText().contains('Acessar SoloForte'),
      ),
      findsOneWidget,
    );
    expect(kAccessSoloForteTaglines, contains(latestTagline(tester)));
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('AccessSoloForteButton troca tagline após o intervalo', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: buildRouter(
          taglineInterval: const Duration(milliseconds: 300),
          random: Random(42),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550)); // só a entrada

    final first = latestTagline(tester);

    await tester.pump(const Duration(milliseconds: 320)); // dispara Timer
    await tester.pump(const Duration(milliseconds: 500)); // fim da transição

    final second = latestTagline(tester);

    expect(kAccessSoloForteTaglines, contains(first));
    expect(kAccessSoloForteTaglines, contains(second));
    expect(second, isNot(equals(first)));
  });

  testWidgets('AccessSoloForteButton navega para login ao tocar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: buildRouter(random: Random(7))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(InkWell));
    await tester.pump(); // inicia navegação
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('login'), findsOneWidget);
  });
}
