import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/infra/ndvi_refined_entitlement_adapter.dart';

void main() {
  final futureExpiry = DateTime.now().add(const Duration(days: 30));
  final pastExpiry = DateTime.now().subtract(const Duration(days: 1));

  UserPlan plan({
    required PlanoTipo tipo,
    bool ativo = true,
    DateTime? expiraEm,
    bool isAdmin = false,
  }) {
    return UserPlan(
      id: 'p1',
      userId: 'u1',
      plano: tipo,
      origem: PlanoOrigem.pagamento,
      ativo: ativo,
      iniciouEm: DateTime(2026, 1, 1),
      expiraEm: expiraEm ?? futureExpiry,
      criadoEm: DateTime(2026, 1, 1),
      isAdmin: isAdmin,
    );
  }

  test('ouro ativo e vigente habilita refinado', () {
    expect(ndviRefinedEnabledForUserPlan(plan(tipo: PlanoTipo.ouro)), isTrue);
  });

  test('ouro expirado ou inativo nao habilita', () {
    expect(
      ndviRefinedEnabledForUserPlan(
        plan(tipo: PlanoTipo.ouro, expiraEm: pastExpiry),
      ),
      isFalse,
    );
    expect(
      ndviRefinedEnabledForUserPlan(plan(tipo: PlanoTipo.ouro, ativo: false)),
      isFalse,
    );
  });

  test('admin ouro nao ganha refinado', () {
    expect(
      ndviRefinedEnabledForUserPlan(
        plan(tipo: PlanoTipo.ouro, isAdmin: true),
      ),
      isFalse,
    );
  });

  test('bronze e prata nao habilitam refinado', () {
    expect(ndviRefinedEnabledForUserPlan(plan(tipo: PlanoTipo.bronze)), isFalse);
    expect(ndviRefinedEnabledForUserPlan(plan(tipo: PlanoTipo.prata)), isFalse);
  });
}
