import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/data/relatorio_combinado_sync_service.dart';

void main() {
  group('RelatorioCombinadoSyncService.syncNow', () {
    setUp(LocalSessionIdentity.resetForTesting);
    tearDown(LocalSessionIdentity.resetForTesting);

    test('no-op sem JWT', () async {
      final service = RelatorioCombinadoSyncService(
        currentUserId: () => null,
        supabase: null,
      );
      await service.syncNow();
    });

    test('no-op com JWT vazio', () async {
      final service = RelatorioCombinadoSyncService(
        currentUserId: () => '  ',
        supabase: null,
      );
      await service.syncNow();
    });

    test(
      'no-op no caminho de produção sem JWT hidratado mesmo com lastKnown',
      () async {
        LocalSessionIdentity.remember('user-last-known');
        final service = RelatorioCombinadoSyncService(supabase: null);
        await service.syncNow();
      },
    );
  });

  group('rowToRemote', () {
    test(
      'push não inclui campo inventado e manda chapters_json decodificado',
      () {
        final payload = RelatorioCombinadoSyncService.rowToRemote({
          'id': 'combo-1',
          'user_id': 'local-user',
          'client_id': 'cli-1',
          'title': 'Combinado · 26/10/2026 · 2 relatórios',
          'chapters_json': '["visita:a","ocorrencia:b"]',
          'created_at': '2026-10-26T12:00:00.000Z',
          'updated_at': '2026-10-26T12:00:00.000Z',
          'sync_status': SyncStatusContract.pendingSync,
          'deleted_at': '2026-10-26T13:00:00.000Z',
          'html': '<html></html>',
        }, userId: 'jwt-user');

        expect(payload.containsKey('html'), isFalse);
        expect(payload['user_id'], 'jwt-user');
        expect(payload['chapters_json'], ['visita:a', 'ocorrencia:b']);
        expect(payload['sync_status'], SyncStatusContract.synced);
        expect(payload['deleted_at'], '2026-10-26T13:00:00.000Z');
        for (final key in payload.keys) {
          expect(RelatorioCombinadoSyncService.allowedColumns, contains(key));
        }
      },
    );
  });

  group('pull LWW', () {
    test('preserva local pending mais novo', () {
      final apply = RelatorioCombinadoSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-10-26T12:00:00.000Z',
          'sync_status': SyncStatusContract.pendingSync,
        },
        {
          'updated_at': '2026-10-26T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );
      expect(apply, isFalse);
    });

    test('aplica remoto quando local está synced e remoto é mais novo', () {
      final apply = RelatorioCombinadoSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-10-26T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
        {
          'updated_at': '2026-10-26T12:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );
      expect(apply, isTrue);
    });

    test('tombstone remoto não apaga a linha e não reaparece como vivo', () {
      expect(
        RelatorioCombinadoSyncService.shouldHardDeleteOnPull({
          'id': 'combo-1',
          'deleted_at': '2026-10-26T12:00:00.000Z',
        }),
        isFalse,
      );

      final merged = RelatorioCombinadoSyncService.mergePulled(
        local: {
          'id': 'combo-1',
          'updated_at': '2026-10-26T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
          'deleted_at': null,
        },
        pulled: {
          'id': 'combo-1',
          'updated_at': '2026-10-26T12:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
          'deleted_at': '2026-10-26T12:00:00.000Z',
          'chapters_json': '["visita:a"]',
        },
      );
      expect(merged, isNotNull);
      expect(merged!['deleted_at'], isNotNull);
      expect(merged['id'], 'combo-1');
    });
  });
}
