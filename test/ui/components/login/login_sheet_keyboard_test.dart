import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/login/login_sheet_keyboard_layout.dart';
import 'package:soloforte_app/ui/components/login/social_auth_button.dart';

void main() {
  group('LoginSheetKeyboardLayout', () {
    test('sheetBottomOffset segue o inset do teclado', () {
      expect(LoginSheetKeyboardLayout.sheetBottomOffset(0), 0);
      expect(LoginSheetKeyboardLayout.sheetBottomOffset(300), 300);
    });

    test('sheetMaxHeight encolhe com teclado', () {
      const height = 800.0;
      const top = 59.0;
      const keyboard = 300.0;

      final withoutKeyboard = LoginSheetKeyboardLayout.sheetMaxHeight(
        viewportHeight: height,
        keyboardInset: 0,
        topSafePadding: top,
      );
      expect(withoutKeyboard, height * 0.80);

      final withKeyboard = LoginSheetKeyboardLayout.sheetMaxHeight(
        viewportHeight: height,
        keyboardInset: keyboard,
        topSafePadding: top,
      );
      expect(withKeyboard, height - keyboard - top);
    });
  });

  testWidgets('SocialAuthButton desabilitado nao dispara callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialAuthButton(
            text: 'Continuar com Google',
            subtitle: 'Disponível em breve',
            icon: Icons.account_circle_outlined,
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.text('Disponível em breve'), findsOneWidget);
    await tester.tap(find.byType(SocialAuthButton));
    await tester.pump();
    expect(tapped, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SocialAuthButton(
            text: 'Continuar com Google',
            icon: Icons.account_circle_outlined,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(SocialAuthButton));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
