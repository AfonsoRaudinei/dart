import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  group('DrawingLocalIdentityStore', () {
    setUp(() {
      DrawingLocalIdentityStore.resetEphemeralStateForTest();
    });

    test(
      'usa currentUserId e persiste como ultimo usuario conhecido',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesService(await SharedPreferences.getInstance());
        final store = DrawingLocalIdentityStore(preferences: prefs);

        final resolved = store.resolveScopedUserId(currentUserId: 'user-123');

        expect(resolved, 'user-123');
        expect(prefs.getString('drawing_last_known_user_id_v1'), 'user-123');
      },
    );

    test(
      'reusa ultimo usuario conhecido quando sessao ainda nao hidratou',
      () async {
        SharedPreferences.setMockInitialValues({
          'drawing_last_known_user_id_v1': 'user-legacy',
        });
        final prefs = PreferencesService(await SharedPreferences.getInstance());
        final store = DrawingLocalIdentityStore(preferences: prefs);

        final resolved = store.resolveScopedUserId(currentUserId: '');

        expect(resolved, 'user-legacy');
      },
    );

    test(
      'cai para orfao temporario quando nao ha sessao nem ultimo usuario',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = PreferencesService(await SharedPreferences.getInstance());
        final store = DrawingLocalIdentityStore(preferences: prefs);

        final resolved = store.resolveScopedUserId(currentUserId: null);

        expect(resolved, DrawingOwnershipPolicy.orphanUserId);
      },
    );
  });

  group('DrawingOwnershipPolicy', () {
    test('rebaixa pending_sync para local_only sem usuario resolvido', () {
      expect(
        DrawingOwnershipPolicy.normalizeSyncStatusForWrite(
          persistedUserId: '',
          currentSyncStatus: SyncStatus.pending_sync,
        ),
        SyncStatus.local_only.toJson(),
      );
    });

    test('preserva sync status quando usuario esta resolvido', () {
      expect(
        DrawingOwnershipPolicy.normalizeSyncStatusForWrite(
          persistedUserId: 'user-123',
          currentSyncStatus: SyncStatus.pending_sync,
        ),
        SyncStatus.pending_sync.toJson(),
      );
    });

    test('escopo de leitura inclui usuario conhecido e orfaos temporarios', () {
      expect(
        DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause('user-123'),
        "(user_id = ? OR user_id = '')",
      );
      expect(DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs('user-123'), [
        'user-123',
      ]);
      expect(
        DrawingOwnershipPolicy.buildOwnedOrOrphanWhereClause(''),
        "user_id = ''",
      );
      expect(DrawingOwnershipPolicy.buildOwnedOrOrphanWhereArgs(''), isEmpty);
    });
  });
}
