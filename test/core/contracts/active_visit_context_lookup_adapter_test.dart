import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/consultoria/clients/data/clients_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/infra/active_visit_context_lookup_adapter.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';

class FakeVisitSessionLookup implements IVisitSessionLookup {
  VisitSessionSummary? session;

  @override
  Future<VisitSessionSummary?> getActiveSession() async => session;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async => session;
}

class FakeClientsRepository extends ClientsRepository {
  Client? client;

  @override
  Future<Client?> getClientById(String id) async => client;
}

class FakeFieldRepository extends FieldRepository {
  Talhao? field;
  final Map<String, List<Talhao>> fieldsByFarm = {};

  @override
  Future<Talhao?> getFieldById(String id) async => field;

  @override
  Future<List<Talhao>> getFieldsByFarmId(String farmId) async {
    return fieldsByFarm[farmId] ?? const [];
  }
}

Talhao _field() => Talhao(
  id: 'field-1',
  name: 'Talhão Norte',
  areaHa: 42.5,
  crop: '',
  harvest: '',
);

Client _client() => Client(
  id: 'client-1',
  name: 'José Augusto Miranda',
  phone: '',
  city: 'Palmas',
  state: 'TO',
  createdAt: DateTime(2026, 1, 1),
  farms: [
    Farm(
      id: 'farm-1',
      name: 'Fazenda Boa Vista',
      city: 'Porto Nacional',
      state: 'TO',
      totalAreaHa: 100,
    ),
  ],
);

void main() {
  late FakeVisitSessionLookup visitLookup;
  late FakeClientsRepository clientsRepository;
  late FakeFieldRepository fieldRepository;
  late ActiveVisitContextLookupAdapter adapter;

  setUp(() {
    visitLookup = FakeVisitSessionLookup();
    clientsRepository = FakeClientsRepository()..client = _client();
    fieldRepository = FakeFieldRepository()..field = _field();
    adapter = ActiveVisitContextLookupAdapter(
      visitLookup,
      clientsRepository,
      fieldRepository,
    );
  });

  test(
    'resolve cliente, fazenda, talhão, área e localização da visita',
    () async {
      visitLookup.session = VisitSessionSummary(
        id: 'visit-1',
        producerId: 'client-1',
        farmId: 'farm-1',
        areaId: 'field-1',
        status: 'active',
        startTime: DateTime(2026, 1, 2),
      );

      final context = await adapter.getActiveContext();

      expect(context, isNotNull);
      expect(
        context!.producerFarmLabel,
        'José Augusto Miranda / Fazenda Boa Vista',
      );
      expect(context.locationLabel, 'Porto Nacional - TO');
      expect(context.fieldName, 'Talhão Norte');
      expect(context.fieldAreaHa, 42.5);
    },
  );

  test('infere fazenda pelo talhão para sessão legada sem farmId', () async {
    visitLookup.session = VisitSessionSummary(
      id: 'visit-legacy',
      producerId: 'client-1',
      areaId: 'field-1',
      status: 'active',
      startTime: DateTime(2026, 1, 2),
    );
    fieldRepository.fieldsByFarm['farm-1'] = [_field()];

    final context = await adapter.getActiveContext();

    expect(context, isNotNull);
    expect(context!.farmId, 'farm-1');
    expect(context.farmName, 'Fazenda Boa Vista');
  });

  test('retorna null sem sessão ativa', () async {
    visitLookup.session = null;

    expect(await adapter.getActiveContext(), isNull);
  });
}
