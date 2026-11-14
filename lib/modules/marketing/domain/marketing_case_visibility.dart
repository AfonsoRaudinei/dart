import '../../../core/access/producer_content_visibility.dart';
import 'entities/marketing_case.dart';
import 'enums/marketing_case_status.dart';
import 'enums/plano_marketing.dart';
import 'marketing_visibility_policy.dart';

/// Filtros de visibilidade de [MarketingCase] para o perfil produtor.
class MarketingCaseVisibility {
  const MarketingCaseVisibility._();

  /// Lista Relatórios: próprios + do consultor vinculado (via client_id).
  static bool isVisibleInReports({
    required MarketingCase marketingCase,
    required String currentUserId,
    required Set<String> authorizedClientIds,
  }) {
    return ProducerContentVisibility.ownsOrLinkedClient(
      currentUserId: currentUserId,
      ownerUserId: marketingCase.ownerUserId,
      clientId: marketingCase.clientId,
      authorizedClientIds: authorizedClientIds,
    );
  }

  /// Mapa privado (produtor): próprios/vinculados + Ouro público.
  static bool isVisibleOnMapForProducer({
    required MarketingCase marketingCase,
    required String currentUserId,
    required Set<String> authorizedClientIds,
  }) {
    if (marketingCase.deletadoEm != null) return false;
    if (!marketingCase.ativo) return false;
    if (marketingCase.status != MarketingCaseStatus.published) return false;

    if (MarketingVisibilityPolicy.somenteAutorNoMapa(
      marketingCase,
      currentUserId,
    )) {
      final owner = marketingCase.ownerUserId;
      return owner != null &&
          owner.isNotEmpty &&
          owner == currentUserId;
    }

    if (isVisibleInReports(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
      authorizedClientIds: authorizedClientIds,
    )) {
      return true;
    }

    if (marketingCase.visibilidade == PlanoMarketing.ouro) {
      return MarketingVisibilityPolicy.janelaPublicaAtiva(marketingCase);
    }

    return false;
  }
}
