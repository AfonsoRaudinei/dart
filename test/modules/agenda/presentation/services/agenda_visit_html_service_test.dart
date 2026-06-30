import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/presentation/services/agenda_visit_html_service.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  group('AgendaVisitHtmlService', () {
    test('renderiza talhao real via IFieldLookup no HTML de visita', () async {
      const service = AgendaVisitHtmlService(
        _FakeClientLookup(),
        _FakeFarmLookup(),
        _FakeFieldLookup(),
      );

      final html = await service.renderEventVisit(
        event: Event(
          id: 'event-1',
          tipo: EventType.visitaTecnica,
          clienteId: 'client-1',
          fazendaId: 'farm-1',
          talhaoId: 'field-1',
          titulo: 'Visita soja',
          dataInicioPlanejada: DateTime(2026, 6, 3, 8),
          dataFimPlanejada: DateTime(2026, 6, 3, 10),
          status: EventStatus.agendado,
          createdAt: DateTime(2026, 6, 1),
          updatedAt: DateTime(2026, 6, 1),
        ),
        agronomistNome: 'Ana Agronoma',
      );

      expect(html, contains('Cliente Real'));
      expect(html, contains('Fazenda Real'));
      expect(html, contains('Talhao Norte'));
      expect(html, contains('Cultura: Soja'));
      expect(html, contains('Safra: 2025/2026'));
      expect(html, contains('42,5'));
      expect(html, isNot(contains('Talhão field-1')));
    });
  });
}

class _FakeClientLookup implements IClientLookup {
  const _FakeClientLookup();

  @override
  Future<ClientSummary?> findById(String id) async {
    return const ClientSummary(
      id: 'client-1',
      name: 'Cliente Real',
      active: true,
    );
  }

  @override
  Future<List<ClientSummary>> listAtivos() async {
    return const [
      ClientSummary(id: 'client-1', name: 'Cliente Real', active: true),
    ];
  }
}

class _FakeFarmLookup implements IFarmLookup {
  const _FakeFarmLookup();

  @override
  Future<FarmSummary?> findById(String farmId) async {
    return const FarmSummary(
      id: 'farm-1',
      clientId: 'client-1',
      name: 'Fazenda Real',
      areaHa: 100,
    );
  }

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async {
    return const [
      FarmSummary(
        id: 'farm-1',
        clientId: 'client-1',
        name: 'Fazenda Real',
        areaHa: 100,
      ),
    ];
  }

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}
}

class _FakeFieldLookup implements IFieldLookup {
  const _FakeFieldLookup();

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    return const FieldSummary(
      id: 'field-1',
      name: 'Talhao Norte',
      farmId: 'farm-1',
      areaHa: 42.5,
      crop: 'Soja',
      harvest: '2025/2026',
    );
  }

  @override
  Future<List<FieldSummary>> listAll() async {
    return const [];
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async {
    return const [
      FieldSummary(
        id: 'field-1',
        name: 'Talhao Norte',
        farmId: 'farm-1',
        areaHa: 42.5,
        crop: 'Soja',
        harvest: '2025/2026',
      ),
    ];
  }
}
