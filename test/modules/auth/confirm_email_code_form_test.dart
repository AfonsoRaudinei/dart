import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/auth/widgets/confirm_email_code_form.dart';

const _fieldKey = Key('confirm_code_field');
const _submitKey = Key('confirm_code_submit');
const _resendKey = Key('confirm_code_resend');

Widget _host({
  required Future<void> Function(String code) onVerify,
  Future<void> Function()? onResend,
  VoidCallback? onConfirmed,
  bool startWithResendCooldown = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ConfirmEmailCodeForm(
          email: 'user@example.com',
          onVerify: onVerify,
          onResend: onResend ?? () async {},
          onConfirmed: onConfirmed ?? () {},
          startWithResendCooldown: startWithResendCooldown,
        ),
      ),
    ),
  );
}

ElevatedButton _submit(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byKey(_submitKey));

TextButton _resend(WidgetTester tester) =>
    tester.widget<TextButton>(find.byKey(_resendKey));

void main() {
  testWidgets('botão Confirmar desabilitado com menos de 6 dígitos', (
    tester,
  ) async {
    await tester.pumpWidget(_host(onVerify: (_) async {}));

    expect(_submit(tester).onPressed, isNull);

    await tester.enterText(find.byKey(_fieldKey), '12345');
    await tester.pump();
    expect(_submit(tester).onPressed, isNull);

    await tester.enterText(find.byKey(_fieldKey), '123456');
    await tester.pump();
    expect(_submit(tester).onPressed, isNotNull);
  });

  testWidgets('aceita somente dígitos e no máximo 6', (tester) async {
    await tester.pumpWidget(_host(onVerify: (_) async {}));

    await tester.enterText(find.byKey(_fieldKey), '12ab-3 45x6789');
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(_fieldKey));
    expect(field.controller!.text, '123456');
    expect(field.keyboardType, TextInputType.number);
    expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('verificação com sucesso envia o código e chama onConfirmed', (
    tester,
  ) async {
    String? sentCode;
    var confirmed = 0;
    await tester.pumpWidget(
      _host(
        onVerify: (code) async => sentCode = code,
        onConfirmed: () => confirmed++,
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), '654321');
    await tester.pump();
    await tester.tap(find.byKey(_submitKey));
    await tester.pump();

    expect(sentCode, '654321');
    expect(confirmed, 1);
  });

  testWidgets('erro de verificação mostra mensagem e não confirma', (
    tester,
  ) async {
    var confirmed = 0;
    await tester.pumpWidget(
      _host(
        onVerify: (_) async => throw Exception('Código inválido ou expirado.'),
        onConfirmed: () => confirmed++,
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), '111111');
    await tester.pump();
    await tester.tap(find.byKey(_submitKey));
    await tester.pump();

    expect(confirmed, 0);
    expect(find.byType(SnackBar), findsNothing);
    expect(
      tester.widget<Text>(find.byKey(const Key('confirm_code_feedback'))).data,
      'Código inválido ou expirado.',
    );
  });

  testWidgets('reenvio inicia cooldown de 60s e reabilita ao final', (
    tester,
  ) async {
    var resendCalls = 0;
    await tester.pumpWidget(
      _host(onVerify: (_) async {}, onResend: () async => resendCalls++),
    );

    expect(_resend(tester).onPressed, isNotNull);
    await tester.tap(find.byKey(_resendKey));
    await tester.pump();

    expect(resendCalls, 1);
    expect(_resend(tester).onPressed, isNull);
    expect(find.text('Reenviar código (60s)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Reenviar código (30s)'), findsOneWidget);
    expect(_resend(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Reenviar código'), findsOneWidget);
    expect(_resend(tester).onPressed, isNotNull);
  });

  testWidgets('startWithResendCooldown começa com reenvio bloqueado', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(onVerify: (_) async {}, startWithResendCooldown: true),
    );

    expect(_resend(tester).onPressed, isNull);
    expect(find.text('Reenviar código (60s)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 60));
    expect(_resend(tester).onPressed, isNotNull);
  });

  testWidgets('falha no reenvio não inicia cooldown', (tester) async {
    await tester.pumpWidget(
      _host(
        onVerify: (_) async {},
        onResend: () async => throw Exception('Muitas tentativas.'),
      ),
    );

    await tester.tap(find.byKey(_resendKey));
    await tester.pump();

    expect(find.text('Muitas tentativas.'), findsOneWidget);
    expect(_resend(tester).onPressed, isNotNull);
  });

  testWidgets('bloqueia por 60s após 5 erros seguidos', (tester) async {
    var verifyCalls = 0;
    await tester.pumpWidget(
      _host(
        onVerify: (_) async {
          verifyCalls++;
          throw Exception('Código inválido ou expirado.');
        },
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), '000000');
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
    }

    expect(verifyCalls, 5);
    expect(_submit(tester).onPressed, isNull);
    expect(find.text('Aguarde 60s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 59));
    expect(_submit(tester).onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(_submit(tester).onPressed, isNotNull);
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('sucesso zera o contador de erros', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _host(
        onVerify: (_) async {
          calls++;
          if (calls == 5) return;
          throw Exception('Código inválido ou expirado.');
        },
      ),
    );

    await tester.enterText(find.byKey(_fieldKey), '000000');
    await tester.pump();

    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byKey(_submitKey));
      await tester.pump();
    }

    expect(calls, 9);
    expect(_submit(tester).onPressed, isNotNull);
  });

  testWidgets('desmontar o widget cancela timers sem erro', (tester) async {
    await tester.pumpWidget(
      _host(onVerify: (_) async {}, startWithResendCooldown: true),
    );
    await tester.pump(const Duration(seconds: 5));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 120));

    expect(tester.takeException(), isNull);
  });
}
