import 'entities/marketing_case.dart';
import 'enums/marketing_case_status.dart';
import '../../planos/domain/entities/user_plan.dart';

/// Regra única de quota de cases publicados (mapa + Relatórios).
class MarketingCaseQuota {
  const MarketingCaseQuota._();

  static int countPublished(Iterable<MarketingCase> cases) {
    return cases
        .where(
          (c) =>
              c.status == MarketingCaseStatus.published &&
              c.ativo &&
              c.deletadoEm == null,
        )
        .length;
  }

  static int limitFor(UserPlan? plan) => plan?.limiteCases ?? 3;

  /// `true` quando o usuário (não-admin) já atingiu o limite do plano.
  static bool isAtLimit({
    required Iterable<MarketingCase> cases,
    required UserPlan? plan,
  }) {
    if (plan?.isAdmin == true) return false;
    return countPublished(cases) >= limitFor(plan);
  }
}
