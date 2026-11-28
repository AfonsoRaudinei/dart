import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/access/producer_link_occurrence_policy.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

UserPlan _paid({bool admin = false}) => UserPlan(
  id: 'plan-1',
  userId: 'u1',
  plano: PlanoTipo.bronze,
  origem: PlanoOrigem.pagamento,
  ativo: true,
  isAdmin: admin,
  iniciouEm: DateTime.utc(2026, 1, 1),
  expiraEm: DateTime.now().add(const Duration(days: 365)),
  criadoEm: DateTime.utc(2026, 1, 1),
);

void main() {
  group('ProducerLinkOccurrencePolicy', () {
    test('free não compartilha ocorrência', () {
      final free = UserPlan.free(userId: 'u1');
      expect(
        ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
          isAdmin: free.isAdmin,
          planId: free.id,
          ocultaPinsMarketingNoMapa: free.ocultaPinsMarketingNoMapa,
        ),
        isFalse,
      );
    });

    test('bronze pago ativo compartilha', () {
      final paid = _paid();
      expect(
        ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
          isAdmin: paid.isAdmin,
          planId: paid.id,
          ocultaPinsMarketingNoMapa: paid.ocultaPinsMarketingNoMapa,
        ),
        isTrue,
      );
    });

    test('expirado não compartilha', () {
      final expired = UserPlan(
        id: 'plan-x',
        userId: 'u1',
        plano: PlanoTipo.ouro,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime.utc(2020, 1, 1),
        expiraEm: DateTime.utc(2020, 6, 1),
        criadoEm: DateTime.utc(2020, 1, 1),
      );
      expect(expired.ocultaPinsMarketingNoMapa, isTrue);
      expect(
        ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
          isAdmin: expired.isAdmin,
          planId: expired.id,
          ocultaPinsMarketingNoMapa: expired.ocultaPinsMarketingNoMapa,
        ),
        isFalse,
      );
    });

    test('admin compartilha mesmo sem plano pago', () {
      final admin = _paid(admin: true);
      expect(
        ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
          isAdmin: admin.isAdmin,
          planId: 'free',
          ocultaPinsMarketingNoMapa: true,
        ),
        isTrue,
      );
    });

    test('usuarioPodeAcessar espelha consultor (produtor ver)', () {
      final free = UserPlan.free(userId: 'u1');
      final paid = _paid();
      expect(
        ProducerLinkOccurrencePolicy.usuarioPodeAcessarOcorrenciasNoVinculo(
          isAdmin: free.isAdmin,
          planId: free.id,
          ocultaPinsMarketingNoMapa: free.ocultaPinsMarketingNoMapa,
        ),
        ProducerLinkOccurrencePolicy.consultorPodeCompartilharOcorrencia(
          isAdmin: free.isAdmin,
          planId: free.id,
          ocultaPinsMarketingNoMapa: free.ocultaPinsMarketingNoMapa,
        ),
      );
      expect(
        ProducerLinkOccurrencePolicy.usuarioPodeAcessarOcorrenciasNoVinculo(
          isAdmin: paid.isAdmin,
          planId: paid.id,
          ocultaPinsMarketingNoMapa: paid.ocultaPinsMarketingNoMapa,
        ),
        isTrue,
      );
    });
  });
}
