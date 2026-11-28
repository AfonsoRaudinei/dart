import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

void main() {
  group('limiteTalhoesSincronizados por tier', () {
    test('grátis retorna 0', () {
      final plan = UserPlan.free(userId: 'u-free');
      expect(plan.limiteTalhoesSincronizados, 0);
    });

    test('bronze retorna 150', () {
      expect(PlanoTipo.bronze.limiteTalhoesSincronizados, 150);
      final plan = UserPlan(
        id: 'p-bronze',
        userId: 'u1',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime(2026),
        expiraEm: DateTime.now().add(const Duration(days: 90)),
        criadoEm: DateTime(2026),
      );
      expect(plan.limiteTalhoesSincronizados, 150);
    });

    test('prata retorna 500', () {
      expect(PlanoTipo.prata.limiteTalhoesSincronizados, 500);
    });

    test('ouro retorna null (ilimitado)', () {
      expect(PlanoTipo.ouro.limiteTalhoesSincronizados, isNull);
      final plan = UserPlan(
        id: 'p-ouro',
        userId: 'u1',
        plano: PlanoTipo.ouro,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime(2026),
        expiraEm: DateTime.now().add(const Duration(days: 365)),
        criadoEm: DateTime(2026),
      );
      expect(plan.limiteTalhoesSincronizados, isNull);
    });

    test('plano pago expirado retorna 0', () {
      final plan = UserPlan(
        id: 'p-exp',
        userId: 'u1',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime(2020),
        expiraEm: DateTime(2020, 6),
        criadoEm: DateTime(2020),
      );
      expect(plan.limiteTalhoesSincronizados, 0);
    });

    test('admin é ilimitado em qualquer plano', () {
      final adminFree = UserPlan.free(userId: 'a').copyWith(isAdmin: true);
      expect(adminFree.limiteTalhoesSincronizados, isNull);

      final adminBronzeExpirado = UserPlan(
        id: 'p-admin',
        userId: 'a',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: false,
        iniciouEm: DateTime(2020),
        expiraEm: DateTime(2020, 6),
        criadoEm: DateTime(2020),
        isAdmin: true,
      );
      expect(adminBronzeExpirado.limiteTalhoesSincronizados, isNull);
    });

    test('valores pagos nunca são negativos', () {
      for (final tipo in PlanoTipo.values) {
        final limite = tipo.limiteTalhoesSincronizados;
        if (limite != null) {
          expect(limite, greaterThanOrEqualTo(0));
        }
      }
    });
  });
}