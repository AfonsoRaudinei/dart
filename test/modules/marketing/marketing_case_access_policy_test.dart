import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/domain/marketing_case_access_policy.dart';

MarketingCase _case({
  String id = 'c1',
  String? ownerUserId = 'owner-1',
  String? clientId = 'client-1',
  MarketingCaseStatus status = MarketingCaseStatus.published,
  String? pendingEditJson,
  String? pendingEditBy,
  DateTime? deletadoEm,
}) {
  final now = DateTime.utc(2026, 7, 27);
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Brejinho',
    produtorFazenda: 'Fazenda',
    produtoUtilizado: 'Coach',
    clientId: clientId,
    ownerUserId: ownerUserId,
    status: status,
    criadoEm: now,
    atualizadoEm: now,
    pendingEditJson: pendingEditJson,
    pendingEditBy: pendingEditBy,
    pendingEditAt: pendingEditJson != null ? now : null,
    deletadoEm: deletadoEm,
  );
}

void main() {
  group('MarketingCaseAccessPolicy', () {
    test('owner pode editar e excluir', () {
      final c = _case();
      expect(
        MarketingCaseAccessPolicy.canEditDirect(
          marketingCase: c,
          currentUserId: 'owner-1',
        ),
        isTrue,
      );
      expect(
        MarketingCaseAccessPolicy.canSoftDelete(
          marketingCase: c,
          currentUserId: 'owner-1',
        ),
        isTrue,
      );
      expect(
        MarketingCaseAccessPolicy.canProposeEdit(
          marketingCase: c,
          currentUserId: 'owner-1',
          linkedClientIds: {'client-1'},
        ),
        isFalse,
      );
    });

    test('contraparte vinculada pode propor edição, não excluir', () {
      final c = _case();
      expect(
        MarketingCaseAccessPolicy.canProposeEdit(
          marketingCase: c,
          currentUserId: 'producer-2',
          linkedClientIds: {'client-1'},
        ),
        isTrue,
      );
      expect(
        MarketingCaseAccessPolicy.canSoftDelete(
          marketingCase: c,
          currentUserId: 'producer-2',
        ),
        isFalse,
      );
      expect(
        MarketingCaseAccessPolicy.canEditDirect(
          marketingCase: c,
          currentUserId: 'producer-2',
        ),
        isFalse,
      );
    });

    test('público sem vínculo não edita', () {
      final c = _case();
      expect(
        MarketingCaseAccessPolicy.canEditDirect(
          marketingCase: c,
          currentUserId: '',
        ),
        isFalse,
      );
      expect(
        MarketingCaseAccessPolicy.canProposeEdit(
          marketingCase: c,
          currentUserId: 'stranger',
          linkedClientIds: const {},
        ),
        isFalse,
      );
    });

    test('owner aprova quando há pending_edit', () {
      final c = _case(
        status: MarketingCaseStatus.pendingApproval,
        pendingEditJson: '{"produto_utilizado":"Novo"}',
        pendingEditBy: 'producer-2',
      );
      expect(c.hasPendingEdit, isTrue);
      expect(
        MarketingCaseAccessPolicy.canApproveEdit(
          marketingCase: c,
          currentUserId: 'owner-1',
        ),
        isTrue,
      );
      expect(
        MarketingCaseAccessPolicy.canApproveEdit(
          marketingCase: c,
          currentUserId: 'producer-2',
        ),
        isFalse,
      );
    });

    test('case deletado não é editável', () {
      final c = _case(deletadoEm: DateTime.utc(2026, 7, 1));
      expect(
        MarketingCaseAccessPolicy.canEditDirect(
          marketingCase: c,
          currentUserId: 'owner-1',
        ),
        isFalse,
      );
      expect(MarketingCaseAccessPolicy.canViewResult(c), isFalse);
    });
  });
}
