import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/feature_flags/feature_flag_backend_adapter.dart';

void main() {
  group('featureFlagsUseMock', () {
    test('development usa mock', () {
      expect(featureFlagsUseMock('development'), isTrue);
    });

    test('staging NÃO usa mock (backend real)', () {
      expect(featureFlagsUseMock('staging'), isFalse);
    });

    test('production NÃO usa mock', () {
      expect(featureFlagsUseMock('production'), isFalse);
    });
  });
}
