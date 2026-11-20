import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client_cultura.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/enums/cultura_tipo.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/client_list_filter_logic.dart';

Client _client({
  required String id,
  String name = 'Cliente',
  String city = 'Cascavel',
  String state = 'PR',
  bool active = true,
  double? areaTotal,
}) {
  return Client(
    id: id,
    name: name,
    phone: '999',
    city: city,
    state: state,
    createdAt: DateTime(2024),
    active: active,
    areaTotal: areaTotal,
  );
}

ClientCultura _cultura({
  required String clientId,
  CulturaTipo tipo = CulturaTipo.soja,
  double areaHa = 50,
}) {
  final now = DateTime(2024);
  return ClientCultura(
    id: '${clientId}_${tipo.name}',
    clientId: clientId,
    cultura: tipo.name,
    areaHa: areaHa,
    createdAt: now,
    updatedAt: now,
  );
}

List<ClientListCulturaRow> _rows(List<ClientListCulturaRow> rows) => rows;

void main() {
  group('buildClientListCulturaIndex', () {
    test('drawings prevalecem sobre client_culturas', () {
      const clientId = 'c1';
      final index = buildClientListCulturaIndex(
        drawingsByClientId: {
          clientId: [
            (cultura: 'Soja', areaHa: 80.0),
            (cultura: 'Milho', areaHa: 40.0),
          ],
        },
        culturasByClientId: {
          clientId: [
            _cultura(clientId: clientId, tipo: CulturaTipo.soja, areaHa: 500),
          ],
        },
      );

      final rows = index[clientId]!;
      expect(rows, hasLength(2));
      expect(
        rows.firstWhere((r) => r.tipo == CulturaTipo.soja).areaHa,
        80.0,
      );
      expect(
        rows.firstWhere((r) => r.tipo == CulturaTipo.milho).areaHa,
        40.0,
      );
    });

    test('sem drawings usa client_culturas', () {
      const clientId = 'c2';
      final index = buildClientListCulturaIndex(
        drawingsByClientId: const {},
        culturasByClientId: {
          clientId: [
            _cultura(clientId: clientId, tipo: CulturaTipo.trigo, areaHa: 12),
          ],
        },
      );

      expect(index[clientId]!.single.tipo, CulturaTipo.trigo);
      expect(index[clientId]!.single.areaHa, 12);
    });

    test('matchStored agrega labels de drawing', () {
      const clientId = 'c3';
      final index = buildClientListCulturaIndex(
        drawingsByClientId: {
          clientId: [
            (cultura: 'soja', areaHa: 30.0),
            (cultura: 'Soja', areaHa: 20.0),
          ],
        },
        culturasByClientId: const {},
      );

      expect(index[clientId]!.single.tipo, CulturaTipo.soja);
      expect(index[clientId]!.single.areaHa, 50.0);
    });
  });

  group('areaHaMatchesRange', () {
    test('faixas de área', () {
      expect(areaHaMatchesRange(ClientListAreaRange.ate100, 80), isTrue);
      expect(areaHaMatchesRange(ClientListAreaRange.ate100, 100), isTrue);
      expect(areaHaMatchesRange(ClientListAreaRange.ate100, 100.1), isFalse);
      expect(areaHaMatchesRange(ClientListAreaRange.de100a500, 250), isTrue);
      expect(areaHaMatchesRange(ClientListAreaRange.acima2000, 2500), isTrue);
    });
  });

  group('clientMatchesAdvancedFilters', () {
    test('cidade: OR entre cidades, exclui sem cidade', () {
      final a = _client(id: 'a', city: 'Cascavel', state: 'PR');
      final b = _client(id: 'b', city: 'Londrina', state: 'PR');
      final semCidade = _client(id: 'c', city: '', state: '');

      final filters = ClientListAdvancedFilters(
        cityKeys: {
          clientCityKey(a),
          clientCityKey(b),
        },
      );

      expect(
        clientMatchesAdvancedFilters(
          client: a,
          advanced: filters,
          culturas: const [],
        ),
        isTrue,
      );
      expect(
        clientMatchesAdvancedFilters(
          client: semCidade,
          advanced: filters,
          culturas: const [],
        ),
        isFalse,
      );
    });

    test('cultura: exige match; área soma culturas selecionadas', () {
      final client = _client(id: '1', areaTotal: 9999);
      final culturas = _rows([
        const ClientListCulturaRow(tipo: CulturaTipo.soja, areaHa: 60),
        const ClientListCulturaRow(tipo: CulturaTipo.milho, areaHa: 200),
      ]);

      final filters = const ClientListAdvancedFilters(
        culturas: {CulturaTipo.soja, CulturaTipo.milho},
        areaRange: ClientListAreaRange.de100a500,
      );

      expect(
        clientMatchesAdvancedFilters(
          client: client,
          advanced: filters,
          culturas: culturas,
        ),
        isTrue,
      );
    });

    test('área sem cultura usa areaTotal do cliente', () {
      final client = _client(id: '1', areaTotal: 90);
      final filters = const ClientListAdvancedFilters(
        areaRange: ClientListAreaRange.ate100,
      );

      expect(
        clientMatchesAdvancedFilters(
          client: client,
          advanced: filters,
          culturas: const [],
        ),
        isTrue,
      );
    });

    test('cliente sem dado numérico excluído com filtro de área', () {
      final client = _client(id: '1', areaTotal: null);
      final filters = const ClientListAdvancedFilters(
        areaRange: ClientListAreaRange.ate100,
      );

      expect(
        clientMatchesAdvancedFilters(
          client: client,
          advanced: filters,
          culturas: const [],
        ),
        isFalse,
      );
    });
  });

  group('applyClientListFilters', () {
    test('combina busca, status e filtros avançados', () {
      final ativo = _client(id: '1', name: 'João', active: true);
      final inativo = _client(id: '2', name: 'Maria', active: false);
      final clients = [ativo, inativo];

      var result = applyClientListFilters(
        clients: clients,
        statusFilter: 'Ativos',
        search: 'jo',
        advanced: const ClientListAdvancedFilters(),
        culturasByClientId: const {},
      );
      expect(result, [ativo]);

      result = applyClientListFilters(
        clients: clients,
        statusFilter: 'Inativos',
        search: '',
        advanced: const ClientListAdvancedFilters(),
        culturasByClientId: const {},
      );
      expect(result, [inativo]);
    });

    test('retorna lista ordenada alfabeticamente por nome', () {
      final zebra = _client(id: 'z', name: 'Zebra Fazenda');
      final alfa = _client(id: 'a', name: 'Alfa Agro');
      final beta = _client(id: 'b', name: 'beta campo');
      final clients = [zebra, alfa, beta];

      final result = applyClientListFilters(
        clients: clients,
        statusFilter: 'Todos',
        search: '',
        advanced: const ClientListAdvancedFilters(),
        culturasByClientId: const {},
      );

      expect(result.map((c) => c.name), ['Alfa Agro', 'beta campo', 'Zebra Fazenda']);
    });
  });

  group('compareClientDisplayName', () {
    test('case-insensitive por nome; desempate por id', () {
      final a = _client(id: 'aa', name: 'Maria');
      final b = _client(id: 'bb', name: 'joão');
      final c = _client(id: 'cc', name: ' João ');

      expect(compareClientDisplayName(a, b), greaterThan(0));
      expect(compareClientDisplayName(b, c), lessThan(0));
      expect(compareClientDisplayName(a, c), greaterThan(0));
    });
  });

  group('advancedFilterNeedsCulturaIndex', () {
    test('só com cultura selecionada', () {
      expect(
        advancedFilterNeedsCulturaIndex(
          const ClientListAdvancedFilters(cityKeys: {'x|y'}),
        ),
        isFalse,
      );
      expect(
        advancedFilterNeedsCulturaIndex(
          const ClientListAdvancedFilters(areaRange: ClientListAreaRange.ate100),
        ),
        isFalse,
      );
      expect(
        advancedFilterNeedsCulturaIndex(
          const ClientListAdvancedFilters(culturas: {CulturaTipo.soja}),
        ),
        isTrue,
      );
    });
  });
}