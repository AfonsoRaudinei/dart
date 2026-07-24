import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/components/public_map/access_button.dart';

void main() {
  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: AccessSoloForteButton(),
          ),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login')),
        ),
      ],
    );
  }

  testWidgets('AccessSoloForteButton mostra título, subtítulo e logo', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Tecnologia com raiz.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is RichText && w.text.toPlainText().contains('Acessar SoloForte'),
      ),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('AccessSoloForteButton navega para login ao tocar', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });
}
