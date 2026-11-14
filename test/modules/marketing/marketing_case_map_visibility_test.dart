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
  MarketingCaseStatus status = MarketingCaseStatus.published,
  bool ativo = true,
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
    status: status,
    ativo: ativo,
    criadoEm: now,
    atualizadoEm: now,
  );
}

void main() {
  final liberado = DateTime.utc(2026, 6, 1);
  final janelaAtivaAte = liberado.add(const Duration(days: 200));
  final janelaExpiradaAte = DateTime.utc(2020, 7, 1);
  final expiradoLiberado = DateTime.utc(2020, 1, 1);

  group('pin — dono sempre vê', () {
    test('expirado ou sem liberado_em', () {
      final expirado = _case(
        visibilidade: PlanoMarketing.prata,
        liberadoEm: expiradoLiberado,
        publicoAte: janelaExpiradaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForConsultant(
          marketingCase: expirado,
          currentUserId: 'author-1',
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: _case(liberadoEm: null),
          currentUserId: 'author-1',
          authorizedClientIds: const {},
        ),
        isTrue,
      );
    });
  });

  group('Ouro', () {
    test('terceiro produtor com janela ativa', () {
      final ouro = _case(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
        liberadoEm: liberado,
        publicoAte: janelaAtivaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: ouro,
          currentUserId: 'prod-1',
          authorizedClientIds: const {},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForConsultant(
          marketingCase: ouro,
          currentUserId: 'cons-1',
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForAnonymous(marketingCase: ouro),
        isTrue,
      );
    });

    test('expirado: só autor', () {
      final ouro = _case(
        ownerUserId: 'outro',
        clientId: 'client-z',
        visibilidade: PlanoMarketing.ouro,
        liberadoEm: expiradoLiberado,
        publicoAte: janelaExpiradaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: ouro,
          currentUserId: 'prod-1',
          authorizedClientIds: const {},
        ),
        isFalse,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForAnonymous(marketingCase: ouro),
        isFalse,
      );
    });
  });

  group('Prata', () {
    test('logados com janela ativa; anônimo não', () {
      final prata = _case(
        ownerUserId: 'outro',
        visibilidade: PlanoMarketing.prata,
        liberadoEm: liberado,
        publicoAte: janelaAtivaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: prata,
          currentUserId: 'prod-1',
          authorizedClientIds: const {},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForConsultant(
          marketingCase: prata,
          currentUserId: 'cons-2',
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForAnonymous(marketingCase: prata),
        isFalse,
      );
    });

    test('expirada: só autor', () {
      final prata = _case(
        visibilidade: PlanoMarketing.prata,
        liberadoEm: expiradoLiberado,
        publicoAte: janelaExpiradaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForConsultant(
          marketingCase: prata,
          currentUserId: 'cons-2',
        ),
        isFalse,
      );
    });
  });

  group('Bronze', () {
    test('produtor vinculado com janela ativa', () {
      final bronze = _case(
        ownerUserId: 'consultor-9',
        clientId: 'client-a',
        visibilidade: PlanoMarketing.bronze,
        liberadoEm: liberado,
        publicoAte: janelaAtivaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: bronze,
          currentUserId: 'prod-1',
          authorizedClientIds: const {'client-a'},
        ),
        isTrue,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForProducer(
          marketingCase: bronze,
          currentUserId: 'prod-9',
          authorizedClientIds: const {},
        ),
        isFalse,
      );
    });

    test('consultor não autor não vê bronze de terceiro', () {
      final bronze = _case(
        ownerUserId: 'consultor-9',
        visibilidade: PlanoMarketing.bronze,
        liberadoEm: liberado,
        publicoAte: janelaAtivaAte,
      );
      expect(
        MarketingCaseVisibility.isVisibleOnMapForConsultant(
          marketingCase: bronze,
          currentUserId: 'cons-outro',
        ),
        isFalse,
      );
    });
  });
}