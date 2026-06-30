import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
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
