import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/marketing_case_reports_list_policy.dart';

void main() {
  group('isEligibleForGeradosTab', () {
    test('published ativo e nao deletado e elegivel', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'published',
          ativo: true,
          deletadoEm: null,
        ),
        isTrue,
      );
    });

    test('draft nao e elegivel', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'draft',
          ativo: true,
          deletadoEm: null,
        ),
        isFalse,
      );
    });

    test('pending_sync nao e elegivel', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'pending_sync',
          ativo: true,
          deletadoEm: null,
        ),
        isFalse,
      );
    });

    test('archived nao e elegivel', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'archived',
          ativo: true,
          deletadoEm: null,
        ),
        isFalse,
      );
    });

    test('inativo nao e elegivel mesmo published', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'published',
          ativo: false,
          deletadoEm: null,
        ),
        isFalse,
      );
    });

    test('deletado nao e elegivel mesmo published e ativo', () {
      expect(
        isEligibleForGeradosTab(
          statusValue: 'published',
          ativo: true,
          deletadoEm: DateTime.utc(2026, 8, 8),
        ),
        isFalse,
      );
    });
  });
}
