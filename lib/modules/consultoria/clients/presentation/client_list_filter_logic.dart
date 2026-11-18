import '../domain/client.dart';
import '../domain/client_cultura.dart';
import '../domain/enums/cultura_tipo.dart';

/// Faixas de área (hectares) para filtro avançado da lista de clientes.
enum ClientListAreaRange {
  ate100,
  de100a500,
  de500a2000,
  acima2000,
}

extension ClientListAreaRangeDisplay on ClientListAreaRange {
  String get label => switch (this) {
    ClientListAreaRange.ate100 => 'Até 100 ha',
    ClientListAreaRange.de100a500 => '100–500 ha',
    ClientListAreaRange.de500a2000 => '500–2.000 ha',
    ClientListAreaRange.acima2000 => 'Acima de 2.000 ha',
  };
}

/// Chave canônica de cidade+UF para multi-select.
String clientCityKey(Client client) =>
    '${client.city.trim()}|${client.state.trim()}';

String clientCityKeyLabel(String key) {
  final sep = key.indexOf('|');
  if (sep < 0) return key;
  final cidade = key.substring(0, sep);
  final uf = key.substring(sep + 1);
  if (cidade.isEmpty && uf.isEmpty) return 'Sem cidade';
  if (cidade.isEmpty) return uf;
  if (uf.isEmpty) return cidade;
  return '$cidade - $uf';
}

/// Filtros avançados (AND entre dimensões; OR dentro de cidade e cultura).
class ClientListAdvancedFilters {
  final Set<String> cityKeys;
  final Set<CulturaTipo> culturas;
  final ClientListAreaRange? areaRange;

  const ClientListAdvancedFilters({
    this.cityKeys = const {},
    this.culturas = const {},
    this.areaRange,
  });

  bool get hasAny =>
      cityKeys.isNotEmpty || culturas.isNotEmpty || areaRange != null;

  int get activeChipCount =>
      cityKeys.length + culturas.length + (areaRange != null ? 1 : 0);

  ClientListAdvancedFilters copyWith({
    Set<String>? cityKeys,
    Set<CulturaTipo>? culturas,
    ClientListAreaRange? areaRange,
    bool clearAreaRange = false,
  }) {
    return ClientListAdvancedFilters(
      cityKeys: cityKeys ?? this.cityKeys,
      culturas: culturas ?? this.culturas,
      areaRange: clearAreaRange ? null : (areaRange ?? this.areaRange),
    );
  }

  ClientListAdvancedFilters cleared() => const ClientListAdvancedFilters();
}

/// Linha unificada de cultura por cliente (talhões primeiro, senão client_culturas).
class ClientListCulturaRow {
  final CulturaTipo tipo;
  final double areaHa;

  const ClientListCulturaRow({required this.tipo, required this.areaHa});
}

/// Filtro de cultura/área por cultura exige índice unificado (async).
bool advancedFilterNeedsCulturaIndex(ClientListAdvancedFilters advanced) =>
    advanced.culturas.isNotEmpty;

List<ClientListCulturaRow> clientListCulturasFromDrawingRows(
  List<({String cultura, double areaHa})> rows,
) {
  final acc = <CulturaTipo, double>{};
  for (final row in rows) {
    final raw = row.cultura.trim();
    if (raw.isEmpty) continue;
    final tipo = CulturaTipo.matchStored(raw);
    if (tipo == null || tipo == CulturaTipo.outro) continue;
    acc[tipo] = (acc[tipo] ?? 0) + row.areaHa;
  }
  return acc.entries
      .map((e) => ClientListCulturaRow(tipo: e.key, areaHa: e.value))
      .toList(growable: false);
}

List<ClientListCulturaRow> clientListCulturasFromClientCulturas(
  List<ClientCultura> list,
) {
  return list
      .map((c) => ClientListCulturaRow(tipo: c.culturaTipo, areaHa: c.areaHa))
      .where((r) => r.tipo != CulturaTipo.outro)
      .toList(growable: false);
}

