import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/infra/drawing_sync_quota_adapter.dart';

void main() {
  test('cloudTalhaoLimit delega a UserPlan.limiteTalhoesSincronizados', () {
    final plan = UserPlan(
      id: 'p-prata',
      userId: 'u1',
      plano: PlanoTipo.prata,
      origem: PlanoOrigem.pagamento,
      ativo: true,
      iniciouEm: DateTime(2026),
      expiraEm: DateTime.now().add(const Duration(days: 90)),
      criadoEm: DateTime(2026),
    );
    final adapter = DrawingSyncQuotaAdapter(plan);
    expect(adapter.cloudTalhaoLimit, 500);
  });

  test('pending fail-closed em 0', () {
    expect(DrawingSyncQuotaAdapter.pending().cloudTalhaoLimit, 0);
  });
}