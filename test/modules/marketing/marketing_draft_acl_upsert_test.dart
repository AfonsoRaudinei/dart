import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_visibility.dart';

void main() {
  group('MarketingCaseVisibility drafts ACL', () {
    test('produtor vê draft próprio', () {
      final draft = _case(
        id: 'd1',
        status: MarketingCaseStatus.draft,
        ownerUserId: 'user-a',
        clientId: 'client-1',
      );

      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: draft,
          currentUserId: 'user-a',
          authorizedClientIds: const {},
        ),
        isTrue,
      );
    });

    test('produtor não vê draft de outro sem vínculo de cliente', () {
      final draft = _case(
        id: 'd2',
        status: MarketingCaseStatus.draft,
        ownerUserId: 'user-b',
        clientId: 'client-x',
      );

      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: draft,
          currentUserId: 'user-a',
          authorizedClientIds: const {'client-1'},
        ),
        isFalse,
      );
    });

    test('produtor vê draft do consultor via client_id autorizado', () {
      final draft = _case(
        id: 'd3',
        status: MarketingCaseStatus.draft,
        ownerUserId: 'consultor',
        clientId: 'client-1',
      );

      expect(
        MarketingCaseVisibility.isVisibleInReports(
          marketingCase: draft,
          currentUserId: 'user-a',
          authorizedClientIds: const {'client-1'},
        ),
        isTrue,
      );
    });
  });

  group('publishCase upsert semantics', () {
    test('substituir por id não duplica entradas', () {
      final now = DateTime.utc(2026, 8, 13);
      final draft = _case(
        id: 'same',
        status: MarketingCaseStatus.draft,
        ownerUserId: 'u1',
        criadoEm: now,
      );
      final published = MarketingCase.fromJson({
        ...draft.toJson(),
        'status': MarketingCaseStatus.published.toValue(),
      });

      final list = [draft];
      final upserted = _upsertById(list, published);

      expect(upserted, hasLength(1));
      expect(upserted.single.id, 'same');
      expect(upserted.single.status, MarketingCaseStatus.published);
    });
  });
}

List<MarketingCase> _upsertById(
  List<MarketingCase> cases,
  MarketingCase item,
) {
  final index = cases.indexWhere((c) => c.id == item.id);
  if (index < 0) return [...cases, item];
  final next = List<MarketingCase>.from(cases);
  next[index] = item;
  return next;
}

MarketingCase _case({
  required String id,
  required MarketingCaseStatus status,
  required String ownerUserId,
  String? clientId,
  DateTime? criadoEm,
}) {
  final now = criadoEm ?? DateTime.utc(2026, 8, 13);
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.bronze,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas - TO',
    produtorFazenda: 'Produtor',
    produtoUtilizado: 'coach',
    dataCase: now,
    clientId: clientId,
    ownerUserId: ownerUserId,
    status: status,
    criadoEm: now,
    atualizadoEm: now,
  );
}
