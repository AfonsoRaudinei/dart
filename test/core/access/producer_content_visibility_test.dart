import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/access/producer_content_visibility.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_visibility.dart';

void main() {
  group('ProducerContentVisibility', () {
    test('ownsOrLinkedClient aceita autoria própria', () {
      expect(
        ProducerContentVisibility.ownsOrLinkedClient(
          currentUserId: 'prod-1',
          ownerUserId: 'prod-1',
          clientId: null,
          authorizedClientIds: const {},
        ),
        isTrue,
      );
    });

    test('ownsOrLinkedClient aceita client vinculado', () {
      expect(
        ProducerContentVisibility.ownsOrLinkedClient(
          currentUserId: 'prod-1',
          ownerUserId: 'consultor-9',
          clientId: 'client-a',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );
    });

    test('ownsOrLinkedClient rejeita terceiro', () {
      expect(
        ProducerContentVisibility.ownsOrLinkedClient(
          currentUserId: 'prod-1',
          ownerUserId: 'outro',
          clientId: 'client-x',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });

    test('isProducerVisibleVisitStatus só publicado/arquivado', () {
      expect(
        ProducerContentVisibility.isProducerVisibleVisitStatus('publicado'),
        isTrue,
      );
      expect(
        ProducerContentVisibility.isProducerVisibleVisitStatus('arquivado'),
        isTrue,
      );
      expect(
        ProducerContentVisibility.isProducerVisibleVisitStatus(
          'pendente_revisao',
        ),
        isFalse,
      );
    });
  });

  group('MarketingCaseVisibility', () {
    final now = DateTime.utc(2026, 7, 23);

    MarketingCase buildCase({
      String? ownerUserId,
      String? clientId,
      PlanoMarketing visibilidade = PlanoMarketing.prata,
      MarketingCaseStatus status = MarketingCaseStatus.published,
      bool ativo = true,
    }) {
      return MarketingCase(
        id: 'c1',
        tipo: CaseTipo.resultado,
        visibilidade: visibilidade,
        lat: -15,
        lng: -47,
        localizacaoTexto: 'Local',
        produtorFazenda: 'Fazenda',
        produtoUtilizado: 'Produto',
        clientId: clientId,
        ownerUserId: ownerUserId,
        ativo: ativo,
        status: status,
        criadoEm: now,
        atualizadoEm: now,
      );
    }

    test('lista relatórios: próprio e vinculado; exclui terceiro', () {
      final own = buildCase(ownerUserId: 'prod-1');
      final linked = buildCase(
        ownerUserId: 'consultor',
        clientId: 'client-a',
      );
      final other = buildCase(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
      );

      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: own,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: linked,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: other,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });

    test('mapa produtor: inclui Ouro público de terceiro', () {
      final publicOuro = buildCase(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
      );
      final prataOther = buildCase(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.prata,
      );

      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: publicOuro,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: prataOther,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isFalse,
      );
    });
  });
}
