import 'package:soloforte_app/core/contracts/i_ndvi_refined_entitlement.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';

class NdviRefinedEntitlementAdapter implements INdviRefinedEntitlement {
  const NdviRefinedEntitlementAdapter(this._enabled);

  final bool _enabled;

  @override
  bool get isNdviRefinedEnabled => _enabled;
}

/// Ouro pago ativo e não expirado. Admin não ganha refinado automaticamente.
bool ndviRefinedEnabledForUserPlan(UserPlan plan) {
  if (plan.isAdmin) return false;
  if (!plan.ativo || plan.expirado) return false;
  return plan.plano == PlanoTipo.ouro;
}
