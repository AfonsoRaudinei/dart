import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  group('OccurrenceRemoteMapper', () {
    test('prioriza latitude e longitude explicitas', () {
      final coordinates = OccurrenceRemoteMapper.resolveCoordinates(
        latitude: -10.25,
        longitude: -48.32,
        geometry: '{"type":"Point","coordinates":[-40,-8]}',
      );

      expect(coordinates?.latitude, -10.25);
      expect(coordinates?.longitude, -48.32);
      expect(coordinates?.geometry['coordinates'], [-48.32, -10.25]);
    });

    test('usa geometry como fallback', () {
      final coordinates = OccurrenceRemoteMapper.resolveCoordinates(
        latitude: null,
        longitude: null,
        geometry: '{"type":"Point","coordinates":[-48.32,-10.25]}',
      );

      expect(coordinates?.latitude, -10.25);
      expect(coordinates?.longitude, -48.32);
    });

    test('coordenadas ausentes ou zero zero nao geram ponto', () {
      expect(
        OccurrenceRemoteMapper.resolveCoordinates(
          latitude: null,
          longitude: null,
          geometry: null,
        ),
        isNull,
      );
      expect(
        OccurrenceRemoteMapper.resolveCoordinates(
          latitude: 0,
          longitude: 0,
          geometry: null,
        ),
        isNull,
      );
    });

    test('fromRemote com lat/long legado popula local lat/long', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-legacy',
          'user_id': 'consultant-1',
          'lat': -10.25,
          'long': -48.32,
          'created_at': '2026-06-21T10:00:00Z',
          'updated_at': '2026-06-21T11:00:00Z',
        },
        localId: 'remote-legacy',
        cachedByUserId: null,
      );

      expect(local['lat'], -10.25);
      expect(local['long'], -48.32);
    });

    test('fromRemote com latitude/longitude canônico popula local lat/long', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-canonical',
          'user_id': 'consultant-1',
          'latitude': -12.5,
          'longitude': -45.8,
          'created_at': '2026-06-21T10:00:00Z',
          'updated_at': '2026-06-21T11:00:00Z',
        },
        localId: 'remote-canonical',
        cachedByUserId: null,
      );

      expect(local['lat'], -12.5);
      expect(local['long'], -45.8);
    });

    test('toRemote envia latitude/longitude e lat/long sem sync_status', () {
      final occurrence = Occurrence(
        id: 'local-1',
        type: 'Info',
        description: 'Teste',
        lat: -10.25,
        long: -48.32,
        createdAt: DateTime.utc(2026, 6, 21),
        syncStatus: 'pending_sync',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');

      expect(remote['latitude'], -10.25);
      expect(remote['longitude'], -48.32);
      expect(remote['lat'], -10.25);
      expect(remote['long'], -48.32);
      expect(remote.containsKey('sync_status'), isFalse);
    });

    test('toRemote/fromRemote round-trip dos campos de plantio preenchidos', () {
      final occurrence = Occurrence(
        id: 'local-plantio',
        type: 'Média',
        description: 'Stand',
        category: 'plantio',
        lat: -10.25,
        long: -48.32,
        createdAt: DateTime.utc(2026, 6, 21),
        dataEmergencia: '2026-11-01',
        sementesPorMetro: 14.5,
        estandePlantas: 12,
        avaliacaoPlantio: 'boa',
        objetivoPlantio: 'Stand uniforme',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(remote['data_emergencia'], '2026-11-01');
      expect(remote['sementes_por_metro'], 14.5);
      expect(remote['estande_plantas'], 12);
      expect(remote['avaliacao_plantio'], 'boa');
      expect(remote['objetivo_plantio'], 'Stand uniforme');

      final local = OccurrenceRemoteMapper.fromRemote(
        remote,
        localId: 'local-plantio',
        cachedByUserId: null,
      );
      final mapped = Occurrence.fromMap(local);
      expect(mapped.dataEmergencia, '2026-11-01');
      expect(mapped.sementesPorMetro, 14.5);
      expect(mapped.estandePlantas, 12);
      expect(mapped.avaliacaoPlantio, 'boa');
      expect(mapped.objetivoPlantio, 'Stand uniforme');
    });

    test('toRemote/fromRemote preserva campos de plantio nulos', () {
      final occurrence = Occurrence(
        id: 'local-plantio-null',
        type: 'Média',
        description: 'Stand vazio',
        category: 'plantio',
        createdAt: DateTime.utc(2026, 6, 21),
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(remote['data_emergencia'], isNull);
      expect(remote['sementes_por_metro'], isNull);
      expect(remote['estande_plantas'], isNull);
      expect(remote['avaliacao_plantio'], isNull);
      expect(remote['objetivo_plantio'], isNull);

      final local = OccurrenceRemoteMapper.fromRemote(
        remote,
        localId: 'local-plantio-null',
        cachedByUserId: null,
      );
      final mapped = Occurrence.fromMap(local);
      expect(mapped.dataEmergencia, isNull);
      expect(mapped.sementesPorMetro, isNull);
      expect(mapped.estandePlantas, isNull);
      expect(mapped.avaliacaoPlantio, isNull);
      expect(mapped.objetivoPlantio, isNull);
      expect(remote['data_fim_plantio'], isNull);
      expect(remote['ciclo_dias'], isNull);
      expect(mapped.dataFimPlantio, isNull);
      expect(mapped.cicloDias, isNull);
    });

    test('toRemote envia término do plantio e ciclo', () {
      final occurrence = Occurrence(
        id: 'local-plantio-fim',
        type: 'Média',
        description: '',
        category: 'plantio',
        createdAt: DateTime.utc(2026, 11, 9),
        dataPlantio: '2026-10-27',
        dataFimPlantio: '2026-10-30',
        cicloDias: 115,
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');

      expect(remote['data_fim_plantio'], '2026-10-30');
      expect(remote['ciclo_dias'], 115);
    });

    test('fromRemote lê término do plantio e ciclo', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-plantio-fim',
          'type': 'Média',
          'description': '',
          'category': 'plantio',
          'created_at': '2026-11-09T00:00:00.000Z',
          'updated_at': '2026-11-09T00:00:00.000Z',
          'data_fim_plantio': '2026-10-30',
          'ciclo_dias': 115,
        },
        localId: 'local-plantio-fim',
        cachedByUserId: null,
      );

      expect(local['data_fim_plantio'], '2026-10-30');
      expect(local['ciclo_dias'], 115);
      final mapped = Occurrence.fromMap(local);
      expect(mapped.dataFimPlantio, '2026-10-30');
      expect(mapped.cicloDias, 115);
    });

    test('toRemote envia cultura e safra', () {
      final occurrence = Occurrence(
        id: 'local-plantio-safra',
        type: 'Média',
        description: '',
        category: 'plantio',
        createdAt: DateTime.utc(2026, 11, 9),
        cultura: 'Soja',
        safra: '2026/2027',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');

      expect(remote['cultura'], 'Soja');
      expect(remote['safra'], '2026/2027');
    });

    test('fromRemote lê cultura e safra; ausentes ficam null', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-plantio-safra',
          'type': 'Média',
          'description': '',
          'category': 'ervas_daninhas',
          'created_at': '2026-11-09T00:00:00.000Z',
          'updated_at': '2026-11-09T00:00:00.000Z',
          'cultura': 'Soja',
          'safra': '2026/2027',
        },
        localId: 'local-plantio-safra',
        cachedByUserId: null,
      );

      expect(local['cultura'], 'Soja');
      expect(local['safra'], '2026/2027');
      final mapped = Occurrence.fromMap(local);
      expect(mapped.cultura, 'Soja');
      expect(mapped.safra, '2026/2027');

      final legado = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-legado',
          'type': 'Média',
          'description': '',
          'created_at': '2026-11-09T00:00:00.000Z',
          'updated_at': '2026-11-09T00:00:00.000Z',
        },
        localId: 'local-legado',
        cachedByUserId: null,
      );
      expect(legado['cultura'], isNull);
      expect(legado['safra'], isNull);
    });

    test('toRemote envia andamento e responsavel_nome', () {
      final occurrence = Occurrence(
        id: 'local-andamento',
        type: 'Alta',
        description: 'Ferrugem',
        createdAt: DateTime.utc(2026, 11, 5),
        status: 'confirmed',
        andamento: 'em_atendimento',
        responsavelNome: 'Maria',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(remote['andamento'], 'em_atendimento');
      expect(remote['responsavel_nome'], 'Maria');
    });

    test('fromRemote sem chave andamento assume aberta', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-legacy',
          'user_id': 'owner-1',
          'type': 'Alta',
          'description': 'Legado',
        },
        localId: 'local-legacy',
        cachedByUserId: null,
      );
      expect(local['andamento'], 'aberta');
      expect(local['responsavel_nome'], isNull);
      expect(Occurrence.fromMap(local).andamento, 'aberta');
    });

    test('toRemote/fromRemote round-trip de andamento preenchido', () {
      final occurrence = Occurrence(
        id: 'local-andamento-rt',
        type: 'Média',
        description: 'Percevejo',
        createdAt: DateTime.utc(2026, 11, 5),
        status: 'confirmed',
        andamento: 'resolvida',
        responsavelNome: 'João',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      final mapped = Occurrence.fromMap(
        OccurrenceRemoteMapper.fromRemote(
          remote,
          localId: 'local-andamento-rt',
          cachedByUserId: null,
        ),
      );
      expect(mapped.andamento, 'resolvida');
      expect(mapped.responsavelNome, 'João');
    });

    test('toRemote/fromRemote round-trip dos campos de amostra preenchidos', () {
      final occurrence = Occurrence(
        id: 'local-amostra',
        type: 'Média',
        description: 'Coleta de solo',
        category: 'amostra_solo',
        amostraSolo: true,
        lat: -10.25,
        long: -48.32,
        createdAt: DateTime.utc(2026, 11, 5),
        amostraCodigo: 'AS-2026-014',
        amostraColetor: 'Técnico',
        amostraTramite: 'laudo_pronto',
        amostraLaudoTexto: 'pH 5,8',
        amostraAnalisesJson: '{"reservado":true}',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(remote['amostra_codigo'], 'AS-2026-014');
      expect(remote['amostra_coletor'], 'Técnico');
      expect(remote['amostra_tramite'], 'laudo_pronto');
      expect(remote['amostra_laudo_texto'], 'pH 5,8');
      expect(remote['amostra_analises_json'], {'reservado': true});

      final local = OccurrenceRemoteMapper.fromRemote(
        remote,
        localId: 'local-amostra',
        cachedByUserId: null,
      );
      final mapped = Occurrence.fromMap(local);
      expect(mapped.amostraCodigo, 'AS-2026-014');
      expect(mapped.amostraTramite, 'laudo_pronto');
      expect(mapped.amostraLaudoTexto, 'pH 5,8');
      expect(mapped.amostraAnalisesJson, contains('reservado'));
    });

    test('toRemote envia as 5 chaves de amostra junto com andamento e áudio', () {
      final occurrence = Occurrence(
        id: 'local-amostra-full',
        type: 'Média',
        description: 'Coleta',
        category: 'amostra_solo',
        amostraSolo: true,
        createdAt: DateTime.utc(2026, 11, 5),
        status: 'confirmed',
        andamento: 'em_atendimento',
        responsavelNome: 'Maria',
        audioPath: 'media/audio_1.m4a',
        audioDurationSec: 12,
        amostraCodigo: 'AS-1',
        amostraColetor: 'João',
        amostraTramite: 'laboratorio',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(
        remote.keys,
        containsAll(<String>[
          'amostra_codigo',
          'amostra_coletor',
          'amostra_tramite',
          'amostra_laudo_texto',
          'amostra_analises_json',
        ]),
      );
      expect(remote['amostra_laudo_texto'], isNull);
      expect(remote['amostra_analises_json'], isNull);

      final mapped = Occurrence.fromMap(
        OccurrenceRemoteMapper.fromRemote(
          remote,
          localId: 'local-amostra-full',
          cachedByUserId: null,
        ),
      );
      expect(mapped.amostraCodigo, 'AS-1');
      expect(mapped.amostraColetor, 'João');
      expect(mapped.amostraTramite, 'laboratorio');
      expect(mapped.andamento, 'em_atendimento');
      expect(mapped.responsavelNome, 'Maria');
      expect(mapped.audioPath, 'media/audio_1.m4a');
      expect(mapped.audioDurationSec, 12);
    });

    test('fromRemote sem chaves de amostra mantém campos nulos', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-sem-amostra',
          'user_id': 'owner-1',
          'type': 'Alta',
          'description': 'Legado',
        },
        localId: 'local-sem-amostra',
        cachedByUserId: null,
      );
      final mapped = Occurrence.fromMap(local);
      expect(mapped.amostraCodigo, isNull);
      expect(mapped.amostraColetor, isNull);
      expect(mapped.amostraTramite, isNull);
      expect(mapped.amostraLaudoTexto, isNull);
      expect(mapped.amostraAnalisesJson, isNull);
    });

    test('toRemote/fromRemote preserva ordem de aplicação e o espelho', () {
      final occurrence = Occurrence(
        id: 'local-ordem',
        type: 'Média',
        description: 'Lagarta',
        createdAt: DateTime.utc(2026, 11, 5),
        recomendacaoAcao: 'Aplicar',
        recomendacaoDose: '0,5 L/ha',
        recomendacaoQuando: 'V4 a V6',
      );

      final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');
      expect(remote['recomendacao_acao'], 'Aplicar');
      expect(remote['recomendacao_dose'], '0,5 L/ha');
      expect(remote['recomendacao_quando'], 'V4 a V6');
      expect(remote.containsKey('field_id'), isFalse);
      expect(
        remote['recomendacoes'],
        'O que fazer: Aplicar\nDose: 0,5 L/ha\nQuando: V4 a V6',
      );

      final local = OccurrenceRemoteMapper.fromRemote(
        remote,
        localId: 'local-ordem',
        cachedByUserId: null,
      );
      final mapped = Occurrence.fromMap(local);
      expect(mapped.recomendacaoAcao, 'Aplicar');
      expect(mapped.recomendacaoDose, '0,5 L/ha');
      expect(mapped.recomendacaoQuando, 'V4 a V6');
    });

    test('preserva owner, identidade externa e payload completo no cache', () {
      final local = OccurrenceRemoteMapper.fromRemote(
        {
          'id': 'remote-1',
          'user_id': 'consultant-1',
          'client_id': 'client-1',
          'type': 'Info',
          'description': 'Laudo',
          'category': 'amostra_solo',
          'amostra_solo': true,
          'analysis_payload': {
            'ph': 5.4,
            'nutrientes': {'P': 12, 'K': 18},
          },
          'external_source': 'caderno_solo',
          'external_analysis_id': 'analysis-1',
          'created_at': '2026-06-21T10:00:00Z',
          'updated_at': '2026-06-21T11:00:00Z',
        },
        localId: 'remote-1_cache_producer-1',
        cachedByUserId: 'producer-1',
      );

      expect(local['user_id'], 'consultant-1');
      expect(local['cached_by_user_id'], 'producer-1');
      expect(local['external_analysis_id'], 'analysis-1');
      expect(jsonDecode(local['analysis_payload_json'] as String)['ph'], 5.4);
      expect(local['amostra_solo'], 1);
    });

    test('soft delete atual e legado preservam ID remoto e owner', () {
      for (final status in ['deleted_local', 'deleted']) {
        final occurrence = Occurrence(
          id: 'local-cache-id',
          remoteId: 'remote-id',
          type: 'Info',
          description: '',
          createdAt: DateTime.utc(2026, 6, 21),
          syncStatus: status,
          externalSource: 'caderno_solo',
          externalAnalysisId: 'analysis-1',
          analysisPayloadJson: '{"ph":5.4}',
        );

        final remote = OccurrenceRemoteMapper.toRemote(
          occurrence,
          'authenticated-owner',
        );
        expect(remote['id'], 'remote-id');
        expect(remote['user_id'], 'authenticated-owner');
        expect(remote['deleted_at'], isNotNull);
        expect(remote['analysis_payload'], {'ph': 5.4});
      }
    });
  });

  test('vinculo revogado remove cache compartilhado sem acesso', () {
    final revoked = OccurrenceCachePolicy.revokedLocalIds(
      [
        {'id': 'cache-active', 'client_id': 'client-active'},
        {'id': 'cache-revoked', 'client_id': 'client-revoked'},
        {'id': 'cache-invalid', 'client_id': null},
      ],
      {'client-active'},
    );

    expect(revoked, ['cache-revoked', 'cache-invalid']);
  });

  test('pull nao sobrescreve alteracao local pendente nem remoto antigo', () {
    expect(
      OccurrenceCachePolicy.shouldReplaceOwnedLocal(
        {'sync_status': 'updated', 'updated_at': '2026-06-21T12:00:00Z'},
        {'updated_at': '2026-06-21T13:00:00Z'},
      ),
      isFalse,
    );
    expect(
      OccurrenceCachePolicy.shouldReplaceOwnedLocal(
        {'sync_status': 'synced', 'updated_at': '2026-06-21T12:00:00Z'},
        {'updated_at': '2026-06-21T11:00:00Z'},
      ),
      isFalse,
    );
    expect(
      OccurrenceCachePolicy.shouldReplaceOwnedLocal(
        {'sync_status': 'synced', 'updated_at': '2026-06-21T12:00:00Z'},
        {'updated_at': '2026-06-21T13:00:00Z'},
      ),
      isTrue,
    );
  });

  test('toRemote não envia field_id (coluna só local)', () {
    final occurrence = Occurrence(
      id: 'local-field',
      type: 'Média',
      description: 'Ferrugem',
      createdAt: DateTime.utc(2026, 6, 21),
      fieldId: 'field-1',
    );

    final remote = OccurrenceRemoteMapper.toRemote(occurrence, 'owner-1');

    expect(remote.containsKey('field_id'), isFalse);
  });

  group('OccurrenceCachePolicy.writePulledRow', () {
    late Database db;

    setUpAll(sqfliteFfiInit);

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    });

    tearDown(() async => db.close());

    test('pull com replace preserva field_id local', () async {
      await db.execute(
        'CREATE TABLE occurrences ('
        'id TEXT PRIMARY KEY, description TEXT, sync_status TEXT, '
        'field_id TEXT)',
      );
      await db.insert('occurrences', {
        'id': 'occ-1',
        'description': 'Antiga',
        'sync_status': 'synced',
        'field_id': 'field-1',
      });

      await OccurrenceCachePolicy.writePulledRow(db, {
        'id': 'occ-1',
        'description': 'Ferrugem',
        'sync_status': 'synced',
      });

      final rows = await db.query('occurrences');
      expect(rows, hasLength(1));
      expect(rows.single['description'], 'Ferrugem');
      expect(rows.single['field_id'], 'field-1');
    });

    test('pull de linha nova deixa field_id nulo', () async {
      await db.execute(
        'CREATE TABLE occurrences ('
        'id TEXT PRIMARY KEY, description TEXT, field_id TEXT)',
      );

      await OccurrenceCachePolicy.writePulledRow(db, {
        'id': 'occ-2',
        'description': 'Ferrugem',
      });

      final rows = await db.query('occurrences');
      expect(rows.single['field_id'], isNull);
    });
  });

  test('cache compartilhado rejeita edicao local', () async {
    final occurrence = Occurrence(
      id: 'shared-cache',
      cachedByUserId: 'producer-1',
      ownerUserId: 'consultant-1',
      type: 'Info',
      description: '',
      createdAt: DateTime.utc(2026, 6, 21),
    );

    await expectLater(
      OccurrenceRepository().updateOccurrence(occurrence),
      throwsA(isA<StateError>()),
    );
  });
}
