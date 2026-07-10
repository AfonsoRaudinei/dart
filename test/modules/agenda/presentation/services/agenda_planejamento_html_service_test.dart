import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/presentation/services/agenda_planejamento_html_service.dart';

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    if (id == 'c1') {
      return const ClientSummary(id: 'c1', name: 'Cliente Teste', active: true);
    }
    return null;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}

class _FakeFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async {
    if (farmId == 'f1') {
      return const FarmSummary(
        id: 'f1',
        clientId: 'c1',
        name: 'Fazenda Norte',
      );
    }
    return null;
  }

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async => const [];

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  test('AgendaPlanejamentoHtmlService renderiza semana com branding', () async {
    final weekStart = DateTime(2026, 7, 6);
    final event = Event(
      id: 'e1',
      tipo: EventType.visitaTecnica,
      clienteId: 'c1',
      fazendaId: 'f1',
      titulo: 'Visita tecnica',
      dataInicioPlanejada: DateTime(2026, 7, 7, 8),
      dataFimPlanejada: DateTime(2026, 7, 7, 10),
      status: EventStatus.agendado,
      createdAt: DateTime(2026, 7, 1),
      updatedAt: DateTime(2026, 7, 1),
      syncStatus: 'pending',
      startTime: const TimeOfDay(hour: 8, minute: 0),
      endTime: const TimeOfDay(hour: 10, minute: 0),
    );

    final html = await AgendaPlanejamentoHtmlService(
      _FakeClientLookup(),
      _FakeFarmLookup(),
    ).renderWeekHtml(
      events: [event],
      weekStart: weekStart,
      consultantName: 'Agronomo Teste',
    );

    expect(html, contains('Planejamento Semanal'));
    expect(html, contains('Cliente Teste'));
    expect(html, contains('Fazenda Norte'));
    expect(html, contains('Visita tecnica'));
    expect(html, contains('SoloForte'));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
    expect(html, isNot(contains('Gerado em')));
  });

  test('AgendaPlanejamentoHtmlService renderiza semana vazia', () async {
    final weekStart = DateTime(2026, 7, 6);
    final html = await AgendaPlanejamentoHtmlService(
      _FakeClientLookup(),
      _FakeFarmLookup(),
    ).renderWeekHtml(events: const [], weekStart: weekStart);

    expect(html, contains('Nenhum evento agendado'));
    expect(html, contains('0%'));
    expect(html, isNot(contains(RegExp(r'\{\{[^}]+\}\}'))));
  });
}
