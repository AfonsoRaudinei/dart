import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

void main() {
  group('Marketing reports draft visibility', () {
    test('draft case is eligible for relatorios list filter', () {
      final now = DateTime.utc(2026, 8, 13);
      final draft = MarketingCase(
        id: 'draft-1',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.bronze,
        lat: -10.0,
        lng: -48.0,
        localizacaoTexto: 'Palmas - TO',
        produtorFazenda: 'RAUDINEI',
        produtoUtilizado: 'coach',
        dataCase: now,
        status: MarketingCaseStatus.draft,
        criadoEm: now,
        atualizadoEm: now,
      );

      expect(draft.status, MarketingCaseStatus.draft);
      expect(draft.deletadoEm, isNull);
      expect(draft.ativo, isTrue);
    });

    test('published case remains published status', () {
      final now = DateTime.utc(2026, 8, 13);
      final published = MarketingCase(
        id: 'pub-1',
        tipo: CaseTipo.resultado,
        visibilidade: PlanoMarketing.prata,
        lat: -10.0,
        lng: -48.0,
        localizacaoTexto: 'Palmas - TO',
        produtorFazenda: 'Augusto',
        produtoUtilizado: 'coach',
        dataCase: now,
        status: MarketingCaseStatus.published,
        criadoEm: now,
        atualizadoEm: now,
      );

      expect(published.status, MarketingCaseStatus.published);
    });
  });
}
