import '../../../core/access/producer_content_visibility.dart';
import 'entities/marketing_case.dart';
import 'enums/marketing_case_status.dart';
import 'enums/plano_marketing.dart';
import 'marketing_visibility_policy.dart';

/// Filtros de visibilidade de [MarketingCase] (relatórios e pin no mapa).
class MarketingCaseVisibility {
  const MarketingCaseVisibility._();

  static bool _pinPreRequisitos(MarketingCase marketingCase) {
    if (marketingCase.deletadoEm != null) return false;
    if (!marketingCase.ativo) return false;
    if (marketingCase.status != MarketingCaseStatus.published) return false;
    return true;
  }

  static bool _isOwner(MarketingCase marketingCase, String currentUserId) {
    final owner = marketingCase.ownerUserId;
    return owner != null && owner.isNotEmpty && owner == currentUserId;
  }

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

  /// Mapa privado (produtor logado) — docs/case.md «Quem vê o pin».
  static bool isVisibleOnMapForProducer({
    required MarketingCase marketingCase,
    required String currentUserId,
    required Set<String> authorizedClientIds,
    DateTime? reference,
  }) {
    if (!_pinPreRequisitos(marketingCase)) return false;
    if (_isOwner(marketingCase, currentUserId)) return true;

    if (MarketingVisibilityPolicy.somenteAutorNoMapa(
      marketingCase,
      currentUserId,
    )) {
      return false;
    }

    final janelaAtiva = MarketingVisibilityPolicy.janelaPublicaAtiva(
      marketingCase,
      reference: reference,
    );
    if (!janelaAtiva) return false;

    return switch (marketingCase.visibilidade) {
      PlanoMarketing.ouro || PlanoMarketing.prata => true,
      PlanoMarketing.bronze => isVisibleInReports(
        marketingCase: marketingCase,
        currentUserId: currentUserId,
        authorizedClientIds: authorizedClientIds,
      ),
    };
  }

  /// Mapa privado (consultor logado). Consultor não vê bronze de terceiros.
  static bool isVisibleOnMapForConsultant({
    required MarketingCase marketingCase,
    required String currentUserId,
    DateTime? reference,
  }) {
    if (!_pinPreRequisitos(marketingCase)) return false;
    if (_isOwner(marketingCase, currentUserId)) return true;

    if (MarketingVisibilityPolicy.somenteAutorNoMapa(
      marketingCase,
      currentUserId,
    )) {
      return false;
    }

    final janelaAtiva = MarketingVisibilityPolicy.janelaPublicaAtiva(
      marketingCase,
      reference: reference,
    );
    if (!janelaAtiva) return false;

    return switch (marketingCase.visibilidade) {
      PlanoMarketing.ouro || PlanoMarketing.prata => true,
      PlanoMarketing.bronze => false,
    };
  }

  /// Mapa público sem login: só Ouro liberado com janela ativa.
  static bool isVisibleOnMapForAnonymous({
    required MarketingCase marketingCase,
    DateTime? reference,
  }) {
    if (!_pinPreRequisitos(marketingCase)) return false;
    if (marketingCase.visibilidade != PlanoMarketing.ouro) return false;
    if (MarketingVisibilityPolicy.somenteAutorNoMapa(
      marketingCase,
      '',
    )) {
      return false;
    }
    return MarketingVisibilityPolicy.janelaPublicaAtiva(
      marketingCase,
      reference: reference,
    );
  }
}