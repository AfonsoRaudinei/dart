import '../../../../core/contracts/i_client_lookup.dart';
import '../../../../core/contracts/i_farm_lookup.dart';

/// Estatísticas de cobertura de `client_id` em marketing cases.
class MarketingCaseClientIdCoverage {
  final int total;
  final int withClientId;
  final int withoutClientId;

  const MarketingCaseClientIdCoverage({
    required this.total,
    required this.withClientId,
    required this.withoutClientId,
  });

  double get percentWithClientId =>
      total == 0 ? 100 : (withClientId / total) * 100;

  factory MarketingCaseClientIdCoverage.audit(Iterable<String?> clientIds) {
    var withId = 0;
    var withoutId = 0;
    for (final raw in clientIds) {
      if (raw != null && raw.trim().isNotEmpty) {
        withId++;
      } else {
        withoutId++;
      }
    }
    return MarketingCaseClientIdCoverage(
      total: withId + withoutId,
      withClientId: withId,
      withoutClientId: withoutId,
    );
  }

  String toReportLine(String phase) {
    return '$phase: $withClientId/$total com client_id '
        '(${percentWithClientId.toStringAsFixed(1)}%)';
  }
}

String normalizeMarketingLabel(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Resolve `clientId` a partir de `produtor_fazenda` sem inventar dados.
///
/// Ordem: match único por nome de cliente → padrão "Cliente - Fazenda" →
/// match único por nome de fazenda.
String? resolveMarketingCaseClientId({
  required String produtorFazenda,
  required List<ClientSummary> clients,
  required Map<String, List<FarmSummary>> farmsByClientId,
}) {
  final label = normalizeMarketingLabel(produtorFazenda);
  if (label.isEmpty) return null;

  final activeClients = clients.where((client) => client.active).toList();
  if (activeClients.isEmpty) return null;

  final byClientName = _matchClientsByName(label, activeClients);
  if (byClientName.length == 1) return byClientName.first.id;

  final splitMatch = _matchByProducerFarmSplit(label, activeClients, farmsByClientId);
  if (splitMatch != null) return splitMatch;

  final byFarm = _matchClientByUniqueFarmName(label, farmsByClientId);
  if (byFarm != null) return byFarm;

  return null;
}

List<ClientSummary> _matchClientsByName(
  String label,
  List<ClientSummary> clients,
) {
  final matches = <ClientSummary>[];
  for (final client in clients) {
    final name = normalizeMarketingLabel(client.name);
    if (name.isEmpty) continue;
    if (label == name || label.startsWith('$name - ') || label.contains(' $name ')) {
      matches.add(client);
      continue;
    }
    if (label.contains(name)) {
      matches.add(client);
    }
  }
  return _uniqueClients(matches);
}

String? _matchByProducerFarmSplit(
  String label,
  List<ClientSummary> clients,
  Map<String, List<FarmSummary>> farmsByClientId,
) {
  final separatorIndex = label.indexOf(' - ');
  if (separatorIndex <= 0) return null;

  final clientPart = label.substring(0, separatorIndex).trim();
  final farmPart = label.substring(separatorIndex + 3).trim();
  if (clientPart.isEmpty) return null;

  final clientMatches = clients
      .where((client) => normalizeMarketingLabel(client.name) == clientPart)
      .toList();
  if (clientMatches.length != 1) return null;

  final clientId = clientMatches.first.id;
  if (farmPart.isEmpty) return clientId;

  final farms = farmsByClientId[clientId] ?? const [];
  final farmMatches = farms
      .where((farm) => normalizeMarketingLabel(farm.name) == farmPart)
      .toList();
  if (farmMatches.isEmpty) {
    return clientId;
  }
  if (farmMatches.length == 1 && farmMatches.first.clientId == clientId) {
    return clientId;
  }
  return null;
}

String? _matchClientByUniqueFarmName(
  String label,
  Map<String, List<FarmSummary>> farmsByClientId,
) {
  String? matchedClientId;
  for (final entry in farmsByClientId.entries) {
    for (final farm in entry.value) {
      final farmName = normalizeMarketingLabel(farm.name);
      if (farmName.isEmpty) continue;
      if (!label.contains(farmName)) continue;
      if (matchedClientId != null && matchedClientId != entry.key) {
        return null;
      }
      matchedClientId = entry.key;
    }
  }
  return matchedClientId;
}

List<ClientSummary> _uniqueClients(List<ClientSummary> clients) {
  final seen = <String>{};
  final unique = <ClientSummary>[];
  for (final client in clients) {
    if (seen.add(client.id)) unique.add(client);
  }
  return unique;
}
