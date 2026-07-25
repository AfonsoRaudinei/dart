import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

void main() {
  group('UserPlan.diasRestantesLabel', () {
    test('plano free (DateTime 9999) não mostra milhões de dias', () {
      final plan = UserPlan.free(userId: 'u1');
      expect(plan.isIndefinite, isTrue);
      expect(plan.diasRestantesLabel, 'Sem expiração');
      expect(plan.expiraEmBreve, isFalse);
    });

    test('plano com expiração real mostra dias', () {
      final plan = UserPlan(
        id: 'p1',
        userId: 'u1',
        plano: PlanoTipo.prata,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime.now(),
        expiraEm: DateTime.now().add(const Duration(days: 47)),
        criadoEm: DateTime.now(),
      );
      expect(plan.isIndefinite, isFalse);
      expect(plan.diasRestantesLabel, contains('dias restantes'));
    });
  });
}
