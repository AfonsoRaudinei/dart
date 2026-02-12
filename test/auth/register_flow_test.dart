import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/modules/auth/models/register_dto.dart';
import 'package:soloforte_app/modules/auth/pages/register_page.dart';
import 'package:soloforte_app/modules/auth/services/auth_service.dart';

// Fake AuthService
class FakeAuthService extends AuthService {
  bool shouldThrow = false;
  Duration delay = Duration.zero;
  int callCount = 0;

  @override
  Future<void> register(RegisterDto dto) async {
    callCount++;
    if (shouldThrow) {
      throw Exception('Falha na conexão');
    }

    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
  }
}

void main() {
  late FakeAuthService fakeAuthService;

  setUp(() {
    fakeAuthService = FakeAuthService();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [authServiceProvider.overrideWith(() => fakeAuthService)],
      child: MaterialApp(
        home: const RegisterPage(),
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.login) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Login Page')),
            );
          }
          return null;
        },
      ),
    );
  }

  testWidgets('Should complete registration flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    // We need a small delay to verify the loading state logic
    fakeAuthService.delay = const Duration(seconds: 1);

    await tester.pumpWidget(createWidget());

    // Fill Form using Keys
    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'João Silva',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'joao@teste.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_phone_field')),
      '11999999999',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'SoloForte2025!',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'SoloForte2025!',
    );

    await tester.pumpAndSettle();

    final buttonFinder = find.byKey(const Key('register_submit_button'));
    // Ensure button is visible before checking state or tapping
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    // Ensure button is enabled
    expect(
      tester.widget<ElevatedButton>(buttonFinder).onPressed,
      isNotNull,
      reason: 'Button should be enabled',
    );
    // Check for button text specifically
    expect(
      find.descendant(of: buttonFinder, matching: find.text('Criar Conta')),
      findsOneWidget,
    );

    await tester.tap(buttonFinder);
    await tester.pump(); // Trigger setState

    // Check Loading State
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Button text should be gone (replaced by spinner), but title stays
    expect(
      find.descendant(of: buttonFinder, matching: find.text('Criar Conta')),
      findsNothing,
    );

    // Finish
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(fakeAuthService.callCount, 1);
  });

  testWidgets('Should handle backend error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    fakeAuthService.shouldThrow = true;

    await tester.pumpWidget(createWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Maria Souza',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'maria@teste.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_phone_field')),
      '11988888888',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'SoloForte2025!',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'SoloForte2025!',
    );

    await tester.pumpAndSettle();

    final buttonFinder = find.byKey(const Key('register_submit_button'));
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Erro ao criar conta: Falha na conexão'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  // Test de duplo clique sem depender de delay do testRunner.
  // A estratégia é usar o delay do FakeAuthService para manter o estado _isLoading = true.
  testWidgets('Should prevent double submit via logic', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    // Long delay to ensure we can tap again during loading
    fakeAuthService.delay = const Duration(seconds: 30);

    await tester.pumpWidget(createWidget());

    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Pedro Mock',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'pedro@teste.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_phone_field')),
      '11977777777',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'SoloForte2025!',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'SoloForte2025!',
    );

    await tester.pumpAndSettle();

    final buttonFinder = find.byKey(const Key('register_submit_button'));
    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    // First tap
    await tester.tap(buttonFinder);
    await tester.pump(); // Start loading

    // Verify Service Called
    expect(fakeAuthService.callCount, 1);

    // Attempt second tap.
    // We try to tap the button again.
    // If UI changed (Loader), tap might fail.
    // If UI didn't change (Text), tap succeeds.
    // Either way, if logic works, callCount must stay 1.
    try {
      await tester.tap(buttonFinder);
      await tester.pump();
    } catch (_) {
      // Button not tappable/visible is GOOD.
    }

    // Call count must STILL be 1
    expect(
      fakeAuthService.callCount,
      1,
      reason: 'Should not call register twice',
    );

    // Finish
    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  });
}
