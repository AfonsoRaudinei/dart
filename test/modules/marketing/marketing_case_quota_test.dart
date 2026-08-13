import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_quota.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

void main() {
  group('MarketingCaseQuota', () {
    final now = DateTime.utc(2026, 8, 13);

    MarketingCase published(String id) => MarketingCase(
      id: id,
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.bronze,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'TO',
      produtorFazenda: 'P',
      produtoUtilizado: 'X',
      dataCase: now,
      status: MarketingCaseStatus.published,
      criadoEm: now,
      atualizadoEm: now,
    );

    MarketingCase draft(String id) => MarketingCase(
      id: id,
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.bronze,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'TO',
      produtorFazenda: 'P',
      produtoUtilizado: 'X',
      dataCase: now,
      status: MarketingCaseStatus.draft,
      criadoEm: now,
      atualizadoEm: now,
    );

    test('conta apenas published ativos', () {
      final cases = [
        published('1'),
        published('2'),
        draft('3'),
        MarketingCase.fromJson({
          ...published('4').toJson(),
          'ativo': false,
        }),
      ];
      expect(MarketingCaseQuota.countPublished(cases), 2);
    });

    test('bronze atinge limite em 3 publicados', () {
      final plan = UserPlan.free(userId: 'u1');
      final cases = [published('1'), published('2'), published('3')];
      expect(MarketingCaseQuota.isAtLimit(cases: cases, plan: plan), isTrue);
      expect(MarketingCaseQuota.limitFor(plan), 3);
    });

    test('admin nunca está no limite', () {
      final plan = UserPlan(
        id: 'admin',
        userId: 'u1',
        plano: PlanoTipo.bronze,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: now,
        expiraEm: DateTime(9999),
        criadoEm: now,
        isAdmin: true,
      );
      final cases = [published('1'), published('2'), published('3'), published('4')];
      expect(MarketingCaseQuota.isAtLimit(cases: cases, plan: plan), isFalse);
    });
  });
}
