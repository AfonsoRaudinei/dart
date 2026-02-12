import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:soloforte_app/modules/auth/models/register_dto.dart';
import 'package:soloforte_app/modules/auth/pages/register_page.dart';
import 'package:soloforte_app/modules/auth/services/auth_service.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

// Fake AuthService for controlling state
class FakeAuthService extends AuthService {
  bool shouldThrow = false;
  Duration delay = Duration.zero;

  @override
  Future<void> register(RegisterDto dto) async {
    if (shouldThrow) {
      throw Exception('Email já cadastrado');
    }
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }
}

void main() {
  late FakeAuthService fakeAuthService;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    fakeAuthService = FakeAuthService();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [authServiceProvider.overrideWith(() => fakeAuthService)],
      child: MaterialApp(
        theme: SoloForteTheme.lightTheme,
        home: const RegisterPage(),
        onGenerateRoute: (settings) {
          return null;
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }

  testGoldens('Register Page Golden Tests', (tester) async {
    // 1️⃣ Preparar ambiente (390x844)
    await tester.binding.setSurfaceSize(const Size(390, 844));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 1.0;

    // 2️⃣ Golden — Estado Inicial
    await tester.pumpWidgetBuilder(createWidget());
    await screenMatchesGolden(tester, 'auth/register_initial');

    // 4️⃣ Golden — Estado com Erro
    final passwordField = find.byKey(const Key('register_password_field'));
    final confirmPasswordField = find.byKey(
      const Key('register_confirm_password_field'),
    );
    final emailField = find.byKey(const Key('register_email_field'));

    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'Senha123!');

    await tester.ensureVisible(confirmPasswordField);
    await tester.enterText(confirmPasswordField, 'Senha456!');

    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'email_invalido');

    await tester.pump();
    await screenMatchesGolden(tester, 'auth/register_error');

    // Fix errors to move to Valid state
    final nameField = find.byKey(const Key('register_name_field'));
    final phoneField = find.byKey(const Key('register_phone_field'));

    await tester.ensureVisible(emailField);
    await tester.enterText(emailField, 'teste@soloforte.com');

    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Usuário Teste');

    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '11999999999');

    await tester.ensureVisible(passwordField);
    await tester.enterText(passwordField, 'SoloForte2025!');

    await tester.ensureVisible(confirmPasswordField);
    await tester.enterText(confirmPasswordField, 'SoloForte2025!');

    await tester.pumpAndSettle();

    // 3️⃣ Golden — Estado Preenchido (Válido)
    // Button should be enabled now.
    await screenMatchesGolden(tester, 'auth/register_valid');

    // 5️⃣ Golden — Estado Loading
    // Configure delay to capture loading state
    fakeAuthService.delay = const Duration(seconds: 2);

    final submitBtn = find.byKey(const Key('register_submit_button'));
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();

    await screenMatchesGolden(tester, 'auth/register_loading');

    // Cleanup
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
