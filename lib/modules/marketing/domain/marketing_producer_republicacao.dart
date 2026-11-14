import '../../../core/access/producer_content_visibility.dart';
import 'entities/marketing_case.dart';
import 'enums/marketing_case_status.dart';

bool producerJaRepublicouFonte({
  required List<MarketingCase> cases,
  required String fonteId,
  required String currentUserId,
}) {
  return cases.any(
    (c) =>
        c.sourceCaseId == fonteId &&
        c.ownerUserId == currentUserId &&
        c.deletadoEm == null,
  );
}

/// Produtor pode clonar publicação do consultor vinculado para publicar com o plano dele.
bool producerRepublicacaoDisponivel({
  required MarketingCase fonte,
  required String currentUserId,
  required Set<String> authorizedClientIds,
  required List<MarketingCase> allCases,
  required bool isProdutor,
}) {
  if (!isProdutor || currentUserId.isEmpty) return false;
  if (fonte.status != MarketingCaseStatus.published ||
      !fonte.ativo ||
      fonte.deletadoEm != null) {
    return false;
  }
  if (fonte.liberadoEm == null) return false;

  final owner = fonte.ownerUserId;
  if (owner == null || owner.isEmpty || owner == currentUserId) return false;

  if (!ProducerContentVisibility.ownsOrLinkedClient(
    currentUserId: currentUserId,
    ownerUserId: owner,
    clientId: fonte.clientId,
    authorizedClientIds: authorizedClientIds,
  )) {
    return false;
  }

  return !producerJaRepublicouFonte(
    cases: allCases,
    fonteId: fonte.id,
    currentUserId: currentUserId,
  );
}