/// Talhões (drawings) primeiro; fallback para [client_culturas] como no detalhe.
Map<String, List<ClientListCulturaRow>> buildClientListCulturaIndex({
  required Map<String, List<({String cultura, double areaHa})>>
  drawingsByClientId,
  required Map<String, List<ClientCultura>> culturasByClientId,
}) {
  final allIds = {
    ...drawingsByClientId.keys,
    ...culturasByClientId.keys,
  };
  final result = <String, List<ClientListCulturaRow>>{};
  for (final id in allIds) {
    final drawingRows = drawingsByClientId[id] ?? const [];
    if (drawingRows.isNotEmpty) {
      result[id] = clientListCulturasFromDrawingRows(drawingRows);
    } else {
      final culturas = culturasByClientId[id] ?? const [];
      result[id] = clientListCulturasFromClientCulturas(culturas);
    }
  }
  return result;
}

bool areaHaMatchesRange(ClientListAreaRange range, double areaHa) {
  return switch (range) {
    ClientListAreaRange.ate100 => areaHa > 0 && areaHa <= 100,
    ClientListAreaRange.de100a500 => areaHa > 100 && areaHa <= 500,
    ClientListAreaRange.de500a2000 => areaHa > 500 && areaHa <= 2000,
    ClientListAreaRange.acima2000 => areaHa > 2000,
  };
}

double? resolveAreaHaForFilter({
  required Client client,
  required ClientListAdvancedFilters advanced,
  required List<ClientListCulturaRow> culturas,
}) {
  if (advanced.culturas.isNotEmpty) {
    final matching = culturas.where(
      (c) => advanced.culturas.contains(c.tipo),
    );
    if (matching.isEmpty) return null;
    return matching.fold<double>(0, (sum, c) => sum + c.areaHa);
  }
  return client.areaTotal;
}

bool clientMatchesAdvancedFilters({
  required Client client,
  required ClientListAdvancedFilters advanced,
  required List<ClientListCulturaRow> culturas,
}) {
  if (!advanced.hasAny) return true;

  if (advanced.cityKeys.isNotEmpty) {
    final city = client.city.trim();
    final state = client.state.trim();
    if (city.isEmpty && state.isEmpty) return false;
    final key = clientCityKey(client);
    if (!advanced.cityKeys.contains(key)) return false;
  }

  if (advanced.culturas.isNotEmpty) {
    final hasMatch = culturas.any(
      (c) => advanced.culturas.contains(c.tipo),
    );
    if (!hasMatch) return false;
  }

  if (advanced.areaRange != null) {
    final areaHa = resolveAreaHaForFilter(
      client: client,
      advanced: advanced,
      culturas: culturas,
    );
    if (areaHa == null) return false;
    if (!areaHaMatchesRange(advanced.areaRange!, areaHa)) return false;
  }

  return true;
}

/// Filtra clientes por busca, status (Todos/Ativos/Inativos) e filtros avançados.
List<Client> applyClientListFilters({
  required List<Client> clients,
  required String statusFilter,
  required String search,
  required ClientListAdvancedFilters advanced,
  required Map<String, List<ClientListCulturaRow>> culturasByClientId,
}) {
  final searchLower = search.toLowerCase();

  return clients.where((c) {
    final matchesSearch = searchLower.isEmpty ||
        c.name.toLowerCase().contains(searchLower);
    final matchesFilter =
        statusFilter == 'Todos' ||
        (statusFilter == 'Ativos' && c.active) ||
        (statusFilter == 'Inativos' && !c.active);

    if (!matchesSearch || !matchesFilter) return false;

    final culturas = culturasByClientId[c.id] ?? const [];
    return clientMatchesAdvancedFilters(
      client: c,
      advanced: advanced,
      culturas: culturas,
    );
  }).toList();
}

/// Cidades distintas (cidade+UF) dos clientes, ordenadas por rótulo.
List<String> distinctClientCityKeys(List<Client> clients) {
  final keys = <String>{};
  for (final c in clients) {
    final city = c.city.trim();
    final state = c.state.trim();
    if (city.isEmpty && state.isEmpty) continue;
    keys.add(clientCityKey(c));
  }
  final list = keys.toList()
    ..sort((a, b) => clientCityKeyLabel(a).compareTo(clientCityKeyLabel(b)));
  return list;
}