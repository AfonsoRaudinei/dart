import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/infra/user_plan_admin_resolver.dart';
import 'package:supabase/supabase.dart';

void main() {
  UserPlan bronze() => UserPlan(
    id: 'p1',
    userId: 'u1',
    plano: PlanoTipo.bronze,
    origem: PlanoOrigem.pagamento,
    ativo: true,
    iniciouEm: DateTime(2026),
    expiraEm: DateTime.now().add(const Duration(days: 90)),
    criadoEm: DateTime(2026),
  );

  test('stampJwt admin em appMetadata', () {
    final user = User(
      id: 'u1',
      appMetadata: const {'role': 'Admin'},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
    );
    final stamped = UserPlanAdminResolver.stampJwt(bronze(), user);
    expect(stamped.isAdmin, isTrue);
    expect(stamped.limiteTalhoesSincronizados, isNull);
  });

  test('stampJwt sem admin mantém plano', () {
    final stamped = UserPlanAdminResolver.stampJwt(bronze(), null);
    expect(stamped.isAdmin, isFalse);
    expect(stamped.limiteTalhoesSincronizados, 150);
  });

  test('isAdminRole ignora caixa', () {
    expect(UserPlanAdminResolver.isAdminRole('ADMIN'), isTrue);
    expect(UserPlanAdminResolver.isAdminRole('consultor'), isFalse);
  });
}