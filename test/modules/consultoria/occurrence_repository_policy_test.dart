import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';

void main() {
  group('OccurrenceOwnershipPolicy', () {
    test('usa currentUserId quando autenticacao ja esta hidratada', () {
      expect(
        OccurrenceOwnershipPolicy.resolvePersistedUserId(
          currentUserId: 'user-123',
          fallbackOwnerUserId: 'owner-legacy',
        ),
        'user-123',
      );
    });

    test('reaproveita ownerUserId ao editar registro local ja atribuido', () {
      expect(
        OccurrenceOwnershipPolicy.resolvePersistedUserId(
          currentUserId: '',
          fallbackOwnerUserId: 'owner-legacy',
        ),
        'owner-legacy',
      );
    });

    test('mantem orfao temporario quando sessao ainda nao hidratou', () {
      expect(
        OccurrenceOwnershipPolicy.resolvePersistedUserId(
          currentUserId: '',
          fallbackOwnerUserId: null,
        ),
        OccurrenceOwnershipPolicy.orphanUserId,
      );
    });

    test('normaliza sync_status legado para contrato canonico', () {
      expect(
        OccurrenceOwnershipPolicy.normalizeSyncStatusForWrite(
          persistedUserId: '',
          currentSyncStatus: 'local',
        ),
        'local_only',
      );
      expect(
        OccurrenceOwnershipPolicy.normalizeSyncStatusForWrite(
          persistedUserId: 'user-123',
          currentSyncStatus: 'local',
        ),
        'local_only',
      );
      expect(
        OccurrenceOwnershipPolicy.normalizeSyncStatusForWrite(
          persistedUserId: '',
          currentSyncStatus: 'pending',
        ),
        'pending_sync',
      );
    });

    test('usuario conhecido le somente o proprio user_id', () {
      expect(
        OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause('user-123'),
        'user_id = ?',
      );
      expect(
        OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs('user-123'),
        ['user-123'],
      );
    });

    test('pre-login le somente user_id vazio', () {
      expect(
        OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereClause(''),
        "user_id = ''",
      );
      expect(
        OccurrenceOwnershipPolicy.buildOwnedOrOrphanWhereArgs(''),
        isEmpty,
      );
    });
  });
}
