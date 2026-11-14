import 'entities/marketing_case.dart';
import 'enums/plano_marketing.dart';

/// Rank de metal para exibição no mapa (maior = pin preferido no grupo).
/// Ouro (3) > Prata (2) > Bronze (1) — não confundir com ordem do enum Dart.
int marketingMetalDisplayRank(PlanoMarketing metal) {
  switch (metal) {
    case PlanoMarketing.ouro:
      return 3;
    case PlanoMarketing.prata:
      return 2;
    case PlanoMarketing.bronze:
      return 1;
  }
}

/// Id do caso raiz do grupo (`source_case_id` aponta para a publicação original).
String marketingCaseGroupRootId(MarketingCase marketingCase) {
  final source = marketingCase.sourceCaseId;
  if (source != null && source.isNotEmpty) return source;
  return marketingCase.id;
}

/// Por grupo ([marketingCaseGroupRootId]), mantém um único pin: metal mais alto;
/// empate de metal → `atualizado_em` mais recente.
List<MarketingCase> deduplicateHighestMetalPerGroup(
  List<MarketingCase> cases,
) {
  if (cases.length <= 1) return List<MarketingCase>.from(cases);

  final byRoot = <String, List<MarketingCase>>{};
  for (final c in cases) {
    byRoot
        .putIfAbsent(marketingCaseGroupRootId(c), () => [])
        .add(c);
  }

  final winners = <MarketingCase>[];
  for (final group in byRoot.values) {
    if (group.length == 1) {
      winners.add(group.single);
      continue;
    }
    group.sort((a, b) {
      final rank = marketingMetalDisplayRank(b.visibilidade)
          .compareTo(marketingMetalDisplayRank(a.visibilidade));
      if (rank != 0) return rank;
      return b.atualizadoEm.compareTo(a.atualizadoEm);
    });
    winners.add(group.first);
  }
  return winners;
}