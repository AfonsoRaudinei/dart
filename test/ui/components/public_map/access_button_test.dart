import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/components/public_map/access_button.dart';

void main() {
  testWidgets('tap no CTA público navega para /login', (tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.publicMap,
      routes: [
        GoRoute(
          path: AppRoutes.publicMap,
          builder: (context, state) =>
              const Scaffold(body: AccessSoloForteButton()),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) =>
              const Scaffold(body: Text('Login')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();

    expect(find.byType(AccessSoloForteButton), findsOneWidget);

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      AppRoutes.login,
    );
  });
}
