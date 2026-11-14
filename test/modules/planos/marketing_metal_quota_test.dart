import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

void main() {
  group('PlanoTipo cota por metal', () {
    test('bronze paid plan quotas', () {
      const tipo = PlanoTipo.bronze;
      expect(tipo.cotaCasesBronze, 5);
      expect(tipo.cotaCasesPrata, 0);
      expect(tipo.cotaCasesOuro, 0);
      expect(tipo.limiteCases, 5);
    });

    test('prata paid plan quotas', () {
      const tipo = PlanoTipo.prata;
      expect(tipo.cotaCasesBronze, 5);
      expect(tipo.cotaCasesPrata, 5);
      expect(tipo.cotaCasesOuro, 0);
      expect(tipo.limiteCases, 10);
    });

    test('ouro paid plan quotas', () {
      const tipo = PlanoTipo.ouro;
      expect(tipo.cotaCasesBronze, 5);
      expect(tipo.cotaCasesPrata, 5);
      expect(tipo.cotaCasesOuro, 10);
      expect(tipo.limiteCases, 20);
    });
  });

  group('UserPlan.cotaPublicacaoPorMetal', () {
    test('free tem cota 0 em todos os metais', () {
      final plan = UserPlan.free(userId: 'u1');
      expect(plan.cotaPublicacaoPorMetal('bronze'), 0);
      expect(plan.cotaPublicacaoPorMetal('prata'), 0);
      expect(plan.cotaPublicacaoPorMetal('ouro'), 0);
    });

    test('ouro pago ativo', () {
      final plan = UserPlan(
        id: 'p1',
        userId: 'u1',
        plano: PlanoTipo.ouro,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime.now(),
        expiraEm: DateTime.now().add(const Duration(days: 30)),
        criadoEm: DateTime.now(),
      );
      expect(plan.cotaPublicacaoPorMetal('bronze'), 5);
      expect(plan.cotaPublicacaoPorMetal('prata'), 5);
      expect(plan.cotaPublicacaoPorMetal('ouro'), 10);
    });

    test('expirado tem cota 0', () {
      final plan = UserPlan(
        id: 'p1',
        userId: 'u1',
        plano: PlanoTipo.ouro,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime.now(),
        expiraEm: DateTime.utc(2020, 1, 1),
        criadoEm: DateTime.now(),
      );
      expect(plan.ocultaPinsMarketingNoMapa, isTrue);
      expect(plan.cotaPublicacaoPorMetal('ouro'), 0);
    });

    test('admin ilimitado', () {
      final plan = UserPlan(
        id: 'p-admin',
        userId: 'u1',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        isAdmin: true,
        iniciouEm: DateTime.now(),
        expiraEm: DateTime.now().add(const Duration(days: 30)),
        criadoEm: DateTime.now(),
      );
      expect(plan.cotaPublicacaoPorMetal('ouro'), 999999);
    });
  });
}