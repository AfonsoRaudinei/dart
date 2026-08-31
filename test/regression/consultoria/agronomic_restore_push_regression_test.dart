import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/data/services/agenda_sync_service.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/services/agronomic_sync_service.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';

/// BUG-011 — restore pós-reinstall: push agronômico PT-only.
///
/// Causa raiz histórica: `clientLocalToRemote` enviava aliases EN
/// (`name`/`phone`/`city`/`state`/`document`/`area_ha`) → PGRST204 engolido
/// → `public.clients=0` → wipe apagava SQLite e o pull vinha vazio.
///
/// Sem HTTP. Sem widgets. IDs sintéticos de teste.
void main() {
  group('BUG-011 agronomic_restore_push_regression', () {
    test('client push PT-only', () {
      final payload = AgronomicSyncService.clientLocalToRemote({
        'id': 'client-1',
        'user_id': 'user-1',
        'nome': 'Cliente 1',
        'telefone': '63999990000',
        'cidade': 'Crixas',
        'uf': 'TO',
        'cpf_cnpj': '12345678901',
        'area_total': 10.0,
        'created_at': '2026-08-31T10:00:00.000',
        'updated_at': '2026-08-31T10:00:00.000',
        'sync_status': AgronomicSyncService.statusDirty,
      });

      expect(payload['nome'], 'Cliente 1');
      expect(payload['telefone'], '63999990000');
      expect(payload['cidade'], 'Crixas');
      expect(payload['uf'], 'TO');
      expect(payload.containsKey('name'), isFalse);
      expect(payload.containsKey('phone'), isFalse);
      expect(payload.containsKey('city'), isFalse);
      expect(payload.containsKey('state'), isFalse);
      expect(payload.containsKey('document'), isFalse);
      expect(payload.containsKey('area_ha'), isFalse);
      expect(payload.containsKey('sync_status'), isFalse);
    });

    test('farm push PT-only', () {
      final payload = AgronomicSyncService.farmLocalToRemote({
        'id': 'farm-1',
        'user_id': 'user-1',
        'cliente_id': 'client-1',
        'nome': 'Fazenda 1',
        'area_total': 80.0,
        'created_at': '2026-08-31T10:00:00.000',
        'updated_at': '2026-08-31T10:00:00.000',
      });

      expect(payload['cliente_id'], 'client-1');
      expect(payload['nome'], 'Fazenda 1');
      expect(payload['area_total'], 80.0);
      expect(payload.containsKey('client_id'), isFalse);
      expect(payload.containsKey('name'), isFalse);
      expect(payload.containsKey('area_ha'), isFalse);
    });

    test('field push PT-only', () {
      final payload = AgronomicSyncService.fieldLocalToRemote({
        'id': 'field-1',
        'user_id': 'user-1',
        'fazenda_id': 'farm-1',
        'nome': 'Talhao 1',
        'area_produtiva': 22.3,
        'created_at': '2026-08-31T10:00:00.000',
        'updated_at': '2026-08-31T10:00:00.000',
      });

      expect(payload['fazenda_id'], 'farm-1');
      expect(payload['nome'], 'Talhao 1');
      expect(payload['area_produtiva'], 22.3);
      expect(payload.containsKey('farm_id'), isFalse);
      expect(payload.containsKey('name'), isFalse);
      expect(payload.containsKey('area_ha'), isFalse);
      expect(payload.containsKey('geometry'), isFalse);
    });

    test('visit push live columns', () {
      final payload = VisitSyncService.toSupabasePayload(
        VisitSession(
          id: 'visit-1',
          producerId: 'client-1',
          farmId: 'farm-1',
          areaId: 'field-1',
          activityType: 'Monitoramento',
          startTime: DateTime(2026, 8, 31, 8),
          endTime: DateTime(2026, 8, 31, 9),
          initialLat: -10,
          initialLong: -48,
          status: 'finished',
          createdAt: DateTime(2026, 8, 31, 8),
          updatedAt: DateTime(2026, 8, 31, 9),
        ),
        'user-1',
      );

      expect(payload.containsKey('start_time'), isTrue);
      expect(payload.containsKey('end_time'), isTrue);
      expect(payload.containsKey('started_at'), isFalse);
      expect(payload.containsKey('ended_at'), isFalse);
      expect(payload.containsKey('sync_status'), isFalse);
    });

    test('occurrence dual lat', () {
      final occurrence = Occurrence(
        id: 'occ-1',
        type: 'Info',
        description: 'Teste',
        lat: -10.25,
        long: -48.32,
        createdAt: DateTime.utc(2026, 8, 31),
        syncStatus: 'pending_sync',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'user-1');
      expect(remote['latitude'], -10.25);
      expect(remote['longitude'], -48.32);
      expect(remote['lat'], -10.25);
      expect(remote['long'], -48.32);
      expect(remote.containsKey('sync_status'), isFalse);

      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'occ-legacy',
          'user_id': 'user-1',
          'lat': -10.25,
          'long': -48.32,
          'created_at': '2026-08-31T10:00:00Z',
          'updated_at': '2026-08-31T11:00:00Z',
        },
        localId: 'occ-legacy',
        cachedByUserId: null,
      );
      expect(local['lat'], -10.25);
      expect(local['long'], -48.32);
    });

    test('agenda dual', () {
      final start = DateTime.utc(2026, 8, 31, 9);
      final event = Event(
        id: 'evt-1',
        tipo: EventType.visitaTecnica,
        clienteId: 'client-1',
        fazendaId: 'farm-1',
        talhaoId: 'field-1',
        titulo: 'Visita',
        dataInicioPlanejada: start,
        dataFimPlanejada: start.add(const Duration(hours: 2)),
        status: EventStatus.agendado,
        createdAt: start,
        updatedAt: start,
      );

      final remote = AgendaEventRemoteMapper.eventLocalToRemote(
        event,
        'user-1',
      );

      expect(remote['tipo'], 'visitaTecnica');
      expect(remote['cliente_id'], 'client-1');
      expect(remote['producer_id'], 'client-1');
      expect(remote['scheduled_date'], start.toIso8601String());
      expect(remote.containsKey('sync_status'), isFalse);
    });
  });
}
