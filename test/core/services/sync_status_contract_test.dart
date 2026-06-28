import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';

void main() {
  group('SyncStatusContract.normalize', () {
    test('valores canônicos permanecem inalterados', () {
      for (final value in SyncStatusContract.canonicalValues) {
        expect(SyncStatusContract.normalize(value), value);
      }
    });

    test('legado pending/local mapeia para contrato', () {
      expect(SyncStatusContract.normalize('pending'), SyncStatusContract.pendingSync);
      expect(SyncStatusContract.normalize('local'), SyncStatusContract.localOnly);
      expect(SyncStatusContract.normalize('1'), SyncStatusContract.pendingSync);
      expect(SyncStatusContract.normalize('0'), SyncStatusContract.synced);
    });

    test('null e desconhecido caem em local_only', () {
      expect(SyncStatusContract.normalize(null), SyncStatusContract.localOnly);
      expect(SyncStatusContract.normalize('???'), SyncStatusContract.localOnly);
    });
  });

  group('SyncStatusContract helpers', () {
    test('isPending cobre local_only e pending_sync', () {
      expect(SyncStatusContract.isPending(SyncStatusContract.localOnly), isTrue);
      expect(SyncStatusContract.isPending(SyncStatusContract.pendingSync), isTrue);
      expect(SyncStatusContract.isPending('pending'), isTrue);
      expect(SyncStatusContract.isPending(SyncStatusContract.synced), isFalse);
    });

    test('isValidCanonical rejeita legado não normalizado', () {
      expect(SyncStatusContract.isValidCanonical('pending'), isFalse);
      expect(SyncStatusContract.isValidCanonical(SyncStatusContract.synced), isTrue);
    });
  });
}
