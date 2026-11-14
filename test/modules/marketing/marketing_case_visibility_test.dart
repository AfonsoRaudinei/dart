import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_visibility.dart';

MarketingCase _case({
  String id = 'c1',
  String? ownerUserId = 'author-1',
  String? clientId = 'client-a',
  PlanoMarketing visibilidade = PlanoMarketing.ouro,
  DateTime? liberadoEm,
  DateTime? publicoAte,
}) {
  final now = DateTime.utc(2026, 6, 1);
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: visibilidade,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Local',
    produtorFazenda: 'Fazenda',
    produtoUtilizado: 'Produto',
    ownerUserId: ownerUserId,
    clientId: clientId,
    liberadoEm: liberadoEm,
    publicoAte: publicoAte,
    status: MarketingCaseStatus.published,
    criadoEm: now,
    atualizadoEm: now,
  );
}

void main() {
  group('MarketingCaseVisibility.isVisibleOnMapForProducer', () {
    test('sem liberado_em: só o autor vê', () {
      final privado = _case(liberadoEm: null, visibilidade: PlanoMarketing.ouro);
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: privado,
          currentUserId: 'author-1',
          authorizedClientIds: const {},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: privado,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });

    test('vinculado exige liberado_em', () {
      final liberado = DateTime.utc(2026, 6, 1);
      final linked = _case(
        ownerUserId: 'consultor-9',
        visibilidade: PlanoMarketing.bronze,
        liberadoEm: liberado,
        publicoAte: liberado.add(const Duration(days: 60)),
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: linked,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );

      final notLiberado = _case(
        ownerUserId: 'consultor-9',
        visibilidade: PlanoMarketing.bronze,
        liberadoEm: null,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: notLiberado,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });

    test('Ouro público exige liberado e janela ativa', () {
      final liberado = DateTime.utc(2026, 6, 1);
      final ativo = _case(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
        liberadoEm: liberado,
        publicoAte: liberado.add(const Duration(days: 180)),
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: ativo,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );

      final semLiberacao = _case(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: semLiberacao,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );

      final expirado = _case(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
        liberadoEm: DateTime.utc(2020, 1, 1),
        publicoAte: DateTime.utc(2020, 7, 1),
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: expirado,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });
  });
}