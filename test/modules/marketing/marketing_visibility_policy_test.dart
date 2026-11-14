import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_visibility_policy.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

UserPlan _paid(PlanoTipo tipo) => UserPlan(
      id: 'paid',
      userId: 'u1',
      plano: tipo,
      origem: PlanoOrigem.pagamento,
      ativo: true,
      iniciouEm: DateTime.now(),
      expiraEm: DateTime.now().add(const Duration(days: 90)),
      criadoEm: DateTime.now(),
    );

void main() {
  group('MarketingVisibilityPolicy', () {
    test('free trava seletor e sem metal inicial', () {
      final plan = UserPlan.free(userId: 'u1');
      expect(MarketingVisibilityPolicy.seletorTotalmenteTravado(plan), isTrue);
      expect(MarketingVisibilityPolicy.metaisSelecionaveis(plan), isEmpty);
      expect(MarketingVisibilityPolicy.metalInicialNovoCase(plan), isNull);
    });

    test('expirado não admin trava seletor', () {
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
      expect(MarketingVisibilityPolicy.seletorTotalmenteTravado(plan), isTrue);
    });

    test('admin expirado não trava seletor', () {
      final plan = UserPlan(
        id: 'p1',
        userId: 'u1',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        isAdmin: true,
        iniciouEm: DateTime.now(),
        expiraEm: DateTime.utc(2020, 1, 1),
        criadoEm: DateTime.now(),
      );
      expect(MarketingVisibilityPolicy.seletorTotalmenteTravado(plan), isFalse);
      expect(
        MarketingVisibilityPolicy.metaisSelecionaveis(plan),
        PlanoMarketing.values.toSet(),
      );
    });

    test('bronze pago só bronze selecionável', () {
      final plan = _paid(PlanoTipo.bronze);
      expect(MarketingVisibilityPolicy.seletorTotalmenteTravado(plan), isFalse);
      expect(
        MarketingVisibilityPolicy.metaisSelecionaveis(plan),
        {PlanoMarketing.bronze},
      );
      expect(
        MarketingVisibilityPolicy.metalInicialNovoCase(plan),
        PlanoMarketing.bronze,
      );
    });

    test('prata pago bronze e prata', () {
      final plan = _paid(PlanoTipo.prata);
      expect(
        MarketingVisibilityPolicy.metaisSelecionaveis(plan),
        {PlanoMarketing.bronze, PlanoMarketing.prata},
      );
      expect(
        MarketingVisibilityPolicy.metalInicialNovoCase(plan),
        PlanoMarketing.bronze,
      );
    });

    test('ouro pago os três metais', () {
      final plan = _paid(PlanoTipo.ouro);
      expect(
        MarketingVisibilityPolicy.metaisSelecionaveis(plan),
        PlanoMarketing.values.toSet(),
      );
      expect(
        MarketingVisibilityPolicy.metalInicialNovoCase(plan),
        PlanoMarketing.bronze,
      );
    });

    test('valor técnico sem UI é bronze', () {
      expect(
        MarketingVisibilityPolicy.valorTecnicoSemSelecaoUi(),
        PlanoMarketing.bronze,
      );
    });
  });
}