import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    if (shouldThrow) throw Exception('Erro');
    if (delay > Duration.zero) await Future.delayed(delay);
  }
}

void main() {
  late FakeAuthService fakeAuthService;

  setUp(() {
    fakeAuthService = FakeAuthService();
    // Reset build count before each test
    RegisterPage.buildCount = 0;
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [authServiceProvider.overrideWith(() => fakeAuthService)],
      child: const MaterialApp(home: RegisterPage()),
    );
  }

  testWidgets('Performance: Typing in Name should NOT rebuild entire page', (
    tester,
  ) async {
    await tester.pumpWidget(createWidget());

    // Type 10 chars
    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'User Name',
    );
    await tester.pump();

    final afterTypingBuilds = RegisterPage.buildCount;

    // Changing text in TextFormField inherently causes internal state update if listening,
    // but RegisterPage itself handles validation logic.
    // Ideally, _validateForm only setsState if validity CHANGES.
    // 'User Name' is valid (length > 3).
    // Initial State: Invalid (empty).
    // 'U' -> Invalid. (No change).
    // 'Us' -> Invalid. (No change).
    // 'Use' -> Valid (Change!). setState called.
    // 'User' -> Valid (No change).
    // So expected rebuilds: Initial + 1 (when valid flips).

    // If it rebuilds on EVERY char, count would be heavily increased.
    // However, enterText enters all text at once in tester.
    // In real app, user types one by one.
    // tester.enterText calls onChanged once with full text.

    // To simulate real typing, we need to loop.
    // Actually, let's type char by char if possible, or assume enterText checks the aggregate result.

    // Let's use loop for heavy typing simulation
    for (var i = 0; i < 5; i++) {
      await tester.enterText(
        find.byKey(const Key('register_name_field')),
        'User Name $i',
      );
      await tester.pump();
    }

    // We typed 5 times.
    // If logic is optimal, validity is already TRUE. So NO rebuilds should happen.
    // If logic is slow, it rebuilds 5 times.

    final finalBuilds = RegisterPage.buildCount;
    final diff = finalBuilds - afterTypingBuilds;

    expect(
      diff,
      lessThanOrEqualTo(1),
      reason: 'Page rebuilt too many times during valid text updates',
    );
  });

  testWidgets(
    'Performance: Password Strength typing should NOT rebuild entire page excessively',
    (tester) async {
      await tester.pumpWidget(createWidget());

      // Enter valid regular fields first to isolate password
      await tester.enterText(
        find.byKey(const Key('register_name_field')),
        'User Name',
      );
      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'user@email.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_phone_field')),
        '11999999999',
      );
      await tester.pump();

      final baseline = RegisterPage.buildCount;

      // Type password char by char
      final passwordField = find.byKey(const Key('register_password_field'));

      // '1' (Weak) -> Rebuild (Strength changes None->Weak?)
      await tester.enterText(passwordField, '1');
      await tester.pump();

      // '12' (Weak) -> Rebuild? If strength assumes Weak->Weak?
      // Current logic: _handlePasswordChange calls setState unconditionally!
      // So it WILL rebuild.
      // We expect this to FAIL if we enforce optimization.

      await tester.enterText(passwordField, '12');
      await tester.pump();

      final builds = RegisterPage.buildCount - baseline;

      // If current implementation is naive, builds == 2.
      // If optimized, builds should be 0 (if strength didn't change category).

      // We assertion for OPTIMIZED behavior:
      expect(
        builds,
        lessThanOrEqualTo(1),
        reason:
            'Password typing triggered rebuilds even when strength category remained Weak',
      );
    },
  );

  testWidgets('Performance: Submit does not freeze UI', (tester) async {
    fakeAuthService.delay = const Duration(seconds: 30); // Long delay
    await tester.pumpWidget(createWidget());

    // Fill all valid
    await tester.enterText(
      find.byKey(const Key('register_name_field')),
      'Valid Name',
    );
    await tester.enterText(
      find.byKey(const Key('register_email_field')),
      'valid@email.com',
    );
    await tester.enterText(
      find.byKey(const Key('register_phone_field')),
      '11999999999',
    );
    await tester.enterText(
      find.byKey(const Key('register_password_field')),
      'StrongPass1!',
    );
    await tester.enterText(
      find.byKey(const Key('register_confirm_password_field')),
      'StrongPass1!',
    );
    await tester.pump();

    final submitBtn = find.byKey(const Key('register_submit_button'));
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();

    // Ensure button is enabled
    final btn = tester.widget<ElevatedButton>(submitBtn);
    expect(btn.onPressed, isNotNull, reason: 'Button should be enabled');

    await tester.tap(submitBtn);
    await tester.pump(); // Start loading (microtask processing)

    // Check if error snackbar appeared (which would mean failure)
    if (find.byType(SnackBar).evaluate().isNotEmpty) {
      final snack = tester.widget<SnackBar>(find.byType(SnackBar).first);
      final content = (snack.content as Text).data;
      fail('Submit failed with error: $content');
    }

    // Verify functional logic first
    expect(
      fakeAuthService.callCount,
      1,
      reason: 'Service should be called once',
    );

    // Validate UI/Performance (Loading state)
    // If logic worked, UI should show loader because we are waiting 30s
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();
  });
}
