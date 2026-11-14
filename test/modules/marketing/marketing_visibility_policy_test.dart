import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
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

    test('publicoAteParaMetal segue meses do tier', () {
      final liberado = DateTime.utc(2026, 3, 15, 12);
      expect(
        MarketingVisibilityPolicy.publicoAteParaMetal(
          PlanoMarketing.ouro,
          liberado,
        ),
        DateTime.utc(2026, 9, 15, 12),
      );
      expect(
        MarketingVisibilityPolicy.publicoAteParaMetal(
          PlanoMarketing.prata,
          liberado,
        ),
        DateTime.utc(2026, 7, 15, 12),
      );
      expect(
        MarketingVisibilityPolicy.publicoAteParaMetal(
          PlanoMarketing.bronze,
          liberado,
        ),
        DateTime.utc(2026, 5, 15, 12),
      );
    });

    test('somenteAutorNoMapa enquanto liberado_em é nulo', () {
      final now = DateTime.utc(2026, 1, 1);
      final c = MarketingCase(
        id: 'x',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.ouro,
        lat: 0,
        lng: 0,
        localizacaoTexto: 'L',
        produtorFazenda: 'F',
        produtoUtilizado: 'P',
        status: MarketingCaseStatus.published,
        criadoEm: now,
        atualizadoEm: now,
      );
      expect(
        MarketingVisibilityPolicy.somenteAutorNoMapa(c, 'u1'),
        isTrue,
      );
      final liberado = c.copyWith(
        liberadoEm: now,
        publicoAte: MarketingVisibilityPolicy.publicoAteParaMetal(
          PlanoMarketing.ouro,
          now,
        ),
      );
      expect(
        MarketingVisibilityPolicy.somenteAutorNoMapa(liberado, 'u1'),
        isFalse,
      );
    });

    test('janelaPublicaAtiva respeita publico_ate', () {
      final now = DateTime.utc(2026, 6, 1);
      final base = MarketingCase(
        id: 'x',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.ouro,
        lat: 0,
        lng: 0,
        localizacaoTexto: 'L',
        produtorFazenda: 'F',
        produtoUtilizado: 'P',
        liberadoEm: now,
        publicoAte: DateTime.utc(2026, 12, 1),
        status: MarketingCaseStatus.published,
        criadoEm: now,
        atualizadoEm: now,
      );
      expect(
        MarketingVisibilityPolicy.janelaPublicaAtiva(
          base,
          reference: DateTime.utc(2026, 7, 1),
        ),
        isTrue,
      );
      expect(
        MarketingVisibilityPolicy.janelaPublicaAtiva(
          base,
          reference: DateTime.utc(2027, 1, 2),
        ),
        isFalse,
      );
    });
  });
}