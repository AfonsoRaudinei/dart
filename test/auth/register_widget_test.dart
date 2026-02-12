import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/auth/pages/register_page.dart';

void main() {
  group('RegisterPage Widget Tests', () {
    testWidgets('Should start with disabled submit button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Criar Conta');
      final button = tester.widget<ElevatedButton>(buttonFinder);

      expect(button.onPressed, isNull);
    });

    testWidgets('Should show error for invalid name', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome Completo'),
        'Jo',
      );
      await tester.pumpAndSettle();

      expect(find.text('Mínimo de 3 caracteres'), findsOneWidget);
    });

    testWidgets('Should toggle password visibility', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      // Default obscure text
      final passwordField = find.widgetWithText(TextFormField, 'Senha');
      final textField = find.descendant(
        of: passwordField,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(textField).obscureText, isTrue);

      // Click toggle button
      final toggleButton = find.descendant(
        of: passwordField,
        matching: find.byType(IconButton),
      );
      await tester.tap(toggleButton);
      await tester.pump();

      expect(tester.widget<TextField>(textField).obscureText, isFalse);
    });

    testWidgets('Should indicate weak password', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        '123456',
      );
      await tester.pumpAndSettle();

      expect(find.text('Fraca'), findsOneWidget);
    });

    testWidgets('Should enable button when form is valid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterPage())),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome Completo'),
        'João Silva',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-mail'),
        'joao@teste.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Telefone'),
        '11999999999',
      );
      // Necessário clicar no dropdown para selecionar? O padrão é Produtor.

      // Senha forte
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Senha'),
        'SoloForte2025!',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirmar Senha'),
        'SoloForte2025!',
      );

      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(ElevatedButton, 'Criar Conta');
      final button = tester.widget<ElevatedButton>(buttonFinder);

      expect(button.onPressed, isNotNull);
    });
  });
}
