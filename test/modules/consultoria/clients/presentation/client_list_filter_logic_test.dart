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

void main() {
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
      final culturas = [
        _cultura(clientId: '1', tipo: CulturaTipo.soja, areaHa: 60),
        _cultura(clientId: '1', tipo: CulturaTipo.milho, areaHa: 200),
      ];

      final filters = ClientListAdvancedFilters(
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
      final filters = ClientListAdvancedFilters(
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
      final filters = ClientListAdvancedFilters(
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
  });
}