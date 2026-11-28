import 'package:soloforte_app/core/contracts/i_drawing_sync_quota.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';

/// Lê [UserPlan.limiteTalhoesSincronizados] após [UserPlanAdminResolver.stamp].
class DrawingSyncQuotaAdapter implements IDrawingSyncQuota {
  const DrawingSyncQuotaAdapter(this._plan);

  final UserPlan _plan;

  /// Fail-closed enquanto o plano com admin ainda não resolveu (fase 3).
  factory DrawingSyncQuotaAdapter.pending() =>
      DrawingSyncQuotaAdapter(UserPlan.free(userId: ''));

  @override
  int? get cloudTalhaoLimit => _plan.limiteTalhoesSincronizados;
}