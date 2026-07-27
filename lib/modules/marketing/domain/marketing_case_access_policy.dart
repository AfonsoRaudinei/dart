import 'entities/marketing_case.dart';
import 'enums/marketing_case_status.dart';

/// ACL de edição / exclusão / aprovação cruzada (ADR-048).
///
/// Neutro de UI — recebe [linkedClientIds] já resolvidos pelo caller
/// (produtor: ADR-041; consultor: IDs de IClientLookup).
class MarketingCaseAccessPolicy {
  const MarketingCaseAccessPolicy._();

  static bool isOwner({
    required MarketingCase marketingCase,
    required String currentUserId,
  }) {
    if (currentUserId.isEmpty) return false;
    final owner = marketingCase.ownerUserId?.trim() ?? '';
    return owner.isNotEmpty && owner == currentUserId;
  }

  /// Contraparte vinculada via `client_id`, sem ser o owner.
  static bool isLinkedCounterpart({
    required MarketingCase marketingCase,
    required String currentUserId,
    required Set<String> linkedClientIds,
  }) {
    if (currentUserId.isEmpty) return false;
    if (isOwner(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
    )) {
      return false;
    }
    final clientId = marketingCase.clientId?.trim() ?? '';
    if (clientId.isEmpty) return false;
    return linkedClientIds.contains(clientId);
  }

  static bool canViewResult(MarketingCase marketingCase) {
    if (marketingCase.deletadoEm != null) return false;
    if (!marketingCase.ativo) return false;
    return marketingCase.status == MarketingCaseStatus.published ||
        marketingCase.status == MarketingCaseStatus.pendingApproval;
  }

  static bool canEditDirect({
    required MarketingCase marketingCase,
    required String currentUserId,
  }) {
    if (!canViewResult(marketingCase)) return false;
    return isOwner(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
    );
  }

  static bool canProposeEdit({
    required MarketingCase marketingCase,
    required String currentUserId,
    required Set<String> linkedClientIds,
  }) {
    if (!canViewResult(marketingCase)) return false;
    if (marketingCase.status == MarketingCaseStatus.pendingApproval) {
      return false;
    }
    return isLinkedCounterpart(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
      linkedClientIds: linkedClientIds,
    );
  }

  static bool canApproveEdit({
    required MarketingCase marketingCase,
    required String currentUserId,
  }) {
    if (!isOwner(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
    )) {
      return false;
    }
    return marketingCase.status == MarketingCaseStatus.pendingApproval &&
        marketingCase.hasPendingEdit;
  }

  static bool canSoftDelete({
    required MarketingCase marketingCase,
    required String currentUserId,
  }) {
    if (marketingCase.deletadoEm != null) return false;
    return isOwner(
      marketingCase: marketingCase,
      currentUserId: currentUserId,
    );
  }
}
