import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumAppTheme TextTheme', () {
    test('themeFor defines all Material 3 text roles in source', () {
      final source = File(
        'lib/ui/theme/premium/premium_app_theme.dart',
      ).readAsStringSync();

      for (final role in [
        'displayLarge',
        'displayMedium',
        'displaySmall',
        'headlineLarge',
        'headlineMedium',
        'headlineSmall',
        'titleLarge',
        'titleMedium',
        'titleSmall',
        'bodyLarge',
        'bodyMedium',
        'bodySmall',
        'labelLarge',
        'labelMedium',
        'labelSmall',
      ]) {
        expect(
          source.contains('$role:'),
          isTrue,
          reason: 'missing TextTheme role $role',
        );
      }
    });
  });
}
