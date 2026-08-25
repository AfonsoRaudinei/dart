import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/data/services/agenda_sync_service.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';

void main() {
  group('AgendaEventRemoteMapper', () {
    test(
      'eventLocalToRemote envia PT e aliases EN legados',
      () {
        final start = DateTime.utc(2026, 8, 12, 9);
        final end = start.add(const Duration(hours: 2));
        final event = Event(
          id: 'evt-1',
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          fazendaId: 'farm-1',
          talhaoId: 'field-1',
          titulo: 'Visita técnica',
          dataInicioPlanejada: start,
          dataFimPlanejada: end,
          status: EventStatus.agendado,
          createdAt: start,
          updatedAt: start,
        );

        final remote = AgendaEventRemoteMapper.eventLocalToRemote(
          event,
          'user-1',
        );

        expect(remote['tipo'], 'visitaTecnica');
        expect(remote['cliente_id'], 'cli-1');
        expect(remote['producer_id'], 'cli-1');
        expect(remote['scheduled_date'], start.toIso8601String());
        expect(remote['description'], 'Visita técnica');
        expect(remote['activity_type'], 'visitaTecnica');
        expect(remote['area_id'], 'field-1');
      },
    );

    test('eventRemoteToLocal prioriza payload PT canônico', () {
      final local = AgendaEventRemoteMapper.eventRemoteToLocal({
        'id': 'evt-pt',
        'tipo': 'consultoria',
        'cliente_id': 'cli-pt',
        'fazenda_id': 'farm-pt',
        'talhao_id': 'field-pt',
        'titulo': 'Consultoria PT',
        'data_inicio_planejada': '2026-08-12T09:00:00.000Z',
        'data_fim_planejada': '2026-08-12T11:00:00.000Z',
        'status': 'agendado',
        'created_at': '2026-08-12T08:00:00.000Z',
        'updated_at': '2026-08-12T08:00:00.000Z',
      });

      expect(local['tipo'], 'consultoria');
      expect(local['cliente_id'], 'cli-pt');
      expect(local['talhao_id'], 'field-pt');
      expect(local['titulo'], 'Consultoria PT');
      expect(local['data_inicio_planejada'], '2026-08-12T09:00:00.000Z');
      expect(local['data_fim_planejada'], '2026-08-12T11:00:00.000Z');
    });

    test('eventRemoteToLocal faz fallback para payload EN legado', () {
      final local = AgendaEventRemoteMapper.eventRemoteToLocal({
        'id': 'evt-en',
        'producer_id': 'prod-en',
        'area_id': 'area-en',
        'activity_type': 'reuniao',
        'scheduled_date': '2026-07-01T14:00:00.000Z',
        'description': 'Reunião legada',
        'realized_at': '2026-07-01T16:00:00.000Z',
        'status': 'concluido',
        'created_at': '2026-07-01T10:00:00.000Z',
        'updated_at': '2026-07-01T16:30:00.000Z',
      });

      expect(local['cliente_id'], 'prod-en');
      expect(local['talhao_id'], 'area-en');
      expect(local['tipo'], 'reuniao');
      expect(local['titulo'], 'Reunião legada');
      expect(local['data_inicio_planejada'], '2026-07-01T14:00:00.000Z');
      expect(local['data_fim_planejada'], '2026-07-01T16:00:00.000Z');
      expect(local['status'], 'concluido');
    });

    test('eventLocalToRemote não envia sync_status', () {
      final start = DateTime.utc(2026, 8, 12, 9);
      final event = Event(
        id: 'evt-sync',
        tipo: EventType.lembrete,
        clienteId: 'cli-sync',
        titulo: 'Lembrete',
        dataInicioPlanejada: start,
        dataFimPlanejada: start.add(const Duration(hours: 1)),
        status: EventStatus.agendado,
        createdAt: start,
        updatedAt: start,
        syncStatus: 'pending_sync',
      );

      final remote = AgendaEventRemoteMapper.eventLocalToRemote(
        event,
        'user-sync',
      );

      expect(remote.containsKey('sync_status'), isFalse);
    });

    test('eventLocalToRemote envia realized_at só quando finalizado', () {
      final start = DateTime.utc(2026, 8, 12, 9);
      final end = start.add(const Duration(hours: 2));

      final agendado = AgendaEventRemoteMapper.eventLocalToRemote(
        Event(
          id: 'evt-open',
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Aberto',
          dataInicioPlanejada: start,
          dataFimPlanejada: end,
          status: EventStatus.agendado,
          createdAt: start,
          updatedAt: start,
        ),
        'user-1',
      );
      expect(agendado['realized_at'], isNull);

      final concluido = AgendaEventRemoteMapper.eventLocalToRemote(
        Event(
          id: 'evt-done',
          tipo: EventType.visitaTecnica,
          clienteId: 'cli-1',
          titulo: 'Concluído',
          dataInicioPlanejada: start,
          dataFimPlanejada: end,
          status: EventStatus.concluido,
          createdAt: start,
          updatedAt: start,
        ),
        'user-1',
      );
      expect(concluido['realized_at'], end.toIso8601String());
    });
  });
}
