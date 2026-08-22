import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/modules/carteira/data/carteira_sync_service.dart';

void main() {
  group('CarteiraSyncService.syncNow', () {
    test('no-op sem JWT', () async {
      final service = CarteiraSyncService(
        currentUserId: () => null,
        supabase: null,
      );
      await service.syncNow();
    });

    test('no-op com JWT vazio', () async {
      final service = CarteiraSyncService(
        currentUserId: () => '  ',
        supabase: null,
      );
      await service.syncNow();
    });
  });

  group('rowToRemote', () {
    test('push não inclui campo inventado', () {
      final payload = CarteiraSyncService.rowToRemote(
        'carteira_lancamentos',
        {
          'id': '11111111-1111-4111-8111-111111111111',
          'user_id': '22222222-2222-4222-8222-222222222222',
          'safra_id': '33333333-3333-4333-8333-333333333333',
          'categoria_id': '44444444-4444-4444-8444-444444444444',
          'cliente_id': 'cliente-1',
          'quantidade': 10.0,
          'observacao': 'ok',
          'data_lancamento': '2026-08-22T10:00:00.000Z',
          'created_at': '2026-08-22T10:00:00.000Z',
          'updated_at': '2026-08-22T11:00:00.000Z',
          'closed_percent': 40.0,
          'tipo_fechamento': 'vendido',
          'sync_status': SyncStatusContract.pendingSync,
          'deleted_at': null,
          'roi': 1.5,
          'quantidade_derivada': 99,
        },
      );

      expect(payload.containsKey('roi'), isFalse);
      expect(payload.containsKey('quantidade_derivada'), isFalse);
      expect(payload['quantidade'], 10.0);
      expect(payload['closed_percent'], 40.0);
      expect(payload['sync_status'], SyncStatusContract.synced);
      for (final key in payload.keys) {
        expect(
          CarteiraSyncService.allowedColumns['carteira_lancamentos'],
          contains(key),
        );
      }
    });

    test('tipos_produto envia 0/1 e não inventa coluna', () {
      final payload = CarteiraSyncService.rowToRemote(
        'carteira_tipos_produto',
        {
          'id': 't1',
          'user_id': 'u1',
          'codigo': 'realPorHa',
          'label': 'R\$/ha',
          'converte_sacas_ha': 1,
          'sistema': 1,
          'ativo': 1,
          'ordem': 0,
          'created_at': '2026-08-22T10:00:00.000Z',
          'updated_at': '2026-08-22T10:00:00.000Z',
          'sync_status': SyncStatusContract.pendingSync,
        },
      );

      expect(payload['converte_sacas_ha'], 1);
      expect(payload['sistema'], 1);
      expect(payload.containsKey('unidade_derivada'), isFalse);
    });
  });

  group('pull LWW', () {
    test('preserva local pending mais novo', () {
      final apply = CarteiraSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-08-22T12:00:00.000Z',
          'sync_status': SyncStatusContract.pendingSync,
        },
        {
          'updated_at': '2026-08-22T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );
      expect(apply, isFalse);
    });

    test('aplica remoto quando local está synced e remoto é mais novo', () {
      final apply = CarteiraSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-08-22T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
        {
          'updated_at': '2026-08-22T12:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );
      expect(apply, isTrue);
    });

    test('não aplica remoto mais antigo sobre local synced', () {
      final apply = CarteiraSyncService.shouldApplyRemote(
        {
          'updated_at': '2026-08-22T12:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
        {
          'updated_at': '2026-08-22T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );
      expect(apply, isFalse);
    });
  });

  group('tombstone', () {
    test('pull com deleted_at não remove a linha', () {
      expect(
        CarteiraSyncService.shouldHardDeleteOnPull({
          'id': 'l1',
          'deleted_at': '2026-08-22T12:00:00.000Z',
        }),
        isFalse,
      );
    });

    test('tombstone local não some no pull de remoto tombstoned', () {
      final local = <String, Object?>{
        'id': 'l1',
        'user_id': 'u1',
        'deleted_at': '2026-08-22T11:00:00.000Z',
        'updated_at': '2026-08-22T11:00:00.000Z',
        'sync_status': SyncStatusContract.synced,
        'quantidade': 10.0,
      };
      final pulled = <String, Object?>{
        'id': 'l1',
        'user_id': 'u1',
        'deleted_at': '2026-08-22T12:00:00.000Z',
        'updated_at': '2026-08-22T12:00:00.000Z',
        'sync_status': SyncStatusContract.synced,
        'quantidade': 10.0,
      };

      final merged = CarteiraSyncService.mergePulled(
        'carteira_lancamentos',
        local: local,
        pulled: pulled,
      );

      expect(merged, isNotNull);
      expect(merged!['deleted_at'], isNotNull);
      expect(merged['id'], 'l1');
    });

    test('remoto tombstoned insere tombstone em device vazio (não vivo)', () {
      final merged = CarteiraSyncService.mergePulled(
        'carteira_lancamentos',
        local: null,
        pulled: {
          'id': 'l1',
          'deleted_at': '2026-08-22T12:00:00.000Z',
          'updated_at': '2026-08-22T12:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );

      expect(merged, isNotNull);
      expect(merged!['deleted_at'], isNotNull);
    });

    test('pending tombstone local não é sobrescrito por remoto vivo mais antigo', () {
      final merged = CarteiraSyncService.mergePulled(
        'carteira_lancamentos',
        local: {
          'id': 'l1',
          'deleted_at': '2026-08-22T12:00:00.000Z',
          'updated_at': '2026-08-22T12:00:00.000Z',
          'sync_status': SyncStatusContract.pendingSync,
        },
        pulled: {
          'id': 'l1',
          'deleted_at': null,
          'updated_at': '2026-08-22T10:00:00.000Z',
          'sync_status': SyncStatusContract.synced,
        },
      );

      expect(merged, isNull);
    });
  });

  test('ordem push/pull é tipos → categorias → config → safras → metas → cliente_categorias → lancamentos', () {
    expect(CarteiraSyncService.pushPullOrder, [
      'carteira_tipos_produto',
      'carteira_categorias',
      'carteira_config',
      'carteira_safras',
      'carteira_metas',
      'carteira_cliente_categorias',
      'carteira_lancamentos',
    ]);
  });
}